//
//  LMRequestCryptoManager.h
//  music
//
//  Created by Leptos on 11/26/18.
//  Copyright © 2018 Leptos. All rights reserved.
//

@import Foundation;

typedef void(^LMRequestCryptoManagerReadyCallback)(void);

FOUNDATION_EXPORT NSErrorDomain const LMCryptoManagerErrorDomain;

@interface LMRequestCryptoManager : NSObject
/// Do not attempt to create other instances of this class.
@property (class, strong, nonatomic, readonly) LMRequestCryptoManager *sharedManager;
/// YES if the backing crypto object has been fully set up, otherwise NO.
/// The backing object only needs to be set-up once per install, however requires an Internet connection to do so
@property (nonatomic, readonly, getter=isReady) BOOL ready;

/// @c LMApiaryDeviceCrypto
- (BOOL)signURLRequest:(NSMutableURLRequest *)request error:(NSError **)error;
/// If @c ready is @c NO, this method can add a callback to be called when it becomes ready
- (void)addReadyCallback:(LMRequestCryptoManagerReadyCallback)callback;

@end
