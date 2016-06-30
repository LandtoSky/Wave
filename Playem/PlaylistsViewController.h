//
//  PlaylistsViewController.h
//  Playem
//
//  Created by Dragos Panoiu on 15/09/14.
//  Copyright (c) 2014 Dragos Panoiu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SWTableViewCell.h"
#import "PlayemCore.h"

@interface PlaylistsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, SWTableViewCellDelegate, PlayemCoreDelegate>

@property (weak, nonatomic) IBOutlet UITableView *playlistsTable;
@property (weak, nonatomic) IBOutlet UIButton *btnCreatePlaylist;
@property (weak, nonatomic) IBOutlet UIButton *btnMenu;

- (IBAction)showCreatePlaylistPopup:(id)sender;
- (IBAction)playPlaylist:(id)sender;

@end
