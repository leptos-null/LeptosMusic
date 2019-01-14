//
//  LMInnerTubeURLBuilder.h
//  music
//
//  Created by Leptos on 12/1/18.
//  Copyright © 2018 Leptos. All rights reserved.
//

@import Foundation;

@interface LMInnerTubeURLBuilder : NSObject
/// String that can be used as URL parameters or HTTP body form-urlencoded content
+ (NSString *)urlEncodedStringWithDictionary:(NSDictionary *)dict;

/// Calculated from below properties. Always HTTPS.
/// In the form: https://{host}/{collection}/{version}/{scope}?key={apiKey}&{additionalQueries}
@property (strong, nonatomic, readonly) NSURL *URL;

/// defaults to "youtubei.googleapis.com"
@property (strong, nonatomic) NSString *host;
/// defaults to "youtubei"
@property (strong, nonatomic) NSString *collection;
/// defaults to "v1"
@property (strong, nonatomic) NSString *version;
/// defaults to "AIzaSyDK3iBpDP9nHVTk2qL73FLJICfOC3c51Og"
@property (strong, nonatomic) NSString *apiKey;
/// Additional HTTP queries to be added to the URL.
@property (strong, nonatomic) NSDictionary *additionalQueries;

/// InnerTube sub-scope. "browse", "guide", "next", etc.
@property (strong, nonatomic, readonly) NSString *scope;

- (instancetype)initWithScope:(NSString *)scope;

+ (NSURL *)defaultURLForScope:(NSString *)scope;

@end
