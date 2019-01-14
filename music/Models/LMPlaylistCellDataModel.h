//
//  LMPlaylistCellDataModel.h
//  music
//
//  Created by Leptos on 12/6/18.
//  Copyright © 2018 Leptos. All rights reserved.
//

#import "../Services/LMCurrentPlayerManager.h"

@interface LMPlaylistCellDataModel : NSObject

@property (strong, nonatomic, readonly) NSString *title;
@property (strong, nonatomic, readonly) NSString *subTitle;
@property (strong, nonatomic, readonly) YTIWatchPlaylistEndpoint *endpoint;

+ (instancetype)modelWithTitle:(NSString *)title endpoint:(YTIWatchPlaylistEndpoint *)endpoint;
+ (instancetype)modelWithTitle:(NSString *)title subTitle:(NSString *)subTitle endpoint:(YTIWatchPlaylistEndpoint *)endpoint;

- (instancetype)initWithTitle:(NSString *)title endpoint:(YTIWatchPlaylistEndpoint *)endpoint;
- (instancetype)initWithTitle:(NSString *)title subTitle:(NSString *)subTitle endpoint:(YTIWatchPlaylistEndpoint *)endpoint;

@end
