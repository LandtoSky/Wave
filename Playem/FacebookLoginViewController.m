//
//  FacebookLoginViewController.m
//  Yusic
//
//  Created by Dragos Panoiu on 01/02/15.
//  Copyright (c) 2015 Dragos Panoiu. All rights reserved.
//

#import "FacebookLoginViewController.h"
#import "MZFormSheetController.h"
#import "PlayemCore.h"
#import "AppDelegate.h"

@interface FacebookLoginViewController () {
    PlayemCore *pc;
}

@end

@implementation FacebookLoginViewController

@synthesize btnFbLogin, btnSkip, lblLine1, lblLine2;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    lblLine1.font = [UIFont fontWithName:@"Roboto-Regular" size:18];
    NSString *label1Text = @"Connect with WAVE";
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:label1Text];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setAlignment:NSTextAlignmentCenter];
    [attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, [label1Text length])];
    lblLine1.attributedText = attributedString;
    
    lblLine2.font = [UIFont fontWithName:@"Roboto-Regular" size:14];
    NSString *label2Text = @"WAVE allows you to stream music and create playlists. Optionally, you can login with Facebook to enable music sharing features with your friends!";
    attributedString = [[NSMutableAttributedString alloc] initWithString:label2Text];
    paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineSpacing:8];
    [paragraphStyle setAlignment:NSTextAlignmentCenter];
    [attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, [label2Text length])];
    lblLine2.attributedText = attributedString;
    
    pc = [PlayemCore sharedInstance];
}

- (IBAction)loginUserToFb:(id)sender
{
    [pc loginWithFacebook];
    [self mz_dismissFormSheetControllerAnimated:YES completionHandler:^(MZFormSheetController *formSheetController) {}];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (IBAction)closePopup:(id)sender
{
    [self mz_dismissFormSheetControllerAnimated:YES completionHandler:^(MZFormSheetController *formSheetController) {}];
}

@end
