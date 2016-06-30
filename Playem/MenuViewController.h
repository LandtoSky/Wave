//
//  MenuViewController.h
//  Playem
//
//  Created by Dragos Panoiu on 07/09/14.
//  Copyright (c) 2014 Dragos Panoiu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MenuViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *lblWelcome;
@property (weak, nonatomic) IBOutlet UIButton *btnFbLogin;
@property (weak, nonatomic) IBOutlet UIButton *btnLogout;
@property (weak, nonatomic) IBOutlet UILabel *lblShareSong;
@property (weak, nonatomic) IBOutlet UISwitch *swShare;

- (IBAction)facebookLogout:(id)sender;
- (IBAction)loginUserToFb:(id)sender;
- (IBAction)changeSwitch:(id)sender;

@end
