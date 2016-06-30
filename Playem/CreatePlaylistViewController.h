//
//  CreatePlaylistViewController.h
//  Playem
//
//  Created by Dragos Panoiu on 08/09/14.
//  Copyright (c) 2014 Dragos Panoiu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CreatePlaylistViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIButton *btnClose;
@property (weak, nonatomic) IBOutlet UIButton *btnSubmit;
@property (weak, nonatomic) IBOutlet UILabel *lblWindowTitle;
@property (weak, nonatomic) IBOutlet UITextField *txtPlaylistName;

@property(nonatomic, assign) NSInteger editPlaylistID;
@property(nonatomic, strong) NSString *editPlaylistName;

- (IBAction)createPlaylist:(id)sender;
- (IBAction)closePopup:(id)sender;

@end
