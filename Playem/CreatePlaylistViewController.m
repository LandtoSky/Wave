//
//  CreatePlaylistViewController.m
//  Playem
//
//  Created by Dragos Panoiu on 08/09/14.
//  Copyright (c) 2014 Dragos Panoiu. All rights reserved.
//

#import "CreatePlaylistViewController.h"
#import "MZFormSheetController.h"
#import "PlayemCore.h"

@interface CreatePlaylistViewController () {
    PlayemCore *pc;
}

@end

@implementation CreatePlaylistViewController

@synthesize btnClose, btnSubmit, lblWindowTitle, txtPlaylistName, editPlaylistID, editPlaylistName;

- (void)viewDidLoad {
    [super viewDidLoad];
    pc = [PlayemCore sharedInstance];
    
    // lblWindowTitle.font = [UIFont fontWithName:@"AvantGardeLT-Book" size:20];
    
    if ([editPlaylistName length] > 0) {
        lblWindowTitle.text = @"Edit Playlist";
        txtPlaylistName.text = editPlaylistName;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [txtPlaylistName becomeFirstResponder];
}

- (IBAction)createPlaylist:(id)sender
{
    // edit existing playlist
    if ([editPlaylistName length] > 0) {
        [pc editPlaylist:txtPlaylistName.text playlistID:editPlaylistID];
    } else {
    // create a new playlist
        if (![txtPlaylistName.text isEqualToString:@""]) {
            [pc createPlaylist:txtPlaylistName.text];
        }
    }
    
    [self mz_dismissFormSheetControllerAnimated:YES completionHandler:^(MZFormSheetController *formSheetController) {}];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)closePopup:(id)sender
{
    [self mz_dismissFormSheetControllerAnimated:YES completionHandler:^(MZFormSheetController *formSheetController) {}];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
    // return UIStatusBarStyleDefault;
}

@end
