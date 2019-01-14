//
//  LMVideoItemModule.m
//  music
//
//  Created by Leptos on 12/4/18.
//  Copyright © 2018 Leptos. All rights reserved.
//

#import "LMVideoItemModule.h"
#import "../Services/LMProtobufFactory.h"
#import "../Services/LMCurrentPlayerManager.h"
#import "../Services/LMPreferencesManager.h"

@implementation LMVideoItemModule {
    NSDictionary *_cachedMetadataHead;
    MPMediaItemArtwork *_mediaArtwork;
}

- (instancetype)initWithWatchpoint:(YTIWatchEndpoint *)watchpoint {
    if (self = [self init]) {
        _watchEndpoint = watchpoint;
    }
    return self;
}

- (void)requestPlayerResponse:(void (^)(YTIPlayerResponse *, NSError *))responseHandler {
    YTIPlayerRequest *playerReq = [YTIPlayerRequest message];
    playerReq.context.client = [LMProtobufFactory currentClientInfo];
    
    playerReq.videoId = self.watchEndpoint.videoId;
    playerReq.playlistId = self.watchEndpoint.playlistId;
    playerReq.params = self.watchEndpoint.playerParams;
    playerReq.playlistIndex = self.watchEndpoint.index;
    
    playerReq.racyCheckOk = NO;
    playerReq.forOffline = NO;
    playerReq.playbackContext.contentPlaybackContext.timeSinceLastAdSeconds = 0;
    playerReq.playbackContext.contentPlaybackContext.autoplaysSinceLastAd = 0;
    playerReq.playbackContext.contentPlaybackContext.conn = 3; // conn = connection, 3 = wifi
    playerReq.playbackContext.contentPlaybackContext.vis = 0;
    
    LMInnerTubeRequest *request = [LMInnerTubeRequest new];
    request.URL = [LMInnerTubeURLBuilder defaultURLForScope:@"player"];
    request.responseClass = [YTIPlayerResponse class];
    request.message = playerReq;
    
    __weak __typeof(self) weakself = self;
    [request completeRequestWithCompletion:^(YTIPlayerResponse *message, NSError *error) {
        [weakself _immediatePlayerResponseProcess:message];
        if (responseHandler) {
            responseHandler(message, error);
        }
    }];
}

- (AVPlayerItem *)playerItem {
    return (LMPreferencesManager.sharedManager.visualType != LMPreferencesVisualizerTypeVideo) ? self.dshPlayerItem : self.hlsPlayerItem;
}

- (void)_immediatePlayerResponseProcess:(YTIPlayerResponse *)playerResponse {
    _playerResponse = playerResponse;
    
    YTIVideoDetails *vidInfo = playerResponse.videoDetails;
    
    YTIStreamingData *streamingData = playerResponse.streamingData;
    YTIFormatStream *stream = streamingData.adaptiveFormatsArray.lastObject;
    
    _approximateDuration = stream.approxDurationMs/1000.0;
    _assetExpiry = [NSDate dateWithTimeIntervalSinceNow:streamingData.expiresInSeconds];
    
    NSDictionary *const urlAssetPrecision = @{
        AVURLAssetPreferPreciseDurationAndTimingKey : @(YES)
    };
    
    AVURLAsset *hlsAsset = [AVURLAsset URLAssetWithURL:[NSURL URLWithString:streamingData.hlsManifestURL] options:urlAssetPrecision];
    AVURLAsset *dshAsset = [AVURLAsset URLAssetWithURL:[NSURL URLWithString:stream.URL] options:urlAssetPrecision];
    
    _hlsPlayerItem = [AVPlayerItem playerItemWithAsset:hlsAsset];
    _dshPlayerItem = [AVPlayerItem playerItemWithAsset:dshAsset];
        
    YTIThumbnailDetails_Thumbnail *thumbnailHandle = vidInfo.thumbnail.thumbnailsArray.lastObject;
    NSURL *thumbnailURL = [NSURL URLWithString:thumbnailHandle.URL];
    
    CGSize thumbnailSize = CGSizeMake(thumbnailHandle.width, thumbnailHandle.height);
    
    __weak typeof(self) weakself = self;
    [[NSURLSession.sharedSession dataTaskWithURL:thumbnailURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        UIImage *thumbnailArt = [UIImage imageWithData:data];
        if (thumbnailArt && weakself) {
            typeof(self) strongself = weakself;
            MPMediaItemArtwork *mediaItemArtwork;
            if (@available(iOS 10.0, *)) {
                mediaItemArtwork = [[MPMediaItemArtwork alloc] initWithBoundsSize:thumbnailSize requestHandler:^UIImage *(CGSize size) {
                    CGRect drawRect = CGRectZero;
                    drawRect.size = size;
                    
                    UIGraphicsBeginImageContext(size);
                    [thumbnailArt drawInRect:drawRect];
                    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
                    UIGraphicsEndImageContext();
                    
                    return image;
                }];
            } else {
                mediaItemArtwork = [[MPMediaItemArtwork alloc] initWithImage:thumbnailArt];
            }
            strongself->_mediaArtwork = mediaItemArtwork;
            if (weakself.watchEndpoint.index == LMCurrentPlayerManager.sharedManager.targetPlayingIndex) {
                [LMCurrentPlayerManager.sharedManager updateSystemCurrentPlayingInfo];
            }
        }
    }] resume];
    
    NSString *authorPatch = vidInfo.author;
    NSString *badAuthorSuffix = @" - Topic"; // not sure why this is here
    if ([authorPatch hasSuffix:badAuthorSuffix]) {
        authorPatch = [authorPatch substringToIndex:authorPatch.length - badAuthorSuffix.length];
    }
    NSMutableDictionary<NSString *, id> *nowPlayingInfo = [NSMutableDictionary dictionary];
    
    if (@available(iOS 11.0, *)) {
        nowPlayingInfo[MPNowPlayingInfoPropertyServiceIdentifier] = vidInfo.channelId;
    }
    if (@available(iOS 10.0, *)) {
        nowPlayingInfo[MPNowPlayingInfoPropertyMediaType] = @(MPNowPlayingInfoMediaTypeAudio);
        nowPlayingInfo[MPNowPlayingInfoPropertyIsLiveStream] = @(NO);
        nowPlayingInfo[MPNowPlayingInfoPropertyExternalContentIdentifier] = vidInfo.videoId;
    }
    if (@available(iOS 9.3, *)) {
        nowPlayingInfo[MPNowPlayingInfoCollectionIdentifier] = self.watchEndpoint.playlistId;
    }
    if (self.watchEndpoint.hasIndex) {
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackQueueIndex] = @(self.watchEndpoint.index);
    }
    
    nowPlayingInfo[MPMediaItemPropertyMediaType] = @(MPMediaTypeMusic);
    nowPlayingInfo[MPMediaItemPropertyTitle] = vidInfo.title;
    nowPlayingInfo[MPMediaItemPropertyArtist] = authorPatch;
    nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = @(self.approximateDuration);
    nowPlayingInfo[MPMediaItemPropertyComments] = vidInfo.shortDescription;
    
    _cachedMetadataHead = [nowPlayingInfo copy];
}

- (NSDictionary<NSString *, id> *)playerMetadata {
    NSMutableDictionary *playingInfo = [_cachedMetadataHead mutableCopy];
    
    playingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = @(CMTimeGetSeconds(self.playerItem.currentTime));
    playingInfo[MPMediaItemPropertyArtwork] = _mediaArtwork;
    if (@available(iOS 10.3, *)) {
        AVURLAsset *urlAsset = (AVURLAsset *)self.playerItem.asset;
        if ([urlAsset isKindOfClass:[AVURLAsset class]]) {
            playingInfo[MPNowPlayingInfoPropertyAssetURL] = urlAsset.URL;
        }
    }
    if (@available(iOS 11.1, *)) {
        playingInfo[MPNowPlayingInfoPropertyCurrentPlaybackDate] = self.playerItem.currentDate;
    }
    
    return [playingInfo copy];
}

- (BOOL)isValid {
    /* in the case of a zero chain, 0 is not greater than 0 */
    return (self.assetExpiry.timeIntervalSinceNow > 0) && self.playerItem;
}

- (void)setLikeStatus:(LMVideoLikedStatus)likeStatus {
    if (likeStatus != self.likeStatus) {
        _likeStatus = likeStatus;
        switch (likeStatus) {
            case LMVideoLikedStatusNone:
                [self _rmLike];
                break;
                
            case LMVideoLikedStatusUp:
                [self _like];
                break;
                
            case LMVideoLikedStatusDown:
                [self _dislike];
                break;
                
            default:
                break;
        }
    }
}

// MARK: Internal changing like status

- (void)_like {
    YTILikeRequest *likeReq = [YTILikeRequest message];
    likeReq.context.client = [LMProtobufFactory currentClientInfo];
    likeReq.target.videoId = self.watchEndpoint.videoId;
    
    LMInnerTubeRequest *request = [LMInnerTubeRequest new];
    request.URL = [LMInnerTubeURLBuilder defaultURLForScope:@"like/like"];
    request.responseClass = [YTILikeResponse class];
    request.message = likeReq;
    
    [request completeRequestWithCompletion:^(YTILikeResponse *message, NSError *error) {
        if (error) {
            NSLog(@"completeRequestCompletedWithError: %@", error);
        }
    }];
}

- (void)_rmLike {
    YTIRemoveLikeRequest *rmLikeReq = [YTIRemoveLikeRequest message];
    rmLikeReq.context.client = [LMProtobufFactory currentClientInfo];
    rmLikeReq.target.videoId = self.watchEndpoint.videoId;
    
    LMInnerTubeRequest *request = [LMInnerTubeRequest new];
    request.URL = [LMInnerTubeURLBuilder defaultURLForScope:@"like/removelike"];
    request.responseClass = [YTILikeResponse class];
    request.message = rmLikeReq;
    
    [request completeRequestWithCompletion:^(YTILikeResponse *message, NSError *error) {
        if (error) {
            NSLog(@"completeRequestCompletedWithError: %@", error);
        }
    }];
}

- (void)_dislike {
    YTIDislikeRequest *disLikeReq = [YTIDislikeRequest message];
    disLikeReq.context.client = [LMProtobufFactory currentClientInfo];
    disLikeReq.target.videoId = self.watchEndpoint.videoId;
    
    LMInnerTubeRequest *request = [LMInnerTubeRequest new];
    request.URL = [LMInnerTubeURLBuilder defaultURLForScope:@"like/dislike"];
    request.responseClass = [YTILikeResponse class];
    request.message = disLikeReq;
    
    [request completeRequestWithCompletion:^(YTILikeResponse *message, NSError *error) {
        if (error) {
            NSLog(@"completeRequestCompletedWithError: %@", error);
        }
    }];
}

@end
