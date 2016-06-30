//
//  AppDelegate.m
//  Playem
//
//  Created by Dragos Panoiu on 03/09/14.
//  Copyright (c) 2014 Dragos Panoiu. All rights reserved.
//

#import "AppDelegate.h"
#import "MZFormSheetController.h"
#import "PlayemCore.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>

@interface AppDelegate () {
    PlayemCore *pc;
}

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    pc = [PlayemCore sharedInstance];
    [pc loadParser];
    
    return [[FBSDKApplicationDelegate sharedInstance] application:application didFinishLaunchingWithOptions:launchOptions];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    __block UIBackgroundTaskIdentifier background_task;
    
    background_task = [application beginBackgroundTaskWithExpirationHandler:^ {
        [application endBackgroundTask: background_task];
        background_task = UIBackgroundTaskInvalid;
    }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while(TRUE)
        {
            //NSTimeInterval timeLeft = [UIApplication sharedApplication].backgroundTimeRemaining;
            //NSLog(@"Background time remaining: %f seconds (%d mins)", timeLeft, (int)(timeLeft / 60));
            [NSThread sleepForTimeInterval:60]; //wait for 1 min
        }
    });
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [FBSDKAppEvents activateApp];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    
}

- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        return UIInterfaceOrientationMaskPortrait;
    } else {
        return UIInterfaceOrientationMaskAll;
    }
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    return [[FBSDKApplicationDelegate sharedInstance] application:application
                                                          openURL:url
                                                sourceApplication:sourceApplication
                                                       annotation:annotation
            ];
}

@end
