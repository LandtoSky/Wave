//
//  TrackCell.h
//  Playem
//
//  Created by Dragos Panoiu on 16/09/14.
//  Copyright (c) 2014 Dragos Panoiu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TrackCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIImageView *imgTrackImage;
@property (weak, nonatomic) IBOutlet UILabel *lblTrackName;
@property (weak, nonatomic) IBOutlet UILabel *lblTrackDuration;
@property (weak, nonatomic) IBOutlet UILabel *bottomBorder;
@property (weak, nonatomic) IBOutlet UILabel *middleBorder;
@property (weak, nonatomic) IBOutlet UIButton *btnDelete;

@end
