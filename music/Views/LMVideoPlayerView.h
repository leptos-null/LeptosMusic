//
//  LMVideoPlayerView.h
//  music
//
//  Created by Leptos on 12/12/18.
//  Copyright © 2018 Leptos. All rights reserved.
//

@import UIKit;
@import AVFoundation;

@interface LMVideoPlayerView : UIView
/// Player object that this view will show the contents of
@property (strong, nonatomic) AVPlayer *backingPlayer;
/// The manner in which the view is filled
@property (strong, nonatomic) AVLayerVideoGravity fillType;

@end
