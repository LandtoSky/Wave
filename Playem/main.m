//
//  main.m
//  Playem
//
//  Created by Dragos Panoiu on 03/09/14.
//  Copyright (c) 2014 Dragos Panoiu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

int main(int argc, char * argv[]) {
    @autoreleasepool {
        signal(SIGPIPE, SIG_IGN);
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
