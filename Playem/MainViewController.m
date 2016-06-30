//
//  MainViewController.m
//  Playem
//
//  Created by Dragos Panoiu on 03/09/14.
//  Copyright (c) 2014 Dragos Panoiu. All rights reserved.
//

#import "MainViewController.h"
#import "SWRevealViewController.h"
#import "_utils.h"
#import "NGAParallaxMotion.h"
#import "MZFormSheetController.h"
#import "MBProgressHUD.h"

@interface MainViewController () {
    PlayemCore *pc;
}

@end

@implementation MainViewController

@synthesize bgImage;

            
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationController.navigationBar setHidden:YES];
    bgImage.parallaxIntensity = 30;
    [self setupSideMenu];
    
    pc = [PlayemCore sharedInstance];
    pc.neededView = self.view;
    
    [[MZFormSheetBackgroundWindow appearance] setBackgroundBlurEffect:YES];
    [[MZFormSheetBackgroundWindow appearance] setDynamicBlur:NO];
    [[MZFormSheetBackgroundWindow appearance] setBlurRadius:5.0];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    /*
    if (!pc.fbLoggedIn) {
        [pc showFacebookLoginPopup];
    }
     */
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
}

- (void)setupSideMenu
{
    SWRevealViewController *revealController = [self revealViewController];
    [revealController panGestureRecognizer];
    [revealController tapGestureRecognizer];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
    // return UIStatusBarStyleDefault;
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)receivedEvent
{
    if (receivedEvent.type == UIEventTypeRemoteControl) {
        switch (receivedEvent.subtype) {
            case UIEventSubtypeRemoteControlPlay:
                [pc startPlaying];
                break;
            case UIEventSubtypeRemoteControlPause:
                [pc startPlaying];
                break;
            case UIEventSubtypeRemoteControlStop:
                [pc stopPlaying];
                break;
            case UIEventSubtypeRemoteControlTogglePlayPause:
                [pc startPlaying];
                break;
            case UIEventSubtypeRemoteControlPreviousTrack:
                [pc playPrevTrack];
                break;
            case UIEventSubtypeRemoteControlNextTrack:
                [pc playNextTrack];
                break;
            default:
                break;
        }
    }
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
