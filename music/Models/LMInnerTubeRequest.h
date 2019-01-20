//
//  LMInnerTubeRequest.h
//  music
//
//  Created by Leptos on 11/27/18.
//  Copyright © 2018 Leptos. All rights reserved.
//

@import Foundation;

#import "../../LMYTIGeneratedProtobufs/LMYTIGeneratedProtobufs.h"
#import "LMInnerTubeURLBuilder.h"

FOUNDATION_EXPORT NSErrorDomain const LMInnerTubeRequestErrorDomain;

@interface LMInnerTubeRequest : NSObject
/// The message to be sent in the request body
@property (strong, nonatomic) __kindof GPBMessage *message;
/// The class to parse the response into, should be the same as ResponseType
@property (weak, nonatomic) Class responseClass;
/// Full URL endpoint for the request
@property (strong, nonatomic) NSURL *URL;

- (void)completeRequestWithCompletion:(void(^)(__kindof GPBMessage *message, NSError *error))completion;

@end
