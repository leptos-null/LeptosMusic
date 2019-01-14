//
//  LMPreferencesManager.m
//  music
//
//  Created by Leptos on 12/12/18.
//  Copyright © 2018 Leptos. All rights reserved.
//

#import "LMPreferencesManager.h"

#define LMPreferencesManagerVisualTypeUserDefaultsKey @"LMPreferencesManagerVisualTypeUserDefaultsKey"

NSNotificationName LMVisualTypePreferenceDidChangeNotification = @"LMVisualTypePreferenceDidChangeNotification";

@implementation LMPreferencesManager

+ (instancetype)sharedManager {
    static LMPreferencesManager *ret;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ret = [self new];
    });
    return ret;
}

- (instancetype)init {
    if (self = [super init]) {
        NSUserDefaults *userDefaults = NSUserDefaults.standardUserDefaults;
        [userDefaults registerDefaults:@{
            LMPreferencesManagerVisualTypeUserDefaultsKey : @(LMPreferencesVisualizerTypeVideo)
        }];
        _visualType = [userDefaults integerForKey:LMPreferencesManagerVisualTypeUserDefaultsKey];
    }
    return self;
}

- (void)setVisualType:(LMPreferencesVisualizerType)visualType {
    _visualType = visualType;
    [NSNotificationCenter.defaultCenter postNotificationName:LMVisualTypePreferenceDidChangeNotification object:self];
    [NSUserDefaults.standardUserDefaults setInteger:visualType forKey:LMPreferencesManagerVisualTypeUserDefaultsKey];
}

@end
