//
//  LMApiaryDeviceCrypto.h
//
//  Created by Leptos on 11/18/18.
//  Copyright © 2018 Leptos. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kYouTubeBase64EncodedProjectKey @"vOU14u6GkupSL2pLKI/B7L3pBZJpI8W92RoKHJOu3PY="
#define kYouTubeMusicBase64EncodedProjectKey @"WrM95onSB5FfXofSzKWgkNZGiosfmCCAcTH4htvkuj4="

/// Fully implemented mirror of @c YTApiaryDeviceCrypto.
/// Some implementations have been slightly edited,
/// however anything created with either class will work with the other,
/// including Archives, however this is SecureCoding, and YT is not.
/// An instance of this class should be created once, and stored to disk using @c NSKeyedArchiver.
/// This class is able to sign @c NSMutableURLRequest objects for interaction with private YouTube REST API.
@interface LMApiaryDeviceCrypto : NSObject <NSSecureCoding>

/// For convenience, the Base64 encoded values of the project keys for YouTube and YouTube Music are included above.
/// @param hmacLength Specify 4
- (instancetype)initWithProjectKey:(NSData *)projectKey HMACLength:(NSUInteger)hmacLength;
/// Before signing a URL request, the deviceID and deviceKey must be set.
/// A valid deviceID and deviceKey can be obtained by making an HTTP POST to
/// https://youtubei.googleapis.com/deviceregistration/v1/devices?key=API_KEY&rawDeviceId=RAW_DEVICE_ID
/// where API_KEY is a valid API key, and RAW_DEVICE_ID is any nonnull string (may support only UUIDs in the future)
- (BOOL)setDeviceID:(NSString *)deviceID deviceKey:(NSString *)deviceKey error:(NSError **)error;

/// Signing a URL request uses all the compotents of this class, ensure they are all valid, before calling.
/// The signature is place in the @c X-Goog-Device-Auth HTTP header field.
/// Mutating the URL or HTTPBody of the @c request after signing it is invalid- other header fields are safe
- (BOOL)signURLRequest:(NSMutableURLRequest *)request error:(NSError **)error;

/// Decrypt an encoded string that was encrypted with the same mechanism, and project key.
- (NSData *)decryptEncodedString:(NSString *)encodedString error:(NSError **)error;
/// Ecrypt and encode any given data. The result is unlikey to be the same for any given data,
/// however the input to this method will always be equal to the output of @c decryptEncodedString:error:
/// when the output of this method is passed as the input to that method.
/// The chance of a collision for the same data is not security sensative-
/// nonetheless the chance is 1 << 64 (a bit has 2 values over 64 bits is 2 raised to 64)
- (NSString *)encryptAndEncodeData:(NSData *)data error:(NSError **)error;

@end
