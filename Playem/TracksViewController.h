//
//  TracksViewController.h
//  Playem
//
//  Created by Dragos Panoiu on 15/09/14.
//  Copyright (c) 2014 Dragos Panoiu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LXReorderableCollectionViewFlowLayout.h"
#import "PlayemCore.h"

@interface TracksViewController : UIViewController <LXReorderableCollectionViewDataSource, LXReorderableCollectionViewDelegateFlowLayout, PlayemCoreDelegate>

@property (weak, nonatomic) IBOutlet UIButton *btnBackToParent;
@property (weak, nonatomic) IBOutlet UIButton *btnAddTrack;
@property (weak, nonatomic) IBOutlet UIButton *btnPlaylist;
@property (weak, nonatomic) IBOutlet UICollectionView *tracksTable;
@property (weak, nonatomic) IBOutlet UILabel *lblPlaylistName;
@property (weak, nonatomic) IBOutlet UILabel *lblPlaylistTime;
@property (weak, nonatomic) IBOutlet UILabel *lblTracksTotal;
@property (weak, nonatomic) IBOutlet UILabel *lblTracksTitle;
@property (weak, nonatomic) IBOutlet UIImageView *waveformImage;
@property (weak, nonatomic) IBOutlet UIImageView *waveformFull;

- (IBAction)backToParentView:(id)sender;
- (IBAction)searchYoutube:(id)sender;
- (IBAction)deleteTrack:(id)sender;
- (IBAction)playPlaylist:(id)sender;

@end
