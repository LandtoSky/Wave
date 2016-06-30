//
//  PlayemCore.m
//  Playem
//
//  Created by Dragos Panoiu on 04/03/14.
//  Copyright (c) 2014 Dragos Panoiu. All rights reserved.
//

#import "PlayemCore.h"
#import "DBController.h"
#import "DataTable.h"
#import "AFHTTPRequestOperationManager.h"
#import "AFHTTPRequestOperation.h"
#import "FTWCache.h"
#import "_utils.h"
#import "MBProgressHUD.h"
#import "RNDecryptor.h"

@implementation PlayemCore

@synthesize audioPlayer, selectedPlaylistID, selectedPlaylistRow, playingPlaylist, playingTrack, manager, repeat, shuffle, webView, neededView, fbLoggedIn, fbUserInfo, autoShareTrack, youtubeKey;

// define urls
static NSString *const parse_url = @"https://www.panoiu.com/yusic/api/ping";
static NSString *const share_url = @"https://itunes.apple.com/us/app/the-wave-free-music-streaming/id1107339484?ls=1&mt=8";//@"https://www.panoiu.com/yusic/play/";
static NSString *const fb_url = @"https://www.panoiu.com/yusic/api/saveuser";

+ (id)sharedInstance {
    static PlayemCore *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (id)init
{
    if (self = [super init]) {
        // Listen audio session interruption notification
        [[NSNotificationCenter defaultCenter]
            addObserver:self
            selector:@selector(handleAudioSessionInterruption:)
            name:AVAudioSessionInterruptionNotification
            object:[AVAudioSession sharedInstance]
         ];
        
        [FBSDKProfile enableUpdatesOnAccessTokenChange:YES];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(_accessTokenChanged:)
                                                     name:FBSDKAccessTokenDidChangeNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(_currentProfileChanged:)
                                                     name:FBSDKProfileDidChangeNotification
                                                   object:nil];
        
        // init reachability
        [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
            [self reachabilityDidChange:status];
        }];
        [[AFNetworkReachabilityManager sharedManager] startMonitoring];
        
        // init db connection
        db = [DBController sharedDatabaseController:@"playem.sqlite"];
        playlistItems = [[DataTable alloc] init];
        trackItems = [[DataTable alloc] init];
        isPlayingBeforeInterrupted = NO;
        fbLoggedIn = NO;
        fbUserInfo = nil;
        autoShareTrack = NO;
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        if ([[defaults valueForKey:@"shareTrack"] boolValue] == YES) {
            autoShareTrack = YES;
        } else {
            autoShareTrack = NO;
        }
        
        // init
        selectedPlaylistID = -1;
        selectedPlaylistRow = -1;
        playingPlaylist = -1;
        playingTrack = -1;
        repeat = YES;
        shuffle = NO;
        manager = [AFHTTPRequestOperationManager manager];
        webView = [[UIWebView alloc] init];
        webView.delegate = self;
        playlists = [[NSMutableArray alloc] init];
        tracks = [[NSMutableArray alloc] init];
        youtubeKey = @"";
    }
    return self;
}

- (void)loadMedia:(NSString *)url completion:(void (^)(BOOL))completion
{
    if (audioPlayer != nil) {
        audioPlayer = nil;
    }
    
    NSLog(@"creating new player");
    
    NSDictionary *options = @{
                              AVOptionNameAVProbeSize : @(100000),   // 500kb, default is 5Mb
                              AVOptionNameHttpUserAgent : [self getUserAgent],
                              AVOptionNameHttpTimeout : @(10)
                              };
    
    audioPlayer = [[FFAVPlayerController alloc] init];
    audioPlayer.delegate = self;
    audioPlayer.shouldPlayOnBackground = YES;
    audioPlayer.shouldAutoPlay = YES;
    audioPlayer.streamDiscardOption = kAVStreamDiscardOptionVideo;
    [audioPlayer openMedia:url withOptions:options onFinishedHandler:completion];
}

- (void)loadParser
{
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    //AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    //securityPolicy.allowInvalidCertificates = YES;
    //securityPolicy.validatesDomainName = NO;
    //manager.securityPolicy = securityPolicy;
    
    // get parser source
    NSDate *now = [NSDate date];
    NSString *pingURL = [NSString stringWithFormat:@"%@?%d", parse_url, (int)[now timeIntervalSince1970]];
    [manager GET:pingURL parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *encryptedText = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        NSData *decryptedData = [RNDecryptor decryptData:[[NSData alloc] initWithBase64EncodedString:encryptedText options:0]
                                            withPassword:@"TF763*73|.kN73E"
                                                   error:nil];
        NSString *decryptedString = [[NSString alloc] initWithData:decryptedData encoding:NSUTF8StringEncoding];
        NSString *parserHtml = [NSString stringWithFormat:@"<html><head><script type=\"text/javascript\">%@</script></head><body>Copyright 2015 WAVE</body></html>", decryptedString];
        
        [webView loadHTMLString:parserHtml baseURL:[NSURL URLWithString:@"yusic.fm"]];
        NSLog(@"parser loaded");
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error downloading parser: %@", error);
    }];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    youtubeKey = [self getYoutubeAPIKey];
}

- (NSArray *) loadPlaylists
{
    NSMutableArray *results = [[NSMutableArray alloc] init];
    NSString *query = [NSString stringWithFormat:@"SELECT * FROM playlists ORDER BY playlist_created ASC"];
    playlistItems = [db ExecuteQuery:query];
    for (id object in playlistItems.rows) {
        NSMutableDictionary *plinfo = [[NSMutableDictionary alloc] init];
        [plinfo setValue:object[[playlistItems colIndex:@"playlist_id"]] forKey:@"playlist_id"];
        [plinfo setValue:object[[playlistItems colIndex:@"playlist_name"]] forKey:@"playlist_name"];
        
        NSString *tracksQuery = [NSString stringWithFormat:@"SELECT track_duration FROM tracks WHERE playlist_id = '%ld'", (long)[object[[playlistItems colIndex:@"playlist_id"]] integerValue]];
        DataTable *tracksTBL = [db ExecuteQuery:tracksQuery];
        NSInteger totalDuration = 0;
        for (id track in tracksTBL.rows) {
            totalDuration += [Utils secondsForTimeString:track[[tracksTBL colIndex:@"track_duration"]]];
        }
        [plinfo setValue:[NSNumber numberWithLong:tracksTBL.rows.count] forKey:@"playlist_tracks"];
        [plinfo setValue:[NSNumber numberWithInteger:totalDuration] forKey:@"playlist_duration"];
        [results addObject:plinfo];
    }
    playlists = results;
    return results;
}

- (NSArray *) loadTracksFromPlaylist:(NSInteger)playlistID
{
    NSMutableArray *results = [[NSMutableArray alloc] init];
    NSString *query = [NSString stringWithFormat:@"SELECT * FROM tracks WHERE playlist_id = '%ld' ORDER BY track_order ASC", (long)selectedPlaylistID];
    trackItems = [db ExecuteQuery:query];
    for (id object in trackItems.rows) {
        NSMutableDictionary *trinfo = [[NSMutableDictionary alloc] init];
        [trinfo setValue:object[[trackItems colIndex:@"track_id"]] forKey:@"track_id"];
        [trinfo setValue:object[[trackItems colIndex:@"track_name"]] forKey:@"track_name"];
        [trinfo setValue:object[[trackItems colIndex:@"track_videoid"]] forKey:@"track_videoid"];
        [trinfo setValue:object[[trackItems colIndex:@"track_duration"]] forKey:@"track_duration"];
        [results addObject:trinfo];
    }
    tracks = results;
    return results;
}

- (void) selectPlaylist:(NSInteger)playlistID withPlaylistRow:(NSInteger)playlistRow
{
    selectedPlaylistID = playlistID;
    selectedPlaylistRow = playlistRow;
}

- (NSDictionary *) getCurrentPlaylistInfo
{
    NSMutableDictionary *results = [[NSMutableDictionary alloc] init];
    NSString *query = [NSString stringWithFormat:@"SELECT * FROM playlists WHERE playlist_id = '%ld'", (long)selectedPlaylistID];
    DataTable *plInfo = [db ExecuteQuery:query];
    
    [results setValue:plInfo.rows[0][[plInfo colIndex:@"playlist_id"]] forKey:@"playlist_id"];
    [results setValue:plInfo.rows[0][[plInfo colIndex:@"playlist_name"]] forKey:@"playlist_name"];
    
    NSString *tracksQuery = [NSString stringWithFormat:@"SELECT track_duration FROM tracks WHERE playlist_id = '%ld'", (long)selectedPlaylistID];
    DataTable *tracksTBL = [db ExecuteQuery:tracksQuery];
    NSInteger totalDuration = 0;
    for (id track in tracksTBL.rows) {
        totalDuration += [Utils secondsForTimeString:track[[tracksTBL colIndex:@"track_duration"]]];
    }
    [results setValue:[NSNumber numberWithLong:tracksTBL.rows.count] forKey:@"playlist_tracks"];
    [results setValue:[NSNumber numberWithInteger:totalDuration] forKey:@"playlist_duration"];
    
    return results;
}

- (NSDictionary *) getCurrentTrackInfo
{
    NSMutableDictionary *results = [[NSMutableDictionary alloc] init];
    NSString *query = [NSString stringWithFormat:@"SELECT * FROM tracks WHERE track_id = '%@'", [tracks[playingTrack] valueForKey:@"track_id"]];
    DataTable *trInfo = [db ExecuteQuery:query];
    
    [results setValue:trInfo.rows[0][[trInfo colIndex:@"track_videoid"]] forKey:@"track_videoid"];
    [results setValue:trInfo.rows[0][[trInfo colIndex:@"track_name"]] forKey:@"track_name"];
    [results setValue:trInfo.rows[0][[trInfo colIndex:@"track_duration"]] forKey:@"track_duration"];
    
    return results;
}

- (BOOL)isPlaying
{
    BOOL result = NO;
    AVPlayerState currentState = audioPlayer.playerState;
    if (currentState == kAVPlayerStatePlaying) {
        result = YES;
    }
    
    return result;
}

- (BOOL)isPaused
{
    BOOL result = NO;
    AVPlayerState currentState = audioPlayer.playerState;
    if (currentState == kAVPlayerStatePaused) {
        result = YES;
    }
    
    return result;
}

- (void) FFAVPlayerControllerDidStateChange:(FFAVPlayerController *)controller
{
    AVPlayerState currentState = audioPlayer.playerState;
    
    if (currentState == kAVPlayerStatePlaying) {
        isPlayingBeforeInterrupted = YES;
        [self enableAudioSession:YES];
    } else {
        isPlayingBeforeInterrupted = NO;
        [self enableAudioSession:NO];
    }
    
    if (currentState == kAVPlayerStateFinishedPlayback) {
        [self playNextTrack];
    }
}

- (void) FFAVPlayerControllerDidCurTimeChange:(FFAVPlayerController *)controller position:(NSTimeInterval)position
{
    NSTimeInterval duration = [audioPlayer duration];
    
    if ([self.delegate respondsToSelector:@selector(updatePlaybackProgress:withProgress:)]) {
        [self.delegate updatePlaybackProgress:duration withProgress:position];
    }
}

# pragma mark Parse Youtube

- (void) parseYoutube:(NSString *)video_id
{
    if ([manager.operationQueue operationCount] > 0) {
        [manager.operationQueue cancelAllOperations];
    }
    
    AFHTTPRequestSerializer *requestSerializer = [AFHTTPRequestSerializer serializer];
    NSString *ua = [self getUserAgent];
    [requestSerializer setValue:ua forHTTPHeaderField:@"User-Agent"];
    manager.requestSerializer = requestSerializer;
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    securityPolicy.allowInvalidCertificates = YES;
    securityPolicy.validatesDomainName = NO;
    manager.securityPolicy = securityPolicy;
    
    // show buffering
    if ([self.delegate respondsToSelector:@selector(updateBufferingStatus:)]) {
        [self.delegate updateBufferingStatus:YES];
    }
    
    // get youtube html source
    NSString *youtube_url = [NSString stringWithFormat:@"https://www.youtube.com/watch?v=%@&gl=US&hl=en&has_verified=1&bpctr=9999999999", video_id];
    [manager GET:youtube_url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *htmlsource = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:[self getRegexPattern] options:NSRegularExpressionCaseInsensitive error:nil];
        NSTextCheckingResult *match = [regex firstMatchInString:htmlsource options:0 range:NSMakeRange(0, [htmlsource length])];
        NSString *music_url = [self decryptYoutubeUrl:[htmlsource substringWithRange:[match rangeAtIndex:1]]];
        //NSLog(@"URL: %@", music_url);
        
        // video deleted or private
        if ([htmlsource length] > 0 && [htmlsource hasString:@"<title>YouTube</title>"]) {
            MBProgressHUD *alertHUD = [[MBProgressHUD alloc] initWithView:self.neededView];
            [self.neededView addSubview:alertHUD];
            alertHUD.mode = MBProgressHUDModeText;
            alertHUD.labelText = @"Youtube Removed Video";
            alertHUD.detailsLabelText = @"This track has been removed due to Copyright Infringement. Please remove it from your playlist.";
            [alertHUD showAnimated:YES whileExecutingBlock:^{
                sleep(5.0f);
            }];
            
            /*
            [self deleteTrack:playingTrack];
            [self loadTracksFromPlaylist:playingPlaylist];
            if (playingTrack > 0) {
                playingTrack -= 1;
            } else {
                playingTrack = 0;
            }
            */
            [self playNextTrack];
            return;
        }
        
        // age restricted video
        if ([htmlsource length] > 0 && [htmlsource hasString:@"player-age-gate-content"]) {
            [self parseAgeRestrictedYoutube:video_id];
            return;
        }
        
        // show buffering
        if ([self.delegate respondsToSelector:@selector(updateBufferingStatus:)]) {
            [self.delegate updateBufferingStatus:YES];
        }
        
        [self loadMedia:music_url completion:^(BOOL loaded) {
            if (loaded) {
                NSLog(@"track finished loading");
                if (fbLoggedIn && autoShareTrack) {
                    [self shareTrack:NO];
                }
            } else {
                NSLog(@"track FAILED loading");
                [self playNextTrack];
            }
            
            // hide buffering
            if ([self.delegate respondsToSelector:@selector(updateBufferingStatus:)]) {
                [self.delegate updateBufferingStatus:NO];
            }
        }];
        
        if ([self.delegate respondsToSelector:@selector(updatePlayerInterface:)]) {
            [self.delegate updatePlayerInterface:YES];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error retrieving YouTube html: %@", error.description);
    }];
}

- (NSString *)decryptYoutubeUrl:(NSString *)html
{
    NSString *jsCall = [NSString stringWithFormat:@"parse('%@')", [[html stringByReplacingOccurrencesOfString:@"\n" withString:@" "] stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"]];
    NSString *returnUrl = [webView stringByEvaluatingJavaScriptFromString:jsCall];
    return returnUrl;
}

- (NSString *)getUserAgent
{
    NSString *userAgent = [webView stringByEvaluatingJavaScriptFromString:@"getUserAgent()"];
    return userAgent;
}

- (NSString *)getRegexPattern
{
    NSString *regexPattern = [webView stringByEvaluatingJavaScriptFromString:@"getRegexPattern()"];
    return regexPattern;
}

- (NSString *)getYoutubeAPIKey
{
    NSString *key = [webView stringByEvaluatingJavaScriptFromString:@"getYoutubeAPIKey()"];
    return key;
}

- (void) playTrack:(NSInteger)trackNo
{
    if (playingPlaylist == selectedPlaylistRow && playingTrack == trackNo) {
        return;
    }
    
    if ([self isPlaying]) {
        [audioPlayer stop];
    }
    
    if (trackItems.rows.count == 0)
        return;
    playingTrack = trackNo;
    playingPlaylist = selectedPlaylistRow;
    
    // build track info dictionary
    UIImage *noArtwork = [UIImage imageNamed:@"NoArtworkMax"];
    currentTrackInfo = [[NSMutableDictionary alloc] init];
    NSString *videoid = [tracks[trackNo] valueForKey:@"track_videoid"];
    NSString *title = [tracks[trackNo] valueForKey:@"track_name"];
    NSString *durationString = [tracks[trackNo] valueForKey:@"track_duration"];
    UIImageView *thumb = [[UIImageView alloc] init];
    NSURL *imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@/maxresdefault.jpg", @"https://img.youtube.com/vi/", videoid]];
    [thumb loadImageFromURL:imageURL placeholderImage:noArtwork cachingKey:videoid];
    if (thumb.image != nil) {
        MPMediaItemArtwork *albumArt = [[MPMediaItemArtwork alloc] initWithImage:thumb.image];
        [currentTrackInfo setObject:albumArt forKey:MPMediaItemPropertyArtwork];
    }
    
    [currentTrackInfo setObject:@"WAVE" forKey:MPMediaItemPropertyArtist];
    [currentTrackInfo setObject:title forKey:MPMediaItemPropertyTitle];
    [currentTrackInfo setObject:[NSNumber numberWithInteger:[Utils secondsForTimeString:durationString]] forKey:MPMediaItemPropertyPlaybackDuration];
    [currentTrackInfo setObject:[NSNumber numberWithInteger:0] forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
    [currentTrackInfo setObject:[NSNumber numberWithInt:1] forKey:MPNowPlayingInfoPropertyPlaybackRate];
    [currentTrackInfo setObject:[NSNumber numberWithLong:tracks.count] forKey:MPNowPlayingInfoPropertyPlaybackQueueCount];
    
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:currentTrackInfo];
    
    // play track
    [self parseYoutube:[tracks[trackNo] valueForKey:@"track_videoid"]];
}

- (void) stopPlaying
{
    if ([self isPlaying]) {
        [audioPlayer stop];
    }
    if ([self.delegate respondsToSelector:@selector(updatePlayerInterface:)]) {
        [self.delegate updatePlayerInterface:NO];
    }
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:nil];
}

- (void)startPlaying
{
    if ([self isPlaying]) {
        [audioPlayer pause];
        if ([self.delegate respondsToSelector:@selector(updatePlayerInterface:)]) {
            [self.delegate updatePlayerInterface:NO];
        }
    } else {
        currentTrackInfo = [[[MPNowPlayingInfoCenter defaultCenter] nowPlayingInfo] mutableCopy];
        [currentTrackInfo setObject:[NSNumber numberWithInteger:audioPlayer.currentTime] forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
        [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:currentTrackInfo];
        [audioPlayer resume];
        if ([self.delegate respondsToSelector:@selector(updatePlayerInterface:)]) {
            [self.delegate updatePlayerInterface:YES];
        }
    }
}

- (void) playNextTrack
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(playNext) object:nil];
    [self performSelector:@selector(playNext) withObject:nil afterDelay:0.0];
}

- (void) playPrevTrack
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(playPrev) object:nil];
    [self performSelector:@selector(playPrev) withObject:nil afterDelay:0.0];
}

- (void) playNext
{
    if (shuffle) {
        NSInteger item = arc4random() % trackItems.rows.count;
        if (item == playingTrack) {
            item = arc4random() % trackItems.rows.count;
        }
        [self playTrack:item];
    } else {
        if (playingTrack == trackItems.rows.count-1) {
            if (repeat) {
                [self playTrack:0];
            } else {
                [self stopPlaying];
            }
        } else {
            [self playTrack:(playingTrack+1)];
        }
    }
}

- (void) playPrev
{
    if ([audioPlayer currentTime] >= 15) {
        [audioPlayer seekto:0.0f];
        return;
    }
    if (shuffle) {
        NSInteger item = arc4random() % trackItems.rows.count;
        if (item == playingTrack) {
            item = arc4random() % trackItems.rows.count;
        }
        [self playTrack:item];
    } else {
        if (playingTrack == 0) {
            if (repeat) {
                [self playTrack:(trackItems.rows.count-1)];
            } else {
                [self stopPlaying];
            }
        } else {
            [self playTrack:(playingTrack-1)];
        }
    }
}

- (void) deleteTrack:(NSInteger)trackNo
{
    NSString *query = [NSString stringWithFormat:@"DELETE FROM tracks WHERE playlist_id = '%ld' AND track_id = '%@'", (long)selectedPlaylistID, [tracks[trackNo] valueForKey:@"track_id"]];
    [db ExecuteNonQuery:query];
}

- (void) deletePlaylist:(NSInteger)playlistID
{
    NSString *query1 = [NSString stringWithFormat:@"DELETE FROM playlists WHERE playlist_id = '%ld'",(long)playlistID];
    [db ExecuteNonQuery: query1];
    NSString *query2 = [NSString stringWithFormat:@"DELETE FROM tracks WHERE playlist_id = '%ld'",(long)playlistID];
    [db ExecuteNonQuery: query2];
}

- (void) createPlaylist:(NSString *)name
{
    if (![[name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqual: @""]) {
        NSString *query = [NSString stringWithFormat:@"INSERT INTO playlists(playlist_name) VALUES('%@')", [name stringByReplacingOccurrencesOfString:@"'" withString:@"''"]];
        [db ExecuteINSERT: query];
    }
}

- (void) editPlaylist:(NSString *)name playlistID:(NSInteger)playlistID
{
    if (![[name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqual: @""]) {
        NSString *query = [NSString stringWithFormat:@"UPDATE playlists SET playlist_name = '%@' WHERE playlist_id = '%ld'", [name stringByReplacingOccurrencesOfString:@"'" withString:@"''"], (long)playlistID];
        [db ExecuteNonQuery: query];
    }
}

- (void) copyPlaylist:(NSDictionary *)playlistInfo
{
    if (![[[playlistInfo valueForKey:@"id"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqual: @""]) {
        AFHTTPRequestSerializer *requestSerializer = [AFHTTPRequestSerializer serializer];
        NSString *ua = [self getUserAgent];
        [requestSerializer setValue:ua forHTTPHeaderField:@"User-Agent"];
        manager.requestSerializer = requestSerializer;
        manager.responseSerializer = [AFJSONResponseSerializer serializer];
        
        AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
        securityPolicy.allowInvalidCertificates = YES;
        securityPolicy.validatesDomainName = NO;
        manager.securityPolicy = securityPolicy;
        
        // get playlist details
        NSString *tracksURL = [NSString stringWithFormat:@"https://www.googleapis.com/youtube/v3/playlistItems?key=%@&part=snippet,contentDetails&maxResults=50&playlistId=%@", youtubeKey, [playlistInfo valueForKey:@"id"]];
        [manager GET:tracksURL parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSMutableArray *itemsIds = [[NSMutableArray alloc] init];
            for (id obj in [responseObject objectForKey:@"items"]) {
                [itemsIds addObject:[obj valueForKeyPath:@"contentDetails.videoId"]];
            }
            
            NSString *detailsURL = [NSString stringWithFormat:@"https://www.googleapis.com/youtube/v3/videos?key=%@&part=snippet,contentDetails&maxResults=50&id=%@", youtubeKey, [itemsIds componentsJoinedByString:@","]];
            [manager GET:detailsURL parameters:nil success:^(AFHTTPRequestOperation *op, id resp) {
                for (id obj in [resp objectForKey:@"items"]) {
                    NSInteger duration = [Utils parseISO8601Time:[obj valueForKeyPath:@"contentDetails.duration"]];
                    NSDictionary *itm = [[NSDictionary alloc] initWithObjects:@[[obj valueForKey:@"id"], [obj valueForKeyPath:@"snippet.title"], [obj valueForKeyPath:@"snippet.channelId"], [NSNumber numberWithInteger:duration]] forKeys:@[@"id", @"title", @"uploader", @"duration"]];
                    [self addTrackToPlaylist:selectedPlaylistID withTrackInfo:itm];
                }
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSLog(@"Error retrieving Youtube feed: %@", [error description]);
            }];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error downloading Youtube playlist: %@", error);
        }];
    }
}

- (BOOL) checkIfTrackInCurrentPlaylist:(NSString *)YoutubeID
{
    NSString *query = [NSString stringWithFormat:@"SELECT COUNT(*) FROM tracks WHERE playlist_id = %ld AND track_videoid = '%@'", (long)selectedPlaylistID, YoutubeID];
    NSInteger exists = [db ExecuteScalar:query asInt:YES];
    BOOL result = NO;
    if (exists > 0) {
        result = YES;
    }
    
    return result;
}

- (void) addTrackToCurrentPlaylist:(NSDictionary *)trackInfo
{
    NSString *query1 = [NSString stringWithFormat:@"SELECT MAX(track_order) FROM tracks WHERE playlist_id = '%ld'", (long)selectedPlaylistID];
    long max = (long)[db ExecuteScalar:query1 asInt:YES];
    
    long minutes = [[trackInfo valueForKey:@"duration"] integerValue] / 60;
    long seconds = [[trackInfo valueForKey:@"duration"] integerValue] % 60;
    NSString *duration = [NSString stringWithFormat:@"%ld:%02ld", minutes, seconds];
    NSString *qinsert = [NSString stringWithFormat:@"INSERT INTO tracks (playlist_id,track_name,track_artist,track_duration,track_videoid,track_order) VALUES (%ld,'%@','%@','%@','%@','%ld')", (long)selectedPlaylistID, [[trackInfo valueForKey:@"title"] stringByReplacingOccurrencesOfString:@"'" withString:@"''"], [[trackInfo valueForKey:@"uploader"] stringByReplacingOccurrencesOfString:@"'" withString:@"''"], duration, [trackInfo valueForKey:@"id"], max+1];
    [db ExecuteINSERT:qinsert];
}

- (void) deleteTrackFromCurrentPlaylist:(NSDictionary *)trackInfo
{
    NSString *videoid = [trackInfo valueForKey:@"id"];
    NSString *query1 = [NSString stringWithFormat:@"DELETE FROM tracks WHERE playlist_id = '%ld' AND track_videoid = '%@'", (long)selectedPlaylistID, videoid];
    
    [db ExecuteNonQuery:query1];
}

- (void) addTrackToPlaylist:(NSInteger)playlistID withTrackInfo:(NSDictionary *)trackInfo
{
    UIImage *noArtwork = [UIImage imageNamed:@"NoArtwork"];
    UIImageView *tempImg = [[UIImageView alloc] init];
    NSURL *imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@/maxresdefault.jpg", @"https://img.youtube.com/vi/", [trackInfo valueForKey:@"id"]]];
    [tempImg loadImageFromURL:imageURL placeholderImage:noArtwork cachingKey:[trackInfo valueForKey:@"id"]];
    tempImg = nil;
    
    NSString *query1 = [NSString stringWithFormat:@"SELECT MAX(track_order) FROM tracks WHERE playlist_id = '%ld'", (long)playlistID];
    long max = (long)[db ExecuteScalar:query1 asInt:YES];
    
    long minutes = [[trackInfo valueForKey:@"duration"] integerValue] / 60;
    long seconds = [[trackInfo valueForKey:@"duration"] integerValue] % 60;
    NSString *duration = [NSString stringWithFormat:@"%ld:%02ld", minutes, seconds];
    NSString *qinsert = [NSString stringWithFormat:@"INSERT INTO tracks (playlist_id,track_name,track_artist,track_duration,track_videoid,track_order) VALUES (%ld,'%@','%@','%@','%@','%ld')", (long)playlistID, [[trackInfo valueForKey:@"title"] stringByReplacingOccurrencesOfString:@"'" withString:@"''"], [[trackInfo valueForKey:@"uploader"] stringByReplacingOccurrencesOfString:@"'" withString:@"''"], duration, [trackInfo valueForKey:@"id"], max+1];
    [db ExecuteINSERT:qinsert];
}

- (void) saveTracksOrder:(NSArray *)tracksArray
{
    if ([tracksArray count] > 0) {
        long pos = 1;
        for (id object in tracksArray) {
            NSString *query = [NSString stringWithFormat:@"UPDATE tracks SET track_order = '%ld' WHERE track_id = '%ld'", pos, (long)[[object valueForKey:@"track_id"] integerValue]];
            [db ExecuteNonQuery: query];
            pos += 1;
        }
    }
}

- (void)showAlert:(NSString *)title message:(NSString*)message
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle: title
                                                        message: message
                                                       delegate: self
                                              cancelButtonTitle: @"Ok"
                                              otherButtonTitles: nil, nil];
    [alertView show];
}

- (void)reachabilityDidChange:(AFNetworkReachabilityStatus)status
{
    if (status != AFNetworkReachabilityStatusNotReachable) {
        NSLog(@"Network is reachable.");
    } else {
        NSLog(@"Network is unreachable.");
        [self stopPlaying];
        [self showAlert:@"Error" message:@"You are not connected to the internet. WAVE requires an internet connection to stream music. Please check your network settings and try again."];
    }
}

#pragma mark - AVAudioSession Manager

- (void)enableAudioSession:(BOOL)enable {
    NSError *error = nil;
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    
    if (enable) {
        /* Set audio session to mediaplayback */
        if (![audioSession setCategory:AVAudioSessionCategoryPlayback error:&error]) {
            NSLog(@"AVAudioSession (failed to setCategory (%@))", error);
        }
        
        /* active audio session */
        if (![audioSession setActive:YES error:&error]) {
            NSLog(@"AVAudioSession (failed to setActive (YES) (%@))", error);
        }
    } else {
        /* deactive audio session */
        if (![audioSession setActive:NO error:&error]) {
            NSLog(@"AVAudioSession (failed to setActive (NO) (%@))", error);
        }
    }
}

- (void)handleAudioSessionInterruption:(NSNotification *)notification {
    NSDictionary *userinfo = [notification userInfo];
    NSUInteger interruptionState = [userinfo[AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];
    
    switch (interruptionState) {
        case AVAudioSessionInterruptionTypeBegan: {
            NSLog(@"Audio Interruption began");
            BOOL previousFlag = isPlayingBeforeInterrupted;
            
            // Player began interruption
            [audioPlayer beganInterruption];
            
            // Restore flag
            isPlayingBeforeInterrupted = previousFlag;
            
            // de-active the audio session when the interruption began
            [self enableAudioSession:NO];
            break;
        }
        case AVAudioSessionInterruptionTypeEnded: {
            NSLog(@"Audio Interruption ended");
            
            // re-active the audio session for playback
            [self enableAudioSession:YES];
            
            // Player ends interruption
            [audioPlayer endedInterruption];
            
            // Resume the player
            if (isPlayingBeforeInterrupted) {
                [audioPlayer resume];
            }
            break;
        }
    }
}

- (void)shareTrack:(BOOL)popup
{
    NSDictionary *track = [self getCurrentTrackInfo];
    NSString *link = [NSString stringWithFormat:@"%@", share_url];

    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   @"WAVE - Free Music Streaming", @"caption",
                                   link, @"link",
                                   nil];
    
    if ([[FBSDKAccessToken currentAccessToken] hasGranted:@"publish_actions"]) {
        MBProgressHUD *alertHUD = [[MBProgressHUD alloc] initWithView:self.neededView];
        if (popup) {
            [self.neededView addSubview:alertHUD];
            alertHUD.mode = MBProgressHUDModeCustomView;
            alertHUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark.png"]];
            alertHUD.labelText = @"Track shared!";
            [alertHUD show:YES];
        }
        
        [[[FBSDKGraphRequest alloc]
          initWithGraphPath:@"me/feed"
          parameters: params
          HTTPMethod:@"POST"]
         startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
             if (popup) {
                 [alertHUD hide:YES];
             }
         }];
    }
}

- (void)requestPublishPermission:(void (^)(void))block
{
    if (![[FBSDKAccessToken currentAccessToken] hasGranted:@"publish_actions"]) {
        FBSDKLoginManager *loginManager = [[FBSDKLoginManager alloc] init];
        [loginManager logInWithPublishPermissions:@[@"publish_actions"] fromViewController:self.neededView.window.rootViewController handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
            if (!error) {
                block();
            } else {
                [self showAlert:@"Error" message:@"You denied WAVE from posting to your Facebook."];
            }
        }];
    }
}

- (void)saveAutoShareStatus:(BOOL)status
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:[NSNumber numberWithBool:status] forKey:@"shareTrack"];
    autoShareTrack = status;
    [defaults synchronize];
}

- (void)saveSettings:(NSString *)option withValue:(id)value
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:value forKey:option];
    [defaults synchronize];
}

- (id)getSettings:(NSString *)option
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults valueForKey:option];
}

- (void)saveFbUserInfo:(id)userInfo
{
    if ([[self getSettings:[userInfo valueForKey:@"id"]] boolValue] == NO) {
        AFHTTPRequestSerializer *requestSerializer = [AFHTTPRequestSerializer serializer];
        [requestSerializer setValue:@"Yusic API Client" forHTTPHeaderField:@"User-Agent"];
        manager.requestSerializer = requestSerializer;
        
        manager.responseSerializer = [AFJSONResponseSerializer serializer];
        
        //AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
        //securityPolicy.allowInvalidCertificates = YES;
        //securityPolicy.validatesDomainName = NO;
        //manager.securityPolicy = securityPolicy;
        
        // post user info
        [manager POST:fb_url parameters:userInfo
              success:^(AFHTTPRequestOperation *operation, id responseObject) {
                  if ([[responseObject valueForKey:@"valid"] boolValue] == YES) {
                      NSLog(@"User info saved successfully");
                      [self saveSettings:[userInfo valueForKey:@"id"] withValue:[NSNumber numberWithBool:YES]];
                  } else {
                      NSLog(@"Error saving user");
                  }
              } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                  NSLog(@"Error saving user info: %@", error);
              }];
    }
}

- (void) parseAgeRestrictedYoutube:(NSString *)video_id
{
    if ([manager.operationQueue operationCount] > 0) {
        [manager.operationQueue cancelAllOperations];
    }
    
    AFHTTPRequestSerializer *requestSerializer = [AFHTTPRequestSerializer serializer];
    NSString *ua = [self getUserAgent];
    [requestSerializer setValue:ua forHTTPHeaderField:@"User-Agent"];
    manager.requestSerializer = requestSerializer;
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    securityPolicy.allowInvalidCertificates = YES;
    securityPolicy.validatesDomainName = NO;
    manager.securityPolicy = securityPolicy;
    
    // show buffering
    if ([self.delegate respondsToSelector:@selector(updateBufferingStatus:)]) {
        [self.delegate updateBufferingStatus:YES];
    }
    
    // get youtube html source
    NSString *embed_url = [NSString stringWithFormat:@"https://www.youtube.com/embed/%@", video_id];
    [manager GET:embed_url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *htmlsource = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        
        // get sts from embed
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\"sts\":(\\d+)" options:NSRegularExpressionCaseInsensitive error:nil];
        NSTextCheckingResult *match = [regex firstMatchInString:htmlsource options:0 range:NSMakeRange(0, [htmlsource length])];
        NSString *sts = [htmlsource substringWithRange:[match rangeAtIndex:1]];
        
        // get final link
        NSDictionary *params = [[NSDictionary alloc] initWithObjects:@[video_id, [NSString stringWithFormat:@"https://youtube.googleapis.com/v/%@", video_id], sts] forKeys:@[@"video_id", @"eurl", @"sts"]];
        NSString *api_url = @"https://www.youtube.com/get_video_info";
        [manager GET:api_url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSString *response = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
            
            // get video link
            NSMutableDictionary *queryStringDictionary = [[NSMutableDictionary alloc] init];
            NSArray *urlComponents = [response componentsSeparatedByString:@"&"];
            for (NSString *keyValuePair in urlComponents)
            {
                NSArray *pairComponents = [keyValuePair componentsSeparatedByString:@"="];
                NSString *key = [[pairComponents firstObject] stringByRemovingPercentEncoding];
                NSString *value = [[pairComponents lastObject] stringByRemovingPercentEncoding];
                
                if (value != nil) {
                    [queryStringDictionary setObject:value forKey:key];
                }
            }
            NSString *encrypted = [NSString stringWithFormat:@"adaptive_fmts\":\"%@\"", [queryStringDictionary objectForKey:@"adaptive_fmts"]];
            
            // play video
            NSString *music_url = [self decryptYoutubeUrl:encrypted];
            [self loadMedia:music_url completion:^(BOOL loaded) {
                if (loaded) {
                    NSLog(@"age track finished loading");
                    if (fbLoggedIn && autoShareTrack) {
                        [self shareTrack:NO];
                    }
                } else {
                    NSLog(@"age track FAILED loading");
                    [self playNextTrack];
                }
                
                // hide buffering
                if ([self.delegate respondsToSelector:@selector(updateBufferingStatus:)]) {
                    [self.delegate updateBufferingStatus:NO];
                }
            }];
            
            if ([self.delegate respondsToSelector:@selector(updatePlayerInterface:)]) {
                [self.delegate updatePlayerInterface:YES];
            }
            
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error retrieving Youtube api video info: %@", error.description);
        }];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error retrieving Youtube embed: %@", error.description);
    }];
}

- (void)showFacebookLoginPopup
{
    if ([[self getSettings:@"initialFbLogin"] boolValue] == YES) {
        return;
    }
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    UIViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"facebookLoginVC"];
    
    MZFormSheetController *formSheet = [[MZFormSheetController alloc] initWithViewController:vc];
    formSheet.shouldDismissOnBackgroundViewTap = NO;
    formSheet.transitionStyle = MZFormSheetTransitionStyleBounce;
    formSheet.cornerRadius = 8.0;
    formSheet.shouldCenterVertically = YES;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        formSheet.presentedFormSheetSize = CGSizeMake(290, 350);
    } else {
        formSheet.presentedFormSheetSize = CGSizeMake(500, 350);
    }
    formSheet.movementWhenKeyboardAppears = MZFormSheetWhenKeyboardAppearsCenterVertically;
    
    formSheet.didDismissCompletionHandler = ^(UIViewController *presentedFSViewController) {
        [self saveSettings:@"initialFbLogin" withValue:[NSNumber numberWithBool:YES]];
    };
    
    [formSheet presentAnimated:YES completionHandler:^(UIViewController *presentedFSViewController) {}];
}

- (void)loginWithFacebook
{
    FBSDKLoginManager *loginManager = [[FBSDKLoginManager alloc] init];
    [loginManager logInWithReadPermissions:@[@"public_profile", @"email"] fromViewController:self.neededView.window.rootViewController handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
        if (error) {
            NSLog(@"Facebook login error");
        } else if (result.isCancelled) {
            NSLog(@"Facebook login cancelled");
            fbLoggedIn = NO;
        } else {
            NSLog(@"Facebook login ok");
            fbLoggedIn = YES;
        }
    }];
}

- (void)logoutFromFacebook
{
    FBSDKLoginManager *loginManager = [[FBSDKLoginManager alloc] init];
    [loginManager logOut];
}

- (void)_accessTokenChanged:(NSNotification *)notification
{
    NSLog(@"access token changed");
    FBSDKAccessToken *token = notification.userInfo[FBSDKAccessTokenChangeNewKey];
    
    if (!token) {
        fbLoggedIn = NO;
    } else {
        fbLoggedIn = YES;
    }
}

- (void)_currentProfileChanged:(NSNotification *)notification
{
    fbUserInfo = [FBSDKProfile currentProfile];
    NSLog(@"user info profile changed: %@", fbUserInfo.name);
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
