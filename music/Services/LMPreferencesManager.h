//
//  LMPreferencesManager.h
//  music
//
//  Created by Leptos on 12/12/18.
//  Copyright © 2018 Leptos. All rights reserved.
//

@import Foundation;

typedef NS_ENUM(NSInteger, LMPreferencesVisualizerType) {
    LMPreferencesVisualizerTypeNone,
    LMPreferencesVisualizerTypeVideo,
    LMPreferencesVisualizerTypeHistogram,
    LMPreferencesVisualizerTypeMetal,
};

FOUNDATION_EXPORT NSNotificationName LMVisualTypePreferenceDidChangeNotification;

@interface LMPreferencesManager : NSObject

@property (class, strong, nonatomic, readonly) LMPreferencesManager *sharedManager;

@property (nonatomic) LMPreferencesVisualizerType visualType;

@end
