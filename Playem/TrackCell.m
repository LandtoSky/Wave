//
//  TrackCell.m
//  Playem
//
//  Created by Dragos Panoiu on 16/09/14.
//  Copyright (c) 2014 Dragos Panoiu. All rights reserved.
//

#import "TrackCell.h"

@implementation TrackCell

-(void)setFrame:(CGRect)frame {
    self.bottomBorder.hidden = YES;
    self.middleBorder.hidden = YES;
    self.backgroundColor = [UIColor clearColor];
    
    if (([[UIDevice currentDevice] orientation] == UIInterfaceOrientationLandscapeLeft) || ([[UIDevice currentDevice] orientation] == UIInterfaceOrientationLandscapeRight)) {
        //self.lblTrackName.font = [UIFont fontWithName:@"AvantGardeLT-Book" size:18];
        self.lblTrackName.preferredMaxLayoutWidth = 250;
    } else {
        //self.lblTrackName.font = [UIFont fontWithName:@"AvantGardeLT-Book" size:15];
        self.lblTrackName.preferredMaxLayoutWidth = 140;
    }
    
    self.lblTrackDuration.font = [UIFont fontWithName:@"AvantGardeLT-Book" size:10];
    
    [self setNeedsDisplay];
}

- (void)prepareForReuse {
    self.bottomBorder.hidden = YES;
    self.middleBorder.hidden = YES;
    self.backgroundColor = [UIColor clearColor];
    
    if (([[UIDevice currentDevice] orientation] == UIInterfaceOrientationLandscapeLeft) || ([[UIDevice currentDevice] orientation] == UIInterfaceOrientationLandscapeRight)) {
        //self.lblTrackName.font = [UIFont fontWithName:@"AvantGardeLT-Book" size:18];
        self.lblTrackName.preferredMaxLayoutWidth = 250;
    } else {
        //self.lblTrackName.font = [UIFont fontWithName:@"AvantGardeLT-Book" size:15];
        self.lblTrackName.preferredMaxLayoutWidth = 140;
    }
    
    self.lblTrackDuration.font = [UIFont fontWithName:@"AvantGardeLT-Book" size:10];
    
    [self setNeedsDisplay];
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];

    if (selected) {
        // self.backgroundColor = [UIColor colorWithRed:164/255.0 green:178/255.0 blue:14/255.0 alpha:0.3f];
        // self.backgroundColor = [UIColor colorWithRed:0.2 green:0.29 blue:0.37 alpha:1.0];
        self.backgroundColor = [UIColor colorWithRed:1.0 green:0.16 blue:0.41 alpha:0.1];
    } else {
        self.backgroundColor = [UIColor clearColor];
    }

    [self setNeedsDisplay];
}


@end
