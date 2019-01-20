//
//  LMInnerTubeRequest.m
//  music
//
//  Created by Leptos on 11/27/18.
//  Copyright © 2018 Leptos. All rights reserved.
//

#import "LMInnerTubeRequest.h"

#import "../Services/LMInnerTubeSession.h"

NSErrorDomain const LMInnerTubeRequestErrorDomain = @"null.leptos.music.innertube.request";

@implementation LMInnerTubeRequest {
    LMInnerTubeSession *_runSession;
}

- (void)completeRequestWithCompletion:(void(^)(__kindof GPBMessage *message, NSError *error))completion {
    Class targetClass = self.responseClass;
    __block id retainInc = self;
    
    NSData *messageData = self.message.data;
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.URL];
    request.HTTPMethod = @"POST";
    request.HTTPBody = messageData;
    [request setValue:@(messageData.length).stringValue forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/x-protobuf" forHTTPHeaderField:@"Content-Type"];

    LMInnerTubeSession *session = [LMInnerTubeSession sessionWithRequest:request completion:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (completion) {
            if (error) {
                completion(nil, error);
            } else if (data) {
                if ([targetClass isSubclassOfClass:[GPBMessage class]]) {
                    GPBMessage *message = [targetClass parseFromData:data error:&error];
                    if (error) {
                        NSDictionary *errMessage = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
                        if (errMessage) {
                            NSError *customError = [NSError errorWithDomain:@"com.googleapis.youtubei.request" code:1 userInfo:errMessage];
                            completion(nil, customError);
                        } else {
                            NSError *customError = [NSError errorWithDomain:LMInnerTubeRequestErrorDomain code:1 userInfo:@{
                                NSLocalizedDescriptionKey : @"Unknown error",
                                NSLocalizedFailureReasonErrorKey : @"Response object is not a Protobuf Message or JSON"
                            }];
                            completion(nil, customError);
                        }
                    } else {
                        completion(message, nil);
                    }
                } else {
                    @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"responseClass must be a GPBMessage subclass" userInfo:@{
                        @"responseClass" : (NSStringFromClass(targetClass) ?: @"(NULL)")
                    }];
                }
            } else {
                NSError *customError = [NSError errorWithDomain:LMInnerTubeRequestErrorDomain code:1 userInfo:@{
                    NSLocalizedDescriptionKey : @"Unknown error",
                    NSLocalizedFailureReasonErrorKey : @"Both data and error are nil after completing network request"
                }];
                completion(nil, customError);
            }
        }
        if (retainInc) { /* silence dead store analyzer warning */
            retainInc = nil;
        }
    }];
    [session complete];
    _runSession = session;
}

@end
