//
//  flowLayoutPortrait.m
//  Playem
//
//  Created by Dragos Panoiu on 05/10/14.
//  Copyright (c) 2014 Dragos Panoiu. All rights reserved.
//

#import "flowLayoutPortrait.h"

@implementation flowLayoutPortrait

-(id)init
{
    if (!(self = [super init])) return nil;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        self.itemSize = CGSizeMake([[UIScreen mainScreen] bounds].size.width-20, 85);
    } else {
        self.itemSize = CGSizeMake(319, 104);
    }
    self.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0);
    self.minimumInteritemSpacing = 0.0f;
    self.minimumLineSpacing = 0.0f;
    
    return self;
}


@end
