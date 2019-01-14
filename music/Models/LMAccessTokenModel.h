//
//  LMAccessTokenModel.h
//  music
//
//  Created by Leptos on 11/26/18.
//  Copyright © 2018 Leptos. All rights reserved.
//

@import Foundation;

@interface LMAccessTokenModel : NSObject <NSCopying, NSSecureCoding>
/// The raw token value
@property (strong, nonatomic, readonly) NSString *token;
/// The date after which the token is no longer valid
@property (strong, nonatomic, readonly) NSDate *expiry;
/// YES if the current time is before the expiry time
@property (nonatomic, readonly, getter=isValid) BOOL valid;

/// A data representation of the receiver, used for serialization
- (NSData *)dataStore;
- (instancetype)initWithDataStore:(NSData *)dataStore;

- (instancetype)initWithToken:(NSString *)token expiry:(NSDate *)expiry;

@end
