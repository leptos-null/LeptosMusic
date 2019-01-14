//
//  LMVideoPlayerView.m
//  music
//
//  Created by Leptos on 12/12/18.
//  Copyright © 2018 Leptos. All rights reserved.
//

#import "LMVideoPlayerView.h"

#import "../Services/LMCurrentPlayerManager.h"

@implementation LMVideoPlayerView

+ (Class)layerClass {
    return [AVPlayerLayer class];
}
- (AVPlayerLayer *)internalLayer {
    return (AVPlayerLayer *)self.layer;
}

- (AVPlayer *)backingPlayer {
    return self.internalLayer.player;
}
- (void)setBackingPlayer:(AVPlayer *)backingPlayer {
    self.internalLayer.player = backingPlayer;
}

- (AVLayerVideoGravity)fillType {
    return self.internalLayer.videoGravity;
}
- (void)setFillType:(AVLayerVideoGravity)fillType {
    self.internalLayer.videoGravity = fillType;
}

@end
