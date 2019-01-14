//
//  LMPlaylistCellDataModel.m
//  music
//
//  Created by Leptos on 12/6/18.
//  Copyright © 2018 Leptos. All rights reserved.
//

#import "LMPlaylistCellDataModel.h"

@implementation LMPlaylistCellDataModel

+ (instancetype)modelWithTitle:(NSString *)title subTitle:(NSString *)subTitle endpoint:(YTIWatchPlaylistEndpoint *)endpoint {
    return [[self alloc] initWithTitle:title subTitle:subTitle endpoint:endpoint];
}

+ (instancetype)modelWithTitle:(NSString *)title endpoint:(YTIWatchPlaylistEndpoint *)endpoint {
    return [[self alloc] initWithTitle:title endpoint:endpoint];
}

- (instancetype)initWithTitle:(NSString *)title subTitle:(NSString *)subTitle endpoint:(YTIWatchPlaylistEndpoint *)endpoint {
    if (self = [self init]) {
        _title = title;
        _subTitle = subTitle;
        _endpoint = endpoint;
    }
    return self;
}

- (instancetype)initWithTitle:(NSString *)title endpoint:(YTIWatchPlaylistEndpoint *)endpoint {
    return [self initWithTitle:title subTitle:nil endpoint:endpoint];
}

@end
