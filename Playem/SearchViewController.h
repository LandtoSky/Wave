//
//  SearchViewController.h
//  Yusic
//
//  Created by Dragos Panoiu on 17/11/14.
//  Copyright (c) 2014 Dragos Panoiu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SearchViewController : UIViewController <UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UITableView *ytTable;
@property (weak, nonatomic) IBOutlet UILabel *lblAddtracks;

- (IBAction)closePopup:(id)sender;

@end
