//
//  MenuViewController.m
//  Playem
//
//  Created by Dragos Panoiu on 07/09/14.
//  Copyright (c) 2014 Dragos Panoiu. All rights reserved.
//

#import "MenuViewController.h"
#import "PlayemCore.h"
#import "SWRevealViewController.h"
#import "AppDelegate.h"
#import "WelcomeViewController.h"

@interface MenuViewController () {
    PlayemCore *pc;
}

@end

@implementation MenuViewController

@synthesize lblWelcome, btnFbLogin, btnLogout, lblShareSong, swShare;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    lblWelcome.font = [UIFont fontWithName:@"Roboto-Regular" size:24];
    lblShareSong.font = [UIFont fontWithName:@"Roboto-Regular" size:13];
    btnLogout.titleLabel.font = [UIFont fontWithName:@"Roboto-Regular" size:14];
    
    pc = [PlayemCore sharedInstance];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (pc.fbLoggedIn) {
        btnLogout.hidden = NO;
        lblWelcome.text = [NSString stringWithFormat:@"Hey, %@!", pc.fbUserInfo.firstName];
        btnFbLogin.hidden = YES;
        lblShareSong.hidden = NO;
        swShare.hidden = NO;
        
        if ([[pc getSettings:@"shareTrack"] boolValue] == YES) {
            [swShare setOn:YES];
        } else {
            [swShare setOn:NO];
        }
    } else {
        lblWelcome.text = @"JOIN THE WAVE";
        btnFbLogin.hidden = NO;
        btnLogout.hidden = YES;
        lblShareSong.hidden = YES;
        swShare.hidden = YES;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)facebookLogout:(id)sender {
    [pc stopPlaying];
    [self.revealViewController revealToggleAnimated:YES];
    [self performSelector:@selector(clearFacebookSession) withObject:nil afterDelay:0.3];
}

- (void)clearFacebookSession
{
    [pc logoutFromFacebook];
}

- (IBAction)loginUserToFb:(id)sender
{
    [pc loginWithFacebook];
    [self.revealViewController revealToggleAnimated:YES];
}

- (IBAction)changeSwitch:(id)sender {
    if ([swShare isOn]) {
        if ([[FBSDKAccessToken currentAccessToken] hasGranted:@"publish_actions"]) {
            [pc saveAutoShareStatus:YES];
            [swShare setOn:YES];
        } else {
            [self.revealViewController revealToggleAnimated:YES];
            [pc requestPublishPermission:^{
                [pc saveAutoShareStatus:YES];
            }];
        }
    } else {
        [pc saveAutoShareStatus:NO];
        [swShare setOn:NO];
    }
    
    if ([[pc getSettings:@"shareTrack"] boolValue] == YES) {
        [swShare setOn:YES];
    } else {
        [swShare setOn:NO];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

@end
