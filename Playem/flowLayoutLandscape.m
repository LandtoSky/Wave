//
//  flowLayoutLandscape.m
//  Playem
//
//  Created by Dragos Panoiu on 05/10/14.
//  Copyright (c) 2014 Dragos Panoiu. All rights reserved.
//

#import "flowLayoutLandscape.h"

@implementation flowLayoutLandscape

-(id)init
{
    if (!(self = [super init])) return nil;
    
    self.itemSize = CGSizeMake(447, 104);
    self.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0);
    self.minimumInteritemSpacing = 0.0f;
    self.minimumLineSpacing = 0.0f;
    
    return self;
}


@end
