//
//  PlayerViewController.m
//  Yusic
//
//  Created by Dragos Panoiu on 19/11/14.
//  Copyright (c) 2014 Dragos Panoiu. All rights reserved.
//

#import "PlayerViewController.h"
#import "Canvas.h"
#import "_utils.h"
#import <QuartzCore/QuartzCore.h>
#import "FBShimmeringView.h"
#import <MediaPlayer/MediaPlayer.h>

@interface PlayerViewController () {
    PlayemCore *pc;
    NSDictionary *trackInfo;
    FBShimmeringView *shimmeringView;
}

@end

@implementation PlayerViewController

@synthesize btnBackToParent, circSlider, trackImage, volumeView, playButton, prevButton, nextButton, repeatButton, shuffleButton, trackDuration, trackName, bufferingStatus, btnShare;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    pc = [PlayemCore sharedInstance];
    
    if ([[pc getSettings:@"shareTrack"] boolValue] == YES) {
        btnShare.hidden = YES;
    }
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        trackName.font = [UIFont fontWithName:@"Roboto-Regular" size:20];
        trackDuration.font = [UIFont fontWithName:@"AvantGardeLT-Book" size:16];
        bufferingStatus.font = [UIFont fontWithName:@"Roboto-Regular" size:20];
    } else {
        trackName.font = [UIFont fontWithName:@"Roboto-Regular" size:24];
        trackDuration.font = [UIFont fontWithName:@"AvantGardeLT-Book" size:16];
        bufferingStatus.font = [UIFont fontWithName:@"Roboto-Regular" size:24];
    }
    
    circSlider.backgroundColor = [UIColor clearColor];
    circSlider.continuous = NO;
    circSlider.minimumTrackTintColor = [UIColor colorWithRed:1.0 green:0.16 blue:0.41 alpha:1.0];
    circSlider.maximumTrackTintColor = [UIColor colorWithRed:28/255 green:40/255 blue:37/255 alpha:0.5f];
    circSlider.thumbTintColor = [UIColor whiteColor];
    circSlider.sliderStyle = UICircularSliderStyleCircle;
    [circSlider addTarget:self action:@selector(updateProgress:) forControlEvents:UIControlEventValueChanged];
    
    [repeatButton setSelected:pc.repeat];
    [shuffleButton setSelected:pc.shuffle];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    pc.delegate = self;
    [self.view startCanvasAnimation];
    trackInfo = [pc getCurrentTrackInfo];
    
    trackName.text = [trackInfo valueForKey:@"track_name"];
    trackDuration.text = [NSString stringWithFormat:@"0:00 / %@", [trackInfo valueForKey:@"track_duration"]];
    
    circSlider.value = (float)pc.audioPlayer.currentTime/pc.audioPlayer.duration;
    
    if ([pc isPlaying]) {
        playButton.selected = YES;
    } else {
        playButton.selected = NO;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    UIImage *noArtwork = [UIImage imageNamed:@"NoArtwork"];
    NSURL *imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@/maxresdefault.jpg", @"http://img.youtube.com/vi/", [trackInfo valueForKey:@"track_videoid"]]];
    [trackImage loadImageFromURL:imageURL placeholderImage:noArtwork cachingKey:[trackInfo valueForKey:@"track_videoid"]];
    trackImage.layer.cornerRadius = roundf(trackImage.frame.size.width/2.0);
    trackImage.layer.masksToBounds = YES;
    
    shimmeringView = [[FBShimmeringView alloc] initWithFrame:bufferingStatus.frame];
    shimmeringView.shimmering = YES;
    shimmeringView.shimmeringBeginFadeDuration = 0.7;
    shimmeringView.shimmeringOpacity = 0.3;
    [self.view addSubview:shimmeringView];
    shimmeringView.contentView = bufferingStatus;
    
    
}

- (IBAction)backToParentView:(id)sender
{
    [self.navigationController popViewControllerAnimated:NO];
}

-(IBAction)shareTrack:(id)sender
{
    if (pc.fbLoggedIn) {
        if ([[FBSDKAccessToken currentAccessToken] hasGranted:@"publish_actions"]) {
            [pc shareTrack:YES];
        } else {
            [pc requestPublishPermission:^{
                [pc shareTrack:YES];
            }];
        }
    } else {
        [pc showAlert:@"Error" message:@"You need to sign in with your Facebook account and allow WAVE to post this track to your wall."];
    }
}

- (IBAction)playNextAction:(id)sender
{
    [pc playNextTrack];
    circSlider.value = 0.0f;
    circSlider.maximumValue = 1.0f;
    circSlider.minimumValue = 0.0f;
}

- (IBAction)playPrevAction:(id)sender
{
    [pc playPrevTrack];
    circSlider.value = 0.0f;
    circSlider.maximumValue = 1.0f;
    circSlider.minimumValue = 0.0f;
}

- (IBAction)toggleRepeat:(id)sender
{
    if (pc.repeat) {
        [repeatButton setSelected:NO];
        pc.repeat = NO;
    } else {
        [repeatButton setSelected:YES];
        pc.repeat = YES;
    }
}

- (IBAction)toggleShuffle:(id)sender
{
    if (pc.shuffle) {
        [shuffleButton setSelected:NO];
        pc.shuffle = NO;
    } else {
        [shuffleButton setSelected:YES];
        pc.shuffle = YES;
    }
}

- (IBAction)togglePlay:(id)sender
{
    [pc startPlaying];
}

- (void)refreshData
{
    trackInfo = [pc getCurrentTrackInfo];
    
    trackName.text = [trackInfo valueForKey:@"track_name"];
    
    UIImage *noArtwork = [UIImage imageNamed:@"NoArtwork"];
    NSURL *imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@/maxresdefault.jpg", @"http://img.youtube.com/vi/", [trackInfo valueForKey:@"track_videoid"]]];
    [trackImage loadImageFromURL:imageURL placeholderImage:noArtwork cachingKey:[trackInfo valueForKey:@"track_videoid"]];
    trackImage.layer.cornerRadius = roundf(trackImage.frame.size.width/2.0);
    trackImage.layer.masksToBounds = YES;
}

- (void)updatePlaybackProgress:(NSInteger)duration withProgress:(NSInteger)progress
{
    circSlider.value = (float)progress/duration;
    
    long total_minutes = duration / 60;
    long total_seconds = duration % 60;
    NSString *total_duration = [NSString stringWithFormat:@"%ld:%02ld", total_minutes, total_seconds];
    
    long prg_minutes = progress / 60;
    long prg_seconds = progress % 60;
    NSString *prg_duration = [NSString stringWithFormat:@"%ld:%02ld", prg_minutes, prg_seconds];
    
    trackDuration.text = [NSString stringWithFormat:@"%@ / %@", prg_duration, total_duration];
}

- (IBAction)updateProgress:(UISlider *)sender {
    float progress = translateValueFromSourceIntervalToDestinationInterval(sender.value, sender.minimumValue, sender.maximumValue, 0.0, 1.0);
    
    [pc.audioPlayer seekto:progress];
    [circSlider setValue:sender.value];
    
    NSMutableDictionary *currentTrackInfo = [[[MPNowPlayingInfoCenter defaultCenter] nowPlayingInfo] mutableCopy];
    [currentTrackInfo setObject:[NSNumber numberWithInteger:progress*[pc.audioPlayer duration]] forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
    
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:currentTrackInfo];
}

- (void) updatePlayerInterface:(BOOL)status
{
    [self refreshData];
    playButton.selected = status;
}

- (void) updateBufferingStatus:(BOOL)status
{
    bufferingStatus.hidden = !status;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
