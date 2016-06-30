//
//  TracksViewController.m
//  Playem
//
//  Created by Dragos Panoiu on 15/09/14.
//  Copyright (c) 2014 Dragos Panoiu. All rights reserved.
//

#import "TracksViewController.h"
#import "TrackCell.h"
#import "flowLayoutLandscape.h"
#import "flowLayoutPortrait.h"
#import "_utils.h"
#import "Canvas.h"
#import "MZFormSheetController.h"
#import "SearchViewController.h"

@interface TracksViewController () {
    PlayemCore *pc;
    NSMutableArray *trackItems;
    flowLayoutLandscape *landscapeLayout;
    flowLayoutPortrait *portraitLayout;
    UIAlertView *deleteAlert;
    NSInteger actionTrackID;
    UIImageView *helpImg;
}

@end

@implementation TracksViewController

@synthesize btnBackToParent, btnAddTrack, tracksTable, lblPlaylistName, lblPlaylistTime, lblTracksTitle, lblTracksTotal, waveformImage, waveformFull, btnPlaylist;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    //lblPlaylistName.font = [UIFont fontWithName:@"AvantGardeLT-BookOblique" size:24];
    //lblPlaylistTime.font = [UIFont fontWithName:@"AvantGardeLT-BookOblique" size:14];
    //lblTracksTotal.font = [UIFont fontWithName:@"AvantGardeLT-BookOblique" size:40];
    //lblTracksTitle.font = [UIFont fontWithName:@"AvantGardeLT-BookOblique" size:14];
    
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setTextColor:[UIColor whiteColor]];
    
    landscapeLayout = [[flowLayoutLandscape alloc] init];
    portraitLayout = [[flowLayoutPortrait alloc] init];
    
    pc = [PlayemCore sharedInstance];
    
    if (([[UIDevice currentDevice] orientation] == UIInterfaceOrientationLandscapeLeft) || ([[UIDevice currentDevice] orientation] == UIInterfaceOrientationLandscapeRight)) {
        [landscapeLayout invalidateLayout];
        [tracksTable setCollectionViewLayout:landscapeLayout animated:NO];
    } else {
        [portraitLayout invalidateLayout];
        [tracksTable setCollectionViewLayout:portraitLayout animated:NO];
    }
    
    // create help image
    helpImg = [[UIImageView alloc] init];
    [helpImg setImage:[UIImage imageNamed:@"SongzaTrackHelp"]];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        helpImg.frame = CGRectMake([[UIScreen mainScreen] bounds].size.width-280, 15, 251, 194);
    } else {
        helpImg.frame = CGRectMake([[UIScreen mainScreen] bounds].size.width-390, 15, 251, 194);
    }
    helpImg.contentMode = UIViewContentModeScaleAspectFit;
    helpImg.hidden = YES;
    [self.view addSubview:helpImg];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    pc.delegate = self;
    [self refreshData];
    [self.view startCanvasAnimation];
    
    if (!pc.fbLoggedIn) {
        [pc showFacebookLoginPopup];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (pc.playingTrack != -1 && pc.selectedPlaylistRow == pc.playingPlaylist) {
        [tracksTable selectItemAtIndexPath:[NSIndexPath indexPathForRow:pc.playingTrack inSection:0] animated:YES scrollPosition:UICollectionViewScrollPositionCenteredVertically];
        
        if ([pc isPlaying]) {
            btnPlaylist.selected = YES;
        } else {
            btnPlaylist.selected = NO;
        }
    }
}

- (void)appDidBecomeActive:(NSNotification *)notification {
    if (pc.playingTrack != -1 && pc.selectedPlaylistRow == pc.playingPlaylist) {
        [tracksTable selectItemAtIndexPath:[NSIndexPath indexPathForRow:pc.playingTrack inSection:0] animated:YES scrollPosition:UICollectionViewScrollPositionCenteredVertically];
    }
}

- (void)refreshData
{
    trackItems = [[pc loadTracksFromPlaylist:pc.selectedPlaylistID] mutableCopy];
    [tracksTable reloadData];
    
    if ([trackItems count] == 0) {
        helpImg.hidden = NO;
    } else {
        helpImg.hidden = YES;
    }
    
    NSDictionary *plInfo = [pc getCurrentPlaylistInfo];
    lblPlaylistName.text = [plInfo valueForKey:@"playlist_name"];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        lblPlaylistTime.text = [NSString stringWithFormat:@"%@ / %@ tracks", [Utils timeFormatted:[[plInfo valueForKey:@"playlist_duration"] integerValue]], [plInfo valueForKey:@"playlist_tracks"]];
    } else {
        lblPlaylistTime.text = [NSString stringWithFormat:@"Playing time: %@", [Utils timeFormatted:[[plInfo valueForKey:@"playlist_duration"] integerValue]]];
    }
    lblTracksTotal.text = [NSString stringWithFormat:@"%@", [plInfo valueForKey:@"playlist_tracks"]];
}

- (IBAction)backToParentView:(id)sender
{
    [self.navigationController popViewControllerAnimated:NO];
}

- (NSInteger) numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [trackItems count];
}

- (UICollectionViewCell *) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"TrackCell";
    TrackCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    
    cell.contentView.frame = cell.bounds;
    cell.contentView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin |UIViewAutoresizingFlexibleTopMargin |UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    
    if (([[UIDevice currentDevice] orientation] == UIInterfaceOrientationLandscapeLeft) || ([[UIDevice currentDevice] orientation] == UIInterfaceOrientationLandscapeRight)) {
        //cell.lblTrackName.font = [UIFont fontWithName:@"AvantGardeLT-BookOblique" size:18];
        //cell.lblTrackName.preferredMaxLayoutWidth = 250;
    } else {
        //cell.lblTrackName.font = [UIFont fontWithName:@"AvantGardeLT-BookOblique" size:15];
        //cell.lblTrackName.preferredMaxLayoutWidth = 140;
    }
    
    //cell.lblTrackDuration.font = [UIFont fontWithName:@"AvantGardeLT-BookOblique" size:10];
    
    cell.tag = [[trackItems[indexPath.row] valueForKey:@"track_id"] integerValue];
    
    cell.lblTrackName.text = [NSString stringWithFormat:@"%@", [trackItems[indexPath.row] valueForKey:@"track_name"]];
    
    NSString *filesize = [NSString stringWithFormat:@"%.02f", ([Utils secondsForTimeString:[trackItems[indexPath.row] valueForKey:@"track_duration"]] * 0.0151)];
    cell.lblTrackDuration.text = [NSString stringWithFormat:@"%@ – %@MB", [trackItems[indexPath.row] valueForKey:@"track_duration"], filesize];
    
    UIImage *noArtwork = [UIImage imageNamed:@"NoArtwork"];
    NSURL *imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@/maxresdefault.jpg", @"http://img.youtube.com/vi/", [trackItems[indexPath.row] valueForKey:@"track_videoid"]]];
    [cell.imgTrackImage loadImageFromURL:imageURL placeholderImage:noArtwork cachingKey:[trackItems[indexPath.row] valueForKey:@"track_videoid"]];
    cell.imgTrackImage.layer.cornerRadius = roundf(cell.imgTrackImage.frame.size.width/2.0);
    cell.imgTrackImage.layer.masksToBounds = YES;
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    waveformFull.hidden = YES;
    
    [pc playTrack:indexPath.row];
    
    UIViewController *pVC = [self.storyboard instantiateViewControllerWithIdentifier:@"playerVC"];
    [self.navigationController pushViewController:pVC animated:NO];
}

- (IBAction)deleteTrack:(id)sender
{
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:tracksTable];
    NSIndexPath *indexPath = [tracksTable indexPathForItemAtPoint:buttonPosition];
    actionTrackID = indexPath.row;
    deleteAlert = [[UIAlertView alloc] initWithTitle: @"Delete Track" message: @"Are you sure you want to delete this track?" delegate: self cancelButtonTitle: @"No"  otherButtonTitles:@"Yes",nil];
    [deleteAlert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // delete track
    if (alertView == deleteAlert && buttonIndex == 1) {
        [pc deleteTrack:actionTrackID];
        [self refreshData];
        if (actionTrackID == pc.playingTrack) {
            [pc stopPlaying];
            waveformFull.hidden = YES;
        }
        if (actionTrackID < pc.playingTrack) {
            pc.playingTrack -= 1;
        }
    }
}

- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath willMoveToIndexPath:(NSIndexPath *)toIndexPath {
    if (fromIndexPath.row == 0 && toIndexPath.row == 0)
        return;

    id obj = trackItems[fromIndexPath.item];
    
    [trackItems removeObjectAtIndex:fromIndexPath.item];
    [trackItems insertObject:obj atIndex:toIndexPath.item];
    
    if (pc.playingTrack == fromIndexPath.row) {
        pc.playingTrack = toIndexPath.row;
    } else if (pc.playingTrack == toIndexPath.row) {
        pc.playingTrack = fromIndexPath.row;
    }
}

- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath canMoveToIndexPath:(NSIndexPath *)toIndexPath {
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout didEndDraggingItemAtIndexPath:(NSIndexPath *)indexPath {
    [pc saveTracksOrder:trackItems];
    [self refreshData];
}

- (void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if (([[UIDevice currentDevice] orientation] == UIInterfaceOrientationLandscapeLeft) || ([[UIDevice currentDevice] orientation] == UIInterfaceOrientationLandscapeRight)) {
        [landscapeLayout invalidateLayout];
        [tracksTable setCollectionViewLayout:landscapeLayout animated:NO completion:^(BOOL finished) {
            if (finished)
                [tracksTable reloadData];
        }];
    } else {
        [portraitLayout invalidateLayout];
        [tracksTable setCollectionViewLayout:portraitLayout animated:NO completion:^(BOOL finished) {
            if (finished)
                [tracksTable reloadData];
        }];
    }
    if ([trackItems count] > 0)
        [tracksTable scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:YES];
    [self.view startCanvasAnimation];
}

- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        helpImg.frame = CGRectMake([[UIScreen mainScreen] bounds].size.width-280, 15, 251, 194);
    } else {
        helpImg.frame = CGRectMake([[UIScreen mainScreen] bounds].size.width-390, 15, 251, 194);
    }
    [helpImg setNeedsDisplay];
}

- (IBAction)searchYoutube:(id)sender
{
    UIViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"searchYoutubeVC"];
    
    MZFormSheetController *formSheet = [[MZFormSheetController alloc] initWithViewController:vc];
    formSheet.shouldDismissOnBackgroundViewTap = NO;
    formSheet.transitionStyle = MZFormSheetTransitionStyleBounce;
    formSheet.cornerRadius = 8.0;
    formSheet.shouldCenterVertically = YES;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        formSheet.presentedFormSheetSize = CGSizeMake([[UIScreen mainScreen] bounds].size.width-20, 500);
    } else {
        formSheet.presentedFormSheetSize = CGSizeMake(500, 600);
    }
    formSheet.movementWhenKeyboardAppears = MZFormSheetWhenKeyboardAppearsCenterVertically;
    
    formSheet.didDismissCompletionHandler = ^(UIViewController *presentedFSViewController) {
        [self refreshData];
    };
    
    [formSheet presentAnimated:YES completionHandler:^(UIViewController *presentedFSViewController) {}];
}

- (void) updatePlaybackProgress:(NSInteger)duration withProgress:(NSInteger)progress
{
    if (pc.playingTrack != -1 && pc.selectedPlaylistRow == pc.playingPlaylist) {
        float fillWidth = (progress * waveformImage.frame.size.width) / duration;
        
        waveformFull.frame = CGRectMake(waveformImage.frame.origin.x, waveformImage.frame.origin.y, fillWidth, waveformImage.frame.size.height);
        waveformFull.contentMode = UIViewContentModeTopLeft;
        waveformFull.clipsToBounds = YES;
        waveformFull.hidden = NO;
        
        [tracksTable selectItemAtIndexPath:[NSIndexPath indexPathForRow:pc.playingTrack inSection:0] animated:YES scrollPosition:UICollectionViewScrollPositionNone];
    }
}

- (IBAction)playPlaylist:(id)sender
{
    if (pc.playingPlaylist == pc.selectedPlaylistRow) {
        // pause
        if ([pc isPlaying]) {
            [pc startPlaying];
            btnPlaylist.selected = NO;
            return;
        }
        
        // resume
        if ([pc isPaused]) {
            [pc startPlaying];
            btnPlaylist.selected = YES;
            return;
        }
    }
        
    if ([trackItems count] > 0) {
        [pc playTrack:0];
        [tracksTable selectItemAtIndexPath:[NSIndexPath indexPathForRow:pc.playingTrack inSection:0] animated:YES scrollPosition:UICollectionViewScrollPositionCenteredVertically];
        btnPlaylist.selected = YES;
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Play" message:@"There are no tracks in this playlist." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [alert show];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
