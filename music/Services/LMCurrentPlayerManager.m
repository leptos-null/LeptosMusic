//
//  LMCurrentPlayerManager.m
//  music
//
//  Created by Leptos on 12/1/18.
//  Copyright © 2018 Leptos. All rights reserved.
//

#import "LMCurrentPlayerManager.h"
#import "LMProtobufFactory.h"
#import "LMPreferencesManager.h"

@implementation LMCurrentPlayerManager {
    NSArray<YTIWatchEndpoint *> *_playlistEndpoints;
    LMVideoItemModule *_preemptiveFetch;
    float _playbackRate;
    
    NSMutableArray<LMCurrentPlayerManagerAudioRenderCallback> *_audioRenderCallbacks;
    NSMutableArray<LMCurrentPlayerManagerMetadataChangeCallback> *_metadataChangeCallbacks;
    
    id _playerEndObserverToken;
    id _playerStartObserverToken;
}

/// @c MTAudioProcessingTapInitCallback
static void _initAudioProcessing(MTAudioProcessingTapRef tap, void *clientInfo, void **tapStorageOut) {
    *tapStorageOut = clientInfo; // "self"
}
/// @c MTAudioProcessingTapFinalizeCallback
static void _finalizeAudioProcessing(MTAudioProcessingTapRef tap) {
    // NSLog(@"Finalizing the Audio Tap Processor");
}
/// @c MTAudioProcessingTapPrepareCallback
static void _prepareAudioProcessing(MTAudioProcessingTapRef tap, CMItemCount maxFrames, const AudioStreamBasicDescription *processingFormat) {
    LMCurrentPlayerManager *self = (__bridge LMCurrentPlayerManager *)MTAudioProcessingTapGetStorage(tap);
    for (LMCurrentPlayerManagerMetadataChangeCallback callback in self->_metadataChangeCallbacks) {
        callback(processingFormat);
    }
}
/// @c MTAudioProcessingTapUnprepareCallback
static void _unprepareAudioProcessing(MTAudioProcessingTapRef tap) {
    // NSLog(@"Unpreparing the Audio Tap Processor");
}
/// @c MTAudioProcessingTapProcessCallback
static void _processAudioProcessing(MTAudioProcessingTapRef tap, CMItemCount numberFrames, MTAudioProcessingTapFlags flags,
                                    AudioBufferList *bufferListInOut, CMItemCount *numberFramesOut, MTAudioProcessingTapFlags *flagsOut) {
    OSStatus err = MTAudioProcessingTapGetSourceAudio(tap, numberFrames, bufferListInOut, flagsOut, NULL, numberFramesOut);
    if (err) {
        NSLog(@"MTAudioProcessingTapGetSourceAudio exited with a non-zero status");
        return;
    }
    
    LMCurrentPlayerManager *self = (__bridge LMCurrentPlayerManager *)MTAudioProcessingTapGetStorage(tap);
    for (LMCurrentPlayerManagerAudioRenderCallback callback in self->_audioRenderCallbacks) {
        callback(bufferListInOut);
    }
}

+ (instancetype)sharedManager {
    static LMCurrentPlayerManager *ret;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ret = [self new];
    });
    return ret;
}

- (instancetype)init {
    if (self = [super init]) {
        _playbackRate = 1;
        _player = [AVPlayer playerWithPlayerItem:nil];
        _audioRenderCallbacks = [NSMutableArray array];
        _metadataChangeCallbacks =  [NSMutableArray array];
        
        __weak typeof(self) weakself = self;
        MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];
        
        [commandCenter.playCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent *event) {
            [weakself play];
            return MPRemoteCommandHandlerStatusSuccess;
        }];
        [commandCenter.pauseCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent *event) {
            [weakself pause];
            return MPRemoteCommandHandlerStatusSuccess;
        }];
        [commandCenter.togglePlayPauseCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent *event) {
            [weakself togglePlayPause];
            return MPRemoteCommandHandlerStatusSuccess;
        }];
        [commandCenter.nextTrackCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent *event) {
            [weakself next];
            return MPRemoteCommandHandlerStatusSuccess;
        }];
        [commandCenter.previousTrackCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent *event) {
            [weakself previous];
            return MPRemoteCommandHandlerStatusSuccess;
        }];
#if 0
        [commandCenter.skipForwardCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent *event) {
            if ([event isKindOfClass:[MPSkipIntervalCommandEvent class]]) {
                MPSkipIntervalCommandEvent *castedEvent = (MPSkipIntervalCommandEvent *)event;
                CMTime time = weakself.player.currentTime;
                time.value += (castedEvent.interval * time.timescale);
                if (CMTimeGetSeconds(time) > weakself.currentModule.approximateDuration) {
                    weakself.targetPlayingIndex++;
                    [weakself updateSystemCurrentPlayingInfo];
                    return MPRemoteCommandHandlerStatusSuccess;
                }
                [weakself.player seekToTime:time completionHandler:^(BOOL finished) {
                    if (finished) {
                        [weakself updateSystemCurrentPlayingInfo];
                    }
                }];
                return MPRemoteCommandHandlerStatusSuccess;
            }
            return MPRemoteCommandHandlerStatusNoSuchContent;
        }];
        [commandCenter.skipBackwardCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent *event) {
            if ([event isKindOfClass:[MPSkipIntervalCommandEvent class]]) {
                MPSkipIntervalCommandEvent *castedEvent = (MPSkipIntervalCommandEvent *)event;
                CMTime time = weakself.player.currentTime;
                time.value -= (castedEvent.interval * time.timescale);
                if (time.value < 0) {
                    time.value = 0;
                }
                [weakself.player seekToTime:time completionHandler:^(BOOL finished) {
                    if (finished) {
                        [weakself updateSystemCurrentPlayingInfo];
                    }
                }];
                return MPRemoteCommandHandlerStatusSuccess;
            }
            return MPRemoteCommandHandlerStatusNoSuchContent;
        }];
#endif
        if (@available(iOS 9.1, *)) {
            [commandCenter.changePlaybackPositionCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent *event) {
                if ([event isKindOfClass:[MPChangePlaybackPositionCommandEvent class]]) {
                    MPChangePlaybackPositionCommandEvent *castedEvent = (MPChangePlaybackPositionCommandEvent *)event;
                    [weakself scrubToTimestamp:castedEvent.positionTime];
                    return MPRemoteCommandHandlerStatusSuccess;
                }
                return MPRemoteCommandHandlerStatusNoSuchContent;
            }];
        }
#if 0
        commandCenter.likeCommand.localizedTitle = @"Like song";
        [commandCenter.likeCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent *event) {
            weakself.currentModule.likeStatus = LMVideoLikedStatusUp;
            return MPRemoteCommandHandlerStatusSuccess;
        }];
        commandCenter.dislikeCommand.localizedTitle = @"Dislike song";
        [commandCenter.dislikeCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent *event) {
            weakself.currentModule.likeStatus = LMVideoLikedStatusDown;
            [weakself next];
            return MPRemoteCommandHandlerStatusSuccess;
        }];
#endif
        _playerStartObserverToken = [self.player addBoundaryTimeObserverForTimes:@[
            [NSValue valueWithCMTime:CMTimeMake(1, 1 << 6)] /* value can't go lower than 1, so increase timescale for times approaching zero */
        ] queue:nil usingBlock:^{
            [weakself updateSystemCurrentPlayingInfo];
        }];
        
        NSNotificationCenter *notifCenter = NSNotificationCenter.defaultCenter;
        [notifCenter addObserverForName:AVPlayerItemDidPlayToEndTimeNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
            if (note.object == weakself.currentModule.playerItem) {
                [weakself next];
            }
        }];
        [notifCenter addObserver:self selector:@selector(updateForPreferenceChange) name:LMVisualTypePreferenceDidChangeNotification object:nil];
        
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        [audioSession setCategory:AVAudioSessionCategoryPlayback error:NULL];
        [audioSession setActive:YES error:NULL];
        [UIApplication.sharedApplication beginReceivingRemoteControlEvents];
    }
    return self;
}

- (void)addAudioRenderCallback:(LMCurrentPlayerManagerAudioRenderCallback)callback {
    [_audioRenderCallbacks addObject:callback];
}
- (void)addMetadataChangeCallback:(LMCurrentPlayerManagerMetadataChangeCallback)callback {
    [_metadataChangeCallbacks addObject:callback];
}

- (void)updateForPreferenceChange {
    AVPlayerItem *playingItem = self.player.currentItem;
    [self.player replaceCurrentItemWithPlayerItem:self.currentModule.playerItem];
    
    __weak typeof(self) weakself = self;
    [self.player seekToTime:playingItem.currentTime completionHandler:^(BOOL finished) {
        if (finished) {
            [weakself updateSystemCurrentPlayingInfo];
        }
    }];
}

- (void)play {
    self.player.rate = _playbackRate;
    [self updateSystemCurrentPlayingInfo];
}
- (void)pause {
    _playbackRate = self.player.rate;
    [self.player pause];
    [self updateSystemCurrentPlayingInfo];
}
- (void)togglePlayPause {
    if (fabs(self.player.rate) < DBL_EPSILON) {
        [self play];
    } else {
        [self pause];
    }
}
- (void)next {
    self.targetPlayingIndex++;
}
- (void)previous {
    if (self.targetPlayingIndex) {
        self.targetPlayingIndex--;
    }
}
- (void)scrubToPosition:(float)position {
    [self scrubToTimestamp:self.currentModule.approximateDuration * position];
}
- (void)scrubToTimestamp:(NSTimeInterval)timestamp {
    __weak typeof(self) weakself = self;
    [self.player seekToTime:CMTimeMakeWithSeconds(timestamp, (1 << 7)) completionHandler:^(BOOL finished) {
        if (finished) {
            [weakself updateSystemCurrentPlayingInfo];
        }
    }];
}

- (void)startFetchForCurrentItem {
    if (_playlistEndpoints.count) {
        LMVideoItemModule *nextVideoModule = _preemptiveFetch;
        if (nextVideoModule.valid && (nextVideoModule.watchEndpoint.index == self.targetPlayingIndex)) {
            __weak typeof(self) weakself = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                weakself.currentModule = nextVideoModule;
            });
        } else {
            [self _sendPlayerRequestForEndpoint:_playlistEndpoints[self.targetPlayingIndex]];
        }
        NSInteger nextIndex = self.targetPlayingIndex+1;
        if (nextIndex < _playlistEndpoints.count) {
            [self _sendPlayerRequestForEndpoint:_playlistEndpoints[nextIndex]];
        }
    }
}

- (void)setPlaylist:(YTIWatchPlaylistEndpoint *)playlist {
    if (playlist) {
        _playlist = playlist;
        _playlistEndpoints = nil;
        _preemptiveFetch = nil;
        
        self.targetPlayingIndex = 0;
    }
}

- (void)setTargetPlayingIndex:(NSUInteger)targetPlayingIndex {
    /* minus one for pre-fetch */
    if (targetPlayingIndex < _playlistEndpoints.count-1) {
        _targetPlayingIndex = targetPlayingIndex;
        
        [self startFetchForCurrentItem];
        if (_playlistEndpoints.count - targetPlayingIndex < 5) {
            YTIWatchPlaylistEndpoint *playlistExtend = [self.playlist copy];
            playlistExtend.index = (uint32_t)_playlistEndpoints.count; // there might be a bug in the protobuf backing of this
            [self _sendWatchRequestWithPlaylist:playlistExtend];
        }
    }
    MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];
    commandCenter.previousTrackCommand.enabled = targetPlayingIndex;
}

// TODO: Change "playlist" to "endpoint" to be more inclusive, and support videoIds
- (void)_sendWatchRequestWithPlaylist:(YTIWatchPlaylistEndpoint *)endpoint {
    YTIWatchNextRequest *nextReq = [YTIWatchNextRequest message];
    
    nextReq.context.client = [LMProtobufFactory currentClientInfo];
    nextReq.playlistId = endpoint.playlistId;
    nextReq.params = endpoint.params;
    nextReq.playlistIndex = endpoint.index;
    // nextReq.videoId = endpoint.videoId;
    
    nextReq.racyCheckOk = NO;
    nextReq.contentCheckOk = NO;
    nextReq.autonavState = 0;
    nextReq.enablePersistentPlaylistPanel = YES;
    nextReq.playbackContext.lactMilliseconds = -1;
    
    LMInnerTubeRequest *request = [LMInnerTubeRequest new];
    request.URL = [LMInnerTubeURLBuilder defaultURLForScope:@"next"];
    request.responseClass = [YTIWatchNextResponse class];
    request.message = nextReq;
    
    __weak typeof(self) weakself = self;
    [request completeRequestWithCompletion:^(YTIWatchNextResponse *message, NSError *error) {
        if (error) {
            NSLog(@"error: %@", error);
        } else if (message) {
            YTIPlaylistPanelRenderer *playlist = message.contents.singleColumnMusicWatchNextResultsRenderer.playlist.playlistPanelRenderer;
            [weakself _preprocessInnerPlaylist:playlist];
        }
    }];
}

- (void)_preprocessInnerPlaylist:(YTIPlaylistPanelRenderer *)innerPlaylist {
    NSMutableArray<YTIWatchEndpoint *> *endpoints = _playlistEndpoints ? [_playlistEndpoints mutableCopy] : [NSMutableArray array];
    NSUInteger const indexOffset = _playlistEndpoints.count; // potentially a hangover from an above bug
    for (YTIPlaylistPanelRenderer_PlaylistPanelVideoSupportedRenderers *vidRends in innerPlaylist.contentsArray) {
        YTIWatchEndpoint *watchEndpoint = vidRends.playlistPanelVideoRenderer.navigationEndpoint.watchEndpoint;
        if (watchEndpoint.hasIndex) {
            endpoints[watchEndpoint.index + indexOffset] = watchEndpoint;
        }
    }
    _playlistEndpoints = [endpoints copy];
    [self startFetchForCurrentItem];
}

- (void)updateSystemCurrentPlayingInfo {
    NSMutableDictionary<NSString *, id> *playingInfo = [self.currentModule.playerMetadata mutableCopy];
    playingInfo[MPNowPlayingInfoPropertyPlaybackRate] = @(self.player.rate);
    MPNowPlayingInfoCenter.defaultCenter.nowPlayingInfo = playingInfo;
}

- (void)setCurrentModule:(LMVideoItemModule *)currentModule {
    _currentModule = currentModule;
    
    // https://chritto.wordpress.com/2013/01/07/processing-avplayers-audio-with-mtaudioprocessingtap/
    NSMutableArray *inputParamees = [NSMutableArray array];
    for (AVAssetTrack *assetTrack in [currentModule.dshPlayerItem.asset tracksWithMediaType:AVMediaTypeAudio]) {
        MTAudioProcessingTapCallbacks callbacks;
        callbacks.version = kMTAudioProcessingTapCallbacksVersion_0;
        callbacks.clientInfo = (__bridge void *)self;
        callbacks.init      = _initAudioProcessing;
        callbacks.finalize  = _finalizeAudioProcessing;
        callbacks.prepare   = _prepareAudioProcessing;
        callbacks.unprepare = _unprepareAudioProcessing;
        callbacks.process   = _processAudioProcessing;
        
        MTAudioProcessingTapRef tap;
        MTAudioProcessingTapCreate(kCFAllocatorDefault, &callbacks, kMTAudioProcessingTapCreationFlag_PostEffects, &tap);
        
        AVMutableAudioMixInputParameters *inputParams = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:assetTrack];
        inputParams.audioTapProcessor = tap;
        [inputParamees addObject:inputParams];
    }
    AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
    audioMix.inputParameters = inputParamees;
    currentModule.dshPlayerItem.audioMix = audioMix;
    
    [self.player replaceCurrentItemWithPlayerItem:currentModule.playerItem];
    [self play];
    
    if (_playerEndObserverToken) {
        [self.player removeTimeObserver:_playerEndObserverToken];
    }
    /* hack to work around https://openradar.appspot.com/46510748 */
#if 1 /* Discussions are open as to which method is more correct/appropriate */
    CMTime trackEndTime = CMTimeMakeWithSeconds(currentModule.approximateDuration, (1 << 7));
#else
    CMTime trackEndTime = currentModule.hlsPlayerItem.asset.duration;
#endif
    _playerEndObserverToken = [self.player addBoundaryTimeObserverForTimes:@[
        [NSValue valueWithCMTime:trackEndTime]
    ] queue:nil usingBlock:^{
        [NSNotificationCenter.defaultCenter postNotificationName:AVPlayerItemDidPlayToEndTimeNotification object:currentModule.dshPlayerItem];
    }];
}

- (void)_sendPlayerRequestForEndpoint:(YTIWatchEndpoint *)watchEndpoint {
    LMVideoItemModule *module = [[LMVideoItemModule alloc] initWithWatchpoint:watchEndpoint];
    __weak typeof(self) weakself = self;
    [module requestPlayerResponse:^(YTIPlayerResponse *response, NSError *error) {
        if (error) {
            NSLog(@"requestPlayerResponseError: %@", error);
        } else {
            if (module.watchEndpoint.index == weakself.targetPlayingIndex) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    weakself.currentModule = module;
                });
            } else if (module.watchEndpoint.index == weakself.targetPlayingIndex+1) {
                if (weakself) {
                    typeof(self) strongself = weakself;
                    strongself->_preemptiveFetch = module;
                }
            }
        }
    }];
}

@end
