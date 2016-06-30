//
//  WelcomeViewController.m
//  WAVE
//
//  Created by Justin Bush on 2016-02-13.
//  Copyright © 2016 Dragos Panoiu. All rights reserved.
//

#import "AppDelegate.h"
#import "WelcomeViewController.h"
#import "MenuViewController.h"

@interface WelcomeViewController ()

@end

@implementation WelcomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (IBAction)continueButton:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hasSeenIntro"];
    UIStoryboard *storyboard = self.storyboard;
    WelcomeViewController *controller = [storyboard instantiateViewControllerWithIdentifier:@"SWRevealViewController"];
    [self presentViewController:controller animated:YES completion:nil];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
