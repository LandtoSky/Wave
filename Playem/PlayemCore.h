//
//  PlayemCore.h
//  Playem
//
//  Created by Dragos Panoiu on 04/03/14.
//  Copyright (c) 2014 Dragos Panoiu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import "DBController.h"
#import "AFHTTPRequestOperationManager.h"
#import <AVPlayerTouch/FFAVPlayerController.h>
#import "MZFormSheetController.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>

@protocol PlayemCoreDelegate;

@interface PlayemCore : NSObject <FFAVPlayerControllerDelegate, AVAudioSessionDelegate, UIWebViewDelegate> {
    NSMutableDictionary *currentTrackInfo;
    NSMutableArray *playlists;
    NSMutableArray *tracks;
    
    DBController *db;
    DataTable *playlistItems;
    DataTable *trackItems;
    BOOL isPlayingBeforeInterrupted;
}

@property (nonatomic, weak) id<PlayemCoreDelegate> delegate;

// audio player
@property (nonatomic, retain) FFAVPlayerController *audioPlayer;

// web components
@property (nonatomic, retain) UIWebView *webView;
@property (nonatomic, retain) AFHTTPRequestOperationManager *manager;

// playing playlist/track
@property (nonatomic, assign) NSInteger selectedPlaylistID;
@property (nonatomic, assign) NSInteger selectedPlaylistRow;
@property (nonatomic, assign) NSInteger playingPlaylist;
@property (nonatomic, assign) NSInteger playingTrack;

// repeat & shuffle
@property (nonatomic, assign) BOOL repeat;
@property (nonatomic, assign) BOOL shuffle;

@property (nonatomic, assign) BOOL fbLoggedIn;
@property (nonatomic, retain) FBSDKProfile *fbUserInfo;
@property (nonatomic, assign) BOOL autoShareTrack;

@property (nonatomic, weak) UIView *neededView;
@property (nonatomic, retain) NSString *youtubeKey;


+ (id)sharedInstance;

- (void) loadParser;
- (NSArray *) loadPlaylists;
- (NSArray *) loadTracksFromPlaylist:(NSInteger)playlistID;
- (void) selectPlaylist:(NSInteger)playlistID withPlaylistRow:(NSInteger)playlistRow;
- (NSDictionary *) getCurrentPlaylistInfo;
- (NSDictionary *) getCurrentTrackInfo;
- (void) playTrack:(NSInteger)trackNo;
- (void) stopPlaying;
- (void) startPlaying;
- (void) playNextTrack;
- (void) playNext;
- (void) playPrevTrack;
- (void) playPrev;
- (void) deleteTrack:(NSInteger)trackNo;
- (void) deletePlaylist:(NSInteger)playlistID;
- (void) createPlaylist:(NSString *)name;
- (void) editPlaylist:(NSString *)name playlistID:(NSInteger)playlistID;
- (BOOL) checkIfTrackInCurrentPlaylist:(NSString *)YoutubeID;
- (void) addTrackToCurrentPlaylist:(NSDictionary *)trackInfo;
- (void) deleteTrackFromCurrentPlaylist:(NSDictionary *)trackInfo;
- (void) addTrackToPlaylist:(NSInteger)playlistID withTrackInfo:(NSDictionary *)trackInfo;
- (void) saveTracksOrder:(NSArray *)tracksArray;
- (void) copyPlaylist:(NSDictionary *)playlistInfo;
- (BOOL) isPlaying;
- (BOOL) isPaused;
- (void)showAlert:(NSString *)title message:(NSString*)message;
- (void)shareTrack:(BOOL)popup;
- (void)requestPublishPermission:(void(^)(void))block;
- (void)saveAutoShareStatus:(BOOL)status;
- (void)saveSettings:(NSString *)option withValue:(id)value;
- (id)getSettings:(NSString *)option;
- (void)saveFbUserInfo:(id)userInfo;
- (void)showFacebookLoginPopup;
- (void)loginWithFacebook;
- (void)logoutFromFacebook;

@end

@protocol PlayemCoreDelegate <NSObject>

@optional
- (void) updatePlaybackProgress:(NSInteger)duration withProgress:(NSInteger)progress;
- (void) updatePlayerInterface:(BOOL)status;
- (void) updateBufferingStatus:(BOOL)status;

@end
