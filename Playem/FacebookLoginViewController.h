//
//  FacebookLoginViewController.h
//  Yusic
//
//  Created by Dragos Panoiu on 01/02/15.
//  Copyright (c) 2015 Dragos Panoiu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FacebookLoginViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIButton *btnFbLogin;
@property (weak, nonatomic) IBOutlet UIButton *btnSkip;
@property (weak, nonatomic) IBOutlet UILabel *lblLine1;
@property (weak, nonatomic) IBOutlet UILabel *lblLine2;

- (IBAction)loginUserToFb:(id)sender;
- (IBAction)closePopup:(id)sender;

@end
