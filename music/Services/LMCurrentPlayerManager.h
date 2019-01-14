//
//  LMCurrentPlayerManager.h
//  music
//
//  Created by Leptos on 12/1/18.
//  Copyright © 2018 Leptos. All rights reserved.
//

@import Foundation;
@import AVFoundation;
@import MediaPlayer;

typedef void(^LMCurrentPlayerManagerAudioRenderCallback)(AudioBufferList *bufferListInOut);
typedef void(^LMCurrentPlayerManagerMetadataChangeCallback)(const AudioStreamBasicDescription *processingFormat);

#import "../Models/LMVideoItemModule.h"

@interface LMCurrentPlayerManager : NSObject
/// Do not attempt to create another instance of this class.
@property (class, strong, nonatomic, readonly) LMCurrentPlayerManager *sharedManager;
/// The current playlist. Setting a new playlist will immediately start requests, and will subsequently start playing the new content
@property (strong, nonatomic) YTIWatchPlaylistEndpoint *playlist;
/// This player does not change, only the currentItem does.
@property (strong, nonatomic, readonly) AVPlayer *player;
/// The playing index you'd like to be playing- does not reflect the actual current playing index.
@property (nonatomic, readonly) NSUInteger targetPlayingIndex;
/// The item module currently being used. The playerItem will be the player's currentItem
@property (strong, nonatomic, readonly) LMVideoItemModule *currentModule;
/// Called every time an audio frame is rendered by the currentModule.playerItem
- (void)addAudioRenderCallback:(LMCurrentPlayerManagerAudioRenderCallback)callback;
/// Called when metadata of the player changes
- (void)addMetadataChangeCallback:(LMCurrentPlayerManagerMetadataChangeCallback)callback;

/// Updates Now Playing Info Center with info from player and currentModule
- (void)updateSystemCurrentPlayingInfo;

/// Begin playing if possible
- (void)play;
/// Pause player
- (void)pause;
/// Play if currently paused, otherwise pause
- (void)togglePlayPause;
/// Start playing next item in playlist
- (void)next;
/// Start playing previous item in playlist
- (void)previous;
/// Start playing at position, where 0 is the beginning and 1 is the end, values should be in the range of [0, 1).
- (void)scrubToPosition:(float)position;
/// Start playing at timestamp, where 0 is the beginning and 60 is 1 minute in, and 120 is 2 minutes in.
- (void)scrubToTimestamp:(NSTimeInterval)timestamp;

@end
