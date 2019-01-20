//
//  LMPlaylistCellDataModel.h
//  music
//
//  Created by Leptos on 12/6/18.
//  Copyright © 2018 Leptos. All rights reserved.
//

#import "../Services/LMCurrentPlayerManager.h"

@interface LMPlaylistCellDataModel : NSObject

/// Title for the cell. Typically the title of the first playlist item
@property (strong, nonatomic, readonly) NSString *title;
/// Subtitle for the cell. Typically the media type of the first playlist item, e.g. "Song", "Video"
@property (strong, nonatomic, readonly) NSString *subTitle;
/// A playlist watch endpoint
@property (strong, nonatomic, readonly) YTIWatchPlaylistEndpoint *endpoint;

+ (instancetype)modelWithTitle:(NSString *)title endpoint:(YTIWatchPlaylistEndpoint *)endpoint;
+ (instancetype)modelWithTitle:(NSString *)title subTitle:(NSString *)subTitle endpoint:(YTIWatchPlaylistEndpoint *)endpoint;

- (instancetype)initWithTitle:(NSString *)title endpoint:(YTIWatchPlaylistEndpoint *)endpoint;
- (instancetype)initWithTitle:(NSString *)title subTitle:(NSString *)subTitle endpoint:(YTIWatchPlaylistEndpoint *)endpoint;

@end
