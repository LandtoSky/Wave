//
//  SearchCell.h
//  Yusic
//
//  Created by Dragos Panoiu on 17/11/14.
//  Copyright (c) 2014 Dragos Panoiu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SearchCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *trackImage;
@property (weak, nonatomic) IBOutlet UILabel *trackName;
@property (weak, nonatomic) IBOutlet UILabel *trackDuration;

@end
