//
//  PlaylistCell.m
//  Playem
//
//  Created by Dragos Panoiu on 07/09/14.
//  Copyright (c) 2014 Dragos Panoiu. All rights reserved.
//

#import "PlaylistCell.h"

@implementation PlaylistCell

- (void)awakeFromNib {
    //self.playlistName.font = [UIFont fontWithName:@"AvantGardeLT-BookOblique" size:24];
    //self.playlistTotal.font = [UIFont fontWithName:@"AvantGardeLT-BookOblique" size:14];
    //self.tracksTotal.font = [UIFont fontWithName:@"AvantGardeLT-BookOblique" size:40];
    //self.tracksLabel.font = [UIFont fontWithName:@"AvantGardeLT-BookOblique" size:14];
    
    //self.playlistName.font = [UIFont fontWithName:@"AvantGardeLT-Medium" size:24];
    //self.playlistTotal.font = [UIFont fontWithName:@"AvantGardeLT-Medium" size:14];
    //self.tracksTotal.font = [UIFont fontWithName:@"AvantGardeLT-Medium" size:40];
    //self.tracksLabel.font = [UIFont fontWithName:@"AvantGardeLT-Medium" size:14];
    
    self.waveformFull.hidden = YES;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    if (selected) {
        //self.backgroundColor = [UIColor colorWithRed:164/255.0 green:178/255.0 blue:14/255.0 alpha:0.3f];
        self.backgroundColor = [UIColor colorWithRed:1.0 green:0.2 blue:0.4 alpha:1.0];
    } else {
        self.backgroundColor = [UIColor clearColor];
    }
    
    [self setNeedsDisplay];
}

@end
