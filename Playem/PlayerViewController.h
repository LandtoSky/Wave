//
//  PlayerViewController.h
//  Yusic
//
//  Created by Dragos Panoiu on 19/11/14.
//  Copyright (c) 2014 Dragos Panoiu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import "PlayemCore.h"
#import "UICircularSlider.h"

@interface PlayerViewController : UIViewController <PlayemCoreDelegate>

@property (weak, nonatomic) IBOutlet UIButton *btnBackToParent;
@property (weak, nonatomic) IBOutlet UIImageView *trackImage;
@property (weak, nonatomic) IBOutlet UICircularSlider *circSlider;
@property (nonatomic, weak) IBOutlet MPVolumeView *volumeView;
@property (nonatomic, weak) IBOutlet UIButton *playButton;
@property (nonatomic, weak) IBOutlet UIButton *prevButton;
@property (nonatomic, weak) IBOutlet UIButton *nextButton;
@property (nonatomic, weak) IBOutlet UIButton *repeatButton;
@property (nonatomic, weak) IBOutlet UIButton *shuffleButton;
@property (nonatomic, weak) IBOutlet UILabel *trackName;
@property (nonatomic, weak) IBOutlet UILabel *trackDuration;
@property (nonatomic, weak) IBOutlet UILabel *bufferingStatus;
@property (weak, nonatomic) IBOutlet UIButton *btnShare;

- (IBAction)backToParentView:(id)sender;
- (IBAction)playNextAction:(id)sender;
- (IBAction)playPrevAction:(id)sender;
- (IBAction)togglePlay:(id)sender;
- (IBAction)toggleRepeat:(id)sender;
- (IBAction)toggleShuffle:(id)sender;
- (IBAction)shareTrack:(id)sender;

@end
