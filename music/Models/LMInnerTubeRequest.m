//
//  LMInnerTubeRequest.m
//  music
//
//  Created by Leptos on 11/27/18.
//  Copyright © 2018 Leptos. All rights reserved.
//

#import "LMInnerTubeRequest.h"

#import "../Services/LMInnerTubeSession.h"

@implementation LMInnerTubeRequest {
    LMInnerTubeSession *_runSession;
}

- (void)completeRequestWithCompletion:(void(^)(__kindof GPBMessage *message, NSError *error))completion {
    Class targetClass = self.responseClass;
    
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
                            NSError *customError = [NSError errorWithDomain:@"null.leptos.music.innertube.request" code:1 userInfo:@{
                                @"message" : @"Unknown error"
                            }];
                            completion(nil, customError);
                        }
                    } else {
                        completion(message, nil);
                    }
                } else {
                    NSError *customError = [NSError errorWithDomain:@"null.leptos.music.innertube.request" code:1 userInfo:@{
                        @"message" : @"responseClass must be a GPBMessage subclass"
                    }];
                    completion(nil, customError);
                }
            } else {
                NSError *customError = [NSError errorWithDomain:@"null.leptos.music.innertube.request" code:1 userInfo:@{
                    @"message" : @"Unknown error"
                }];
                completion(nil, customError);
            }
        }
    }];
    [session complete];
    _runSession = session;
}

@end
