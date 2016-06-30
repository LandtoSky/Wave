//
//  PlaylistsViewController.m
//  Playem
//
//  Created by Dragos Panoiu on 15/09/14.
//  Copyright (c) 2014 Dragos Panoiu. All rights reserved.
//

#import "PlaylistsViewController.h"
#import "_utils.h"
#import "PlaylistCell.h"
#import "MZFormSheetController.h"
#import "CreatePlaylistViewController.h"
#import "TracksViewController.h"
#import "Canvas.h"
#import "SWRevealViewController.h"
#import "WelcomeViewController.h"

@interface PlaylistsViewController () {
    PlayemCore *pc;
    NSArray *playlistItems;
    NSTimer *timer;
    UIImageView *helpImg;
}

@end

@implementation PlaylistsViewController

@synthesize playlistsTable, btnCreatePlaylist, btnMenu;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationController.navigationBar setHidden:YES];
    [btnMenu addTarget:self.revealViewController action:@selector(revealToggle:) forControlEvents:UIControlEventTouchUpInside];
    btnMenu.hidden = NO;
    
    pc = [PlayemCore sharedInstance];
    
    // create help image
    helpImg = [[UIImageView alloc] init];
    [helpImg setImage:[UIImage imageNamed:@"SongzaPlaylistHelp"]];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        helpImg.frame = CGRectMake([[UIScreen mainScreen] bounds].size.width-260, 15, 235, 118);
    } else {
        helpImg.frame = CGRectMake([[UIScreen mainScreen] bounds].size.width-330, 15, 235, 118);
    }
    helpImg.contentMode = UIViewContentModeScaleAspectFit;
    helpImg.hidden = YES;
    [self.view addSubview:helpImg];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self refreshData];
    [self.view startCanvasAnimation];
    pc.delegate = self;
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"hasSeenIntro"])
        [self presentWelcomeViewController];
}

- (void)presentWelcomeViewController {
    UIStoryboard *storyboard = self.storyboard;
    WelcomeViewController *controller = [storyboard instantiateViewControllerWithIdentifier:@"WelcomeViewController"];
    [self presentViewController:controller animated:YES completion:nil];
}

- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        helpImg.frame = CGRectMake([[UIScreen mainScreen] bounds].size.width-260, 15, 235, 118);
    } else {
        helpImg.frame = CGRectMake([[UIScreen mainScreen] bounds].size.width-330, 15, 235, 118);
    }
    [helpImg setNeedsDisplay];
}

-(void)refreshData
{
    playlistItems = [pc loadPlaylists];
    [playlistsTable reloadData];
    
    if ([playlistItems count] == 0) {
        helpImg.hidden = NO;
    } else {
        helpImg.hidden = YES;
    }
    
    // set playing playlist
    if ([pc isPlaying] && pc.playingPlaylist != -1) {
        [playlistsTable selectRowAtIndexPath:[NSIndexPath indexPathForRow:pc.playingPlaylist inSection:0] animated:YES scrollPosition:UITableViewScrollPositionMiddle];
        PlaylistCell *cell = (PlaylistCell *) [playlistsTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:pc.playingPlaylist inSection:0]];
        cell.btnPlayPlaylist.selected = YES;
    }
    
    if ([pc isPaused] && pc.playingPlaylist != -1) {
        [playlistsTable selectRowAtIndexPath:[NSIndexPath indexPathForRow:pc.playingPlaylist inSection:0] animated:YES scrollPosition:UITableViewScrollPositionMiddle];
        PlaylistCell *cell = (PlaylistCell *) [playlistsTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:pc.playingPlaylist inSection:0]];
        cell.btnPlayPlaylist.selected = NO;
    }
}

- (NSArray *)rightCellButtons
{
    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
    [rightUtilityButtons sw_addUtilityButtonWithColor: [UIColor colorWithRed:0.78f green:0.78f blue:0.8f alpha:1.0] title:@"Edit"];
    [rightUtilityButtons sw_addUtilityButtonWithColor: [UIColor colorWithRed:1.0f green:0.231f blue:0.188 alpha:1.0f] title:@"Delete"];
    
    return rightUtilityButtons;
}

- (BOOL)swipeableTableViewCellShouldHideUtilityButtonsOnSwipe:(SWTableViewCell *)cell
{
    // allow just one cell's utility button to be open at once
    return YES;
}

- (BOOL)swipeableTableViewCell:(SWTableViewCell *)cell canSwipeToState:(SWCellState)state
{
    switch (state) {
        case 1:
            // set to NO to disable all left utility buttons appearing
            return NO;
            break;
        case 2:
            // set to NO to disable all right utility buttons appearing
            return YES;
            break;
        default:
            break;
    }
    
    return YES;
}

-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [playlistItems count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"PlaylistCell";
    PlaylistCell *cell = (PlaylistCell *) [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[PlaylistCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    [cell setRightUtilityButtons:[self rightCellButtons] WithButtonWidth:58.0f];
    cell.delegate = self;
    cell.tag = [[playlistItems[indexPath.row] valueForKey:@"playlist_id"] integerValue];
    
    cell.playlistName.text = [NSString stringWithFormat:@"%@", [playlistItems[indexPath.row] valueForKey:@"playlist_name"]];
    cell.tracksTotal.text = [NSString stringWithFormat:@"%@", [playlistItems[indexPath.row] valueForKey:@"playlist_tracks"]];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        cell.playlistTotal.text = [NSString stringWithFormat:@"%@ / %@ tracks", [Utils timeFormatted:[[playlistItems[indexPath.row] valueForKey:@"playlist_duration"] integerValue]], [playlistItems[indexPath.row] valueForKey:@"playlist_tracks"]];
    } else {
        cell.playlistTotal.text = [NSString stringWithFormat:@"Playing time: %@", [Utils timeFormatted:[[playlistItems[indexPath.row] valueForKey:@"playlist_duration"] integerValue]]];
    }
    cell.backgroundColor = [UIColor clearColor];
    cell.waveformFull.hidden = YES;
    cell.btnPlayPlaylist.selected = NO;
    
    if (pc.playingPlaylist == indexPath.row) {
        cell.btnPlayPlaylist.selected = YES;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger playlistID = [tableView cellForRowAtIndexPath:indexPath].tag;
    [pc selectPlaylist:playlistID withPlaylistRow:indexPath.row];
    UIViewController *tVC = [self.storyboard instantiateViewControllerWithIdentifier:@"tracksVC"];
    [self.navigationController pushViewController:tVC animated:NO];
}

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index
{
    switch (index) {
        case 0:
        {
            // Edit playlist
            NSIndexPath *indexPath = [playlistsTable indexPathForCell:cell];
            PlaylistCell *plCell = (PlaylistCell *)[playlistsTable cellForRowAtIndexPath:indexPath];
            [self editPlaylistName:plCell.playlistName.text withPlaylistID:cell.tag];
            
            [cell hideUtilityButtonsAnimated:YES];
            break;
        }
        case 1:
        {
            // Delete playlist
            NSIndexPath *indexPath = [playlistsTable indexPathForCell:cell];
            [pc deletePlaylist:cell.tag];
            playlistItems = [pc loadPlaylists];
            
            if (indexPath.row < pc.playingPlaylist) {
                pc.playingPlaylist -= 1;
            }
            
            if (pc.playingPlaylist == indexPath.row) {
                pc.playingPlaylist = -1;
                [pc stopPlaying];
            }
            
            [playlistsTable beginUpdates];
            [playlistsTable deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [playlistsTable endUpdates];
            break;
        }
        default:
            break;
    }
    
    [self refreshData];
}

- (IBAction)showCreatePlaylistPopup:(id)sender
{
    UIViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"createPlaylistVC"];
    
    MZFormSheetController *formSheet = [[MZFormSheetController alloc] initWithViewController:vc];
    formSheet.shouldDismissOnBackgroundViewTap = NO;
    formSheet.transitionStyle = MZFormSheetTransitionStyleBounce;
    formSheet.cornerRadius = 8.0;
    formSheet.shouldCenterVertically = YES;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        formSheet.presentedFormSheetSize = CGSizeMake(290, 180);
    } else {
        formSheet.presentedFormSheetSize = CGSizeMake(500, 250);
    }
    formSheet.movementWhenKeyboardAppears = MZFormSheetWhenKeyboardAppearsCenterVertically;
    
    formSheet.didDismissCompletionHandler = ^(UIViewController *presentedFSViewController) {
        [self refreshData];
    };
    
    [formSheet presentAnimated:YES completionHandler:^(UIViewController *presentedFSViewController) {}];
}

- (void)editPlaylistName:(NSString *)playlistName withPlaylistID:(NSInteger)playlistID
{
    CreatePlaylistViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"createPlaylistVC"];
    vc.editPlaylistName = playlistName;
    vc.editPlaylistID = playlistID;
    
    MZFormSheetController *formSheet = [[MZFormSheetController alloc] initWithViewController:vc];
    formSheet.shouldDismissOnBackgroundViewTap = NO;
    formSheet.transitionStyle = MZFormSheetTransitionStyleBounce;
    formSheet.cornerRadius = 8.0;
    formSheet.shouldCenterVertically = YES;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        formSheet.presentedFormSheetSize = CGSizeMake(290, 180);
    } else {
        formSheet.presentedFormSheetSize = CGSizeMake(500, 250);
    }
    formSheet.movementWhenKeyboardAppears = MZFormSheetWhenKeyboardAppearsCenterVertically;
    
    formSheet.didDismissCompletionHandler = ^(UIViewController *presentedFSViewController) {
        [self refreshData];
    };
    
    [formSheet presentAnimated:YES completionHandler:^(UIViewController *presentedFSViewController) {}];
}

- (void) updatePlaybackProgress:(NSInteger)duration withProgress:(NSInteger)progress
{
    PlaylistCell *cell = (PlaylistCell *) [playlistsTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:pc.playingPlaylist inSection:0]];
    float fillWidth = (progress * cell.waveformImage.frame.size.width) / duration;
    
    cell.waveformFull.frame = CGRectMake(cell.waveformImage.frame.origin.x, cell.waveformImage.frame.origin.y, fillWidth, cell.waveformImage.frame.size.height);
    cell.waveformFull.contentMode = UIViewContentModeTopLeft;
    cell.waveformFull.clipsToBounds = YES;
    cell.waveformFull.hidden = NO;
}

- (IBAction)playPlaylist:(id)sender
{
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:playlistsTable];
    NSIndexPath *indexPath = [playlistsTable indexPathForRowAtPoint:buttonPosition];
    NSInteger playlistID = [playlistsTable cellForRowAtIndexPath:indexPath].tag;
    
    // pause
    if ([pc isPlaying] && pc.playingPlaylist == indexPath.row) {
        [pc startPlaying];
        PlaylistCell *cell = (PlaylistCell *) [playlistsTable cellForRowAtIndexPath:indexPath];
        cell.btnPlayPlaylist.selected = NO;
        return;
    }
    
    // resume
    if ([pc isPaused] && pc.playingPlaylist == indexPath.row) {
        [pc startPlaying];
        PlaylistCell *cell = (PlaylistCell *) [playlistsTable cellForRowAtIndexPath:indexPath];
        cell.btnPlayPlaylist.selected = YES;
        return;
    }
    
    // start playing
    [pc selectPlaylist:playlistID withPlaylistRow:indexPath.row];
    NSArray *tr = [pc loadTracksFromPlaylist:pc.selectedPlaylistID];
    if ([tr count] > 0) {
        [pc playTrack:0];
        PlaylistCell *cell = (PlaylistCell *) [playlistsTable cellForRowAtIndexPath:indexPath];
        cell.btnPlayPlaylist.selected = YES;
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Play" message:@"There are no tracks in this playlist." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [alert show];
    }
    [self refreshData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
