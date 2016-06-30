//
//  PlaylistCell.h
//  Playem
//
//  Created by Dragos Panoiu on 07/09/14.
//  Copyright (c) 2014 Dragos Panoiu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SWTableViewCell.h"

@interface PlaylistCell : SWTableViewCell

@property (weak, nonatomic) IBOutlet UIButton *btnPlayPlaylist;
@property (weak, nonatomic) IBOutlet UILabel *playlistName;
@property (weak, nonatomic) IBOutlet UILabel *playlistTotal;
@property (weak, nonatomic) IBOutlet UILabel *tracksTotal;
@property (weak, nonatomic) IBOutlet UILabel *tracksLabel;
@property (weak, nonatomic) IBOutlet UIImageView *waveformImage;
@property (weak, nonatomic) IBOutlet UIImageView *waveformFull;

@end
