//
//  SearchViewController.m
//  Yusic
//
//  Created by Dragos Panoiu on 17/11/14.
//  Copyright (c) 2014 Dragos Panoiu. All rights reserved.
//

#import "SearchViewController.h"
#import "MZFormSheetController.h"
#import "PlayemCore.h"
#import "SearchCell.h"
#import "MBProgressHUD.h"
#import "_utils.h"
#import "AFHTTPRequestOperationManager.h"

@interface SearchViewController ()

@end

@implementation SearchViewController {
    PlayemCore *pc;
    NSMutableArray *responses;
    NSMutableString *nextIndex;
    MBProgressHUD *searchLoader;
    MBProgressHUD *confirmLoader;
}

@synthesize searchBar, ytTable, lblAddtracks;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    pc = [PlayemCore sharedInstance];
    
    responses = [[NSMutableArray alloc] init];
    nextIndex = [NSMutableString stringWithString:@""];
    
    // lblAddtracks.font = [UIFont fontWithName:@"AvantGardeLT-Book" size:20];
      
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setTextColor:[UIColor whiteColor]];
    
    searchLoader = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:searchLoader];
    searchLoader.mode = MBProgressHUDModeIndeterminate;
    searchLoader.labelText = @"Loading...";
    
    confirmLoader = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:confirmLoader];
    confirmLoader.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark.png"]];
    confirmLoader.mode = MBProgressHUDModeCustomView;
    confirmLoader.labelText = @"Track added";
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //[searchBar becomeFirstResponder];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)theSearchBar {
    [theSearchBar setShowsCancelButton:YES animated:YES];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)theSearchBar {
    theSearchBar.text = @"";
    [theSearchBar setShowsCancelButton:NO animated:YES];
    [theSearchBar resignFirstResponder];
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (void)searchBarSearchButtonClicked:(UISearchBar *)theSearchBar {
    [responses removeAllObjects];
    [ytTable reloadData];
    [theSearchBar setShowsCancelButton:NO animated:YES];
    [theSearchBar resignFirstResponder];
    if([responses count]) {
        [responses removeAllObjects];
    }
    nextIndex = [NSMutableString stringWithString:@""];
    [self searchYoutube:theSearchBar.text start:nextIndex searchFor:[theSearchBar selectedScopeButtonIndex]];
}

- (void)searchBar:(UISearchBar *)theSearchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope
{
    if ([theSearchBar.text isEqualToString:@""]) {
        return;
    }
    [responses removeAllObjects];
    [ytTable reloadData];
    [theSearchBar setShowsCancelButton:NO animated:YES];
    [theSearchBar resignFirstResponder];
    if([responses count]) {
        [responses removeAllObjects];
    }
    nextIndex = [NSMutableString stringWithString:@""];
    [self searchYoutube:theSearchBar.text start:nextIndex searchFor:[theSearchBar selectedScopeButtonIndex]];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [searchBar resignFirstResponder];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (([scrollView contentOffset].y+scrollView.frame.size.height) == [scrollView contentSize].height) {
        [self searchYoutube:searchBar.text start:nextIndex searchFor:[searchBar selectedScopeButtonIndex]];
    }
    [searchBar resignFirstResponder];
}

- (IBAction)closePopup:(id)sender
{
    [self mz_dismissFormSheetControllerAnimated:YES completionHandler:^(MZFormSheetController *formSheetController) {}];
}

-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [responses count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"SearchCell";
    SearchCell *cell = [ytTable dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[SearchCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    if ([searchBar selectedScopeButtonIndex] == 0) {
        // display video search results
        cell.trackName.text = [responses[indexPath.row] valueForKey:@"title"];
        NSString *duration = [Utils timeFormatted:[[responses[indexPath.row] valueForKey:@"duration"] integerValue]];
        cell.trackDuration.text = duration;
        NSURL *imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@/maxresdefault.jpg", @"https://img.youtube.com/vi/", [responses[indexPath.row] valueForKey:@"id"]]];
        [cell.trackImage loadImageFromURL:imageURL placeholderImage:[UIImage imageNamed:@"NoArtworkSearch"] cachingKey:[responses[indexPath.row] valueForKey:@"id"]];
        cell.userInteractionEnabled = YES;
        cell.alpha = 1.00;
    } else {
        // display playlist search results
        cell.trackName.text = [responses[indexPath.row] valueForKey:@"title"];
        cell.trackDuration.text = [NSString stringWithFormat:@"%@ tracks", [responses[indexPath.row] valueForKey:@"size"]];
        NSURL *imageURL = [NSURL URLWithString:[responses[indexPath.row] valueForKey:@"thumbnail"]];
        [cell.trackImage loadImageFromURL:imageURL placeholderImage:[UIImage imageNamed:@"NoArtworkSearch"] cachingKey:[responses[indexPath.row] valueForKey:@"id"]];
        cell.userInteractionEnabled = YES;
        cell.alpha = 1.00;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row % 2) {
        cell.backgroundColor = [UIColor colorWithHexValue:0xEEEFEF];
    } else {
        cell.backgroundColor = [UIColor colorWithHexValue:0xFFFFFF];
    }
    
    if ([searchBar selectedScopeButtonIndex] == 0) {
        BOOL exists = [pc checkIfTrackInCurrentPlaylist:[responses[indexPath.row] valueForKey:@"id"]];
        if (exists) {
            [cell setUserInteractionEnabled:NO];
            [cell setAlpha:0.3];
        } else {
            [cell setUserInteractionEnabled:YES];
            [cell setAlpha:1.0];
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([searchBar selectedScopeButtonIndex] == 0) {
        // add track to playlist
        if ([tableView cellForRowAtIndexPath:indexPath].alpha < 1) {
            [pc deleteTrackFromCurrentPlaylist:responses[indexPath.row]];
            [[tableView cellForRowAtIndexPath:indexPath] setAlpha:1.0];
        } else {
            [pc addTrackToCurrentPlaylist:responses[indexPath.row]];
            //[[tableView cellForRowAtIndexPath:indexPath] setUserInteractionEnabled:NO];
            [[tableView cellForRowAtIndexPath:indexPath] setAlpha:0.3];
            confirmLoader.labelText = @"Track Added!";
            [confirmLoader showAnimated:YES whileExecutingBlock:^{
                sleep(0.5f);
            }];
        }
    } else {
        // save the selected playlist
        [pc copyPlaylist:responses[indexPath.row]];
        [[tableView cellForRowAtIndexPath:indexPath] setUserInteractionEnabled:NO];
        [[tableView cellForRowAtIndexPath:indexPath] setAlpha:0.3];
        confirmLoader.labelText = @"Album Added!";
        [confirmLoader showAnimated:YES whileExecutingBlock:^{
            sleep(1);
        }];
    }
}

- (void)searchYoutube:(NSString *)query start:(NSString *)start searchFor:(NSInteger)scope
{
    [searchLoader show:YES];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    AFHTTPRequestSerializer *requestSerializer = [AFHTTPRequestSerializer serializer];
    NSString *ua = @"Mozilla/5.0 (Macintosh; Intel Mac OS X 10.10; rv:33.0) Gecko/20100101 Firefox/33.0";
    [requestSerializer setValue:ua forHTTPHeaderField:@"User-Agent"];
    manager.requestSerializer = requestSerializer;
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    securityPolicy.allowInvalidCertificates = YES;
    securityPolicy.validatesDomainName = NO;
    manager.securityPolicy = securityPolicy;
    
    NSString *searchURL = @"";
    
    if (scope == 0) {
        // search for videos
        searchURL = [NSString stringWithFormat:@"https://www.googleapis.com/youtube/v3/search?key=%@&part=id&type=video&maxResults=20&safeSearch=none&q=%@&pageToken=%@", pc.youtubeKey, [query stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], start];
        
        [manager GET:searchURL parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            nextIndex = [responseObject valueForKey:@"nextPageToken"];
            
            NSMutableArray *itemsIds = [[NSMutableArray alloc] init];
            for (id obj in [responseObject objectForKey:@"items"]) {
                [itemsIds addObject:[obj valueForKeyPath:@"id.videoId"]];
            }
            
            NSString *detailsURL = [NSString stringWithFormat:@"https://www.googleapis.com/youtube/v3/videos?key=%@&part=snippet,contentDetails&maxResults=20&id=%@", pc.youtubeKey, [itemsIds componentsJoinedByString:@","]];
            [manager GET:detailsURL parameters:nil success:^(AFHTTPRequestOperation *op, id resp) {
                for (id obj in [resp objectForKey:@"items"]) {
                    NSInteger duration = [Utils parseISO8601Time:[obj valueForKeyPath:@"contentDetails.duration"]];
                    NSDictionary *itm = [[NSDictionary alloc] initWithObjects:@[[obj valueForKey:@"id"], [obj valueForKeyPath:@"snippet.title"], [obj valueForKeyPath:@"snippet.channelId"], [NSNumber numberWithInteger:duration]] forKeys:@[@"id", @"title", @"uploader", @"duration"]];
                    [responses addObject:itm];
                }
                
                [ytTable reloadData];
                if ([start isEqualToString:@""]) {
                    [ytTable setContentOffset:CGPointZero animated:YES];
                }
                [searchLoader hide:YES];
                
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSLog(@"Error retrieving Youtube feed: %@", [error description]);
            }];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error retrieving Youtube feed: %@", [error description]);
        }];
        
    } else {
        // search for playlists
        searchURL = [NSString stringWithFormat:@"https://www.googleapis.com/youtube/v3/search?key=%@&part=id&type=playlist&maxResults=20&safeSearch=none&q=%@&pageToken=%@", pc.youtubeKey, [query stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], start];
        
        [manager GET:searchURL parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            nextIndex = [responseObject valueForKey:@"nextPageToken"];
            
            NSMutableArray *itemsIds = [[NSMutableArray alloc] init];
            for (id obj in [responseObject objectForKey:@"items"]) {
                [itemsIds addObject:[obj valueForKeyPath:@"id.playlistId"]];
            }
            
            NSString *detailsURL = [NSString stringWithFormat:@"https://www.googleapis.com/youtube/v3/playlists?key=%@&part=snippet,contentDetails&maxResults=20&id=%@", pc.youtubeKey, [itemsIds componentsJoinedByString:@","]];
            [manager GET:detailsURL parameters:nil success:^(AFHTTPRequestOperation *op, id resp) {
                for (id obj in [resp objectForKey:@"items"]) {
                    NSDictionary *itm = [[NSDictionary alloc] initWithObjects:@[[obj valueForKey:@"id"], [obj valueForKeyPath:@"snippet.title"], [obj valueForKeyPath:@"snippet.thumbnails.medium.url"], [obj valueForKeyPath:@"contentDetails.itemCount"]] forKeys:@[@"id", @"title", @"thumbnail", @"size"]];
                    [responses addObject:itm];
                }
                
                [ytTable reloadData];
                if ([start isEqualToString:@""]) {
                    [ytTable setContentOffset:CGPointZero animated:YES];
                }
                [searchLoader hide:YES];
                
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSLog(@"Error retrieving YouTube feed: %@", [error description]);
            }];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error retrieving YouTube feed: %@", [error description]);
        }];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
