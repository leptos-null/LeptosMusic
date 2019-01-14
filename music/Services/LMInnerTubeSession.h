//
//  LMInnerTubeSession.h
//  music
//
//  Created by Leptos on 11/27/18.
//  Copyright © 2018 Leptos. All rights reserved.
//

@import Foundation;

#import "../Models/LMInnerTubeRequest.h"

/* I decided to use the NS prefix, because it seems more appropriate,
 * but it's also inappropriate to use someone else's prefix in case
 * they decided to add a symbol by that name
 */
typedef void(^NSURLSessionTaskCompletionBlock)(NSData *data, NSURLResponse *response, NSError *error);

@interface LMInnerTubeSession : NSObject
/// The request used to instantiate the object
@property (nonatomic, strong, readonly) NSMutableURLRequest *urlRequest;
/// Reflects whether the request has been signed by the crypto manager
@property (nonatomic, readonly) BOOL cryptoGreenLight;
/// Reflects whether the request has a valid access token
@property (nonatomic, readonly) BOOL accessGreenLight;

/// A session object with the given request. The completion handler will be called asynchronously after @c complete is called
+ (instancetype)sessionWithRequest:(NSMutableURLRequest *)request completion:(NSURLSessionTaskCompletionBlock)completion;
- (instancetype)initWithRequest:(NSMutableURLRequest *)request completion:(NSURLSessionTaskCompletionBlock)completion;
/// Start the process of signing, authorizing, and making the request.
- (void)complete;

@end
