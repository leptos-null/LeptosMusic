//
//  LMVideoItemModule.h
//  music
//
//  Created by Leptos on 12/4/18.
//  Copyright © 2018 Leptos. All rights reserved.
//

@import AVFoundation;
@import MediaPlayer;

#import "LMInnerTubeRequest.h"

typedef NS_ENUM(NSInteger, LMVideoLikedStatus) {
    /// No thumb
    LMVideoLikedStatusNone,
    /// Thumb up
    LMVideoLikedStatusUp,
    /// Thumb down
    LMVideoLikedStatusDown,
};

@interface LMVideoItemModule : NSObject
/// Player backed by an HLS source (audio and video)
@property (strong, nonatomic, readonly) AVPlayerItem *hlsPlayerItem;
/// Player backed by an MPEG-DASH source (audio only)
@property (strong, nonatomic, readonly) AVPlayerItem *dshPlayerItem;

/// Dynamic player item, may point to either @c hlsPlayerItem or @c dshPlayerItem depeneding on user settings
@property (strong, nonatomic, readonly) AVPlayerItem *playerItem;
/// Approximate duration of the video item, provided by the server
@property (nonatomic, readonly) NSTimeInterval approximateDuration;

/// Date after which the asset will no longer be accessible
@property (strong, nonatomic, readonly) NSDate *assetExpiry;
/// Whether the asset is loaded and is not expired.
/// Cannot be valid until @c requestPlayerResponse: is called
@property (nonatomic, readonly, getter=isValid) BOOL valid;

/// Watch endpoint used to instantiate object
@property (strong, nonatomic, readonly) YTIWatchEndpoint *watchEndpoint;
/// Player response passed into the @c requestPlayerResponse: completion handler
@property (strong, nonatomic, readonly) YTIPlayerResponse *playerResponse;
/// User's like status of the video. Writes are asynchronous
@property (nonatomic) LMVideoLikedStatus likeStatus;

- (instancetype)initWithWatchpoint:(YTIWatchEndpoint *)watchpoint;
- (void)requestPlayerResponse:(void(^)(YTIPlayerResponse *response, NSError *error))responseHandler;

/// Current player metadata of the receiver. Used for Now Playing Info Center
- (NSDictionary<NSString *, id> *)playerMetadata;

@end
