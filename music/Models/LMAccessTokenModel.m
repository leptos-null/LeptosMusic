//
//  LMAccessTokenModel.m
//  music
//
//  Created by Leptos on 11/26/18.
//  Copyright © 2018 Leptos. All rights reserved.
//

#import "LMAccessTokenModel.h"

#define LMAccessTokenModelTokenCodingKey @"LMAccessTokenModelTokenEncodeKey"
#define LMAccessTokenModelExpiryCodingKey @"LMAccessTokenModelExpiryEncodeKey"

/* I prefer using unions over casts */
typedef union {
    NSTimeInterval time;
    char bytes[sizeof(NSTimeInterval)];
} NSTimeIntervalByteUnion;

@implementation LMAccessTokenModel

- (instancetype)initWithToken:(NSString *)token expiry:(NSDate *)expiry {
    if (self = [self init]) {
        _token = token;
        _expiry = expiry;
    }
    return self;
}

- (BOOL)isValid {
    /* a date that's in the future from "now" will view the time-since-now as a positive interval
     * think that it's currently 0800, and the expiry is 0900, the time since 0800 at 0900 is +1 hour
     */
    return (self.expiry.timeIntervalSinceNow > 0) && self.token;
}

- (NSData *)dataStore {
    NSTimeIntervalByteUnion dateUnderstanding;
    dateUnderstanding.time = self.expiry.timeIntervalSince1970;
    
    NSMutableData *data = [NSMutableData dataWithBytes:dateUnderstanding.bytes length:sizeof(dateUnderstanding)];
    
    const char *confirmToken = self.token.UTF8String;
    // use strlen as a more accurate length represenation
    // I'm using UTF8String because the token should be in such an encoding
    // however, for a matter of practice, strlen is used in case the conversion
    // from an unknown encoding resulted in additional "spill" bytes
    [data appendBytes:confirmToken length:strlen(confirmToken)];
    
    return [data copy];
}

- (instancetype)initWithDataStore:(NSData *)dataStore {
    if (dataStore.length < sizeof(NSTimeIntervalByteUnion)) {
        return nil;
    }
    if (self = [self init]) {
        NSTimeIntervalByteUnion dateUnderstanding;
        [dataStore getBytes:dateUnderstanding.bytes range:NSMakeRange(0, sizeof(dateUnderstanding))];
        _expiry = [NSDate dateWithTimeIntervalSince1970:dateUnderstanding.time];
        
        char tokenBytes[dataStore.length - sizeof(dateUnderstanding)];
        [dataStore getBytes:tokenBytes range:NSMakeRange(sizeof(dateUnderstanding), sizeof(tokenBytes))];
        _token = @(tokenBytes);
    }
    return self;
}

- (NSUInteger)hash {
    NSString *value = [self.token stringByAppendingString:@(self.expiry.timeIntervalSince1970).stringValue];
    return value.hash;
}

// MARK: Coding
+ (BOOL)supportsSecureCoding {
    return YES;
}

- (void)encodeWithCoder:(nonnull NSCoder *)aCoder {
    [aCoder encodeObject:self.token forKey:LMAccessTokenModelTokenCodingKey];
    [aCoder encodeObject:self.expiry forKey:LMAccessTokenModelExpiryCodingKey];
}

- (instancetype)initWithCoder:(nonnull NSCoder *)aDecoder {
    if (self = [self init]) {
        _token = [aDecoder decodeObjectForKey:LMAccessTokenModelTokenCodingKey];
        _expiry = [aDecoder decodeObjectForKey:LMAccessTokenModelExpiryCodingKey];
    }
    return self;
}

// MARK: Copying
- (instancetype)copyWithZone:(NSZone *)zone {
    return [[[self class] allocWithZone:zone] initWithToken:self.token expiry:self.expiry];
}

@end
