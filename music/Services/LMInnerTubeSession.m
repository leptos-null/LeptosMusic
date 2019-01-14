//
//  LMInnerTubeSession.m
//  music
//
//  Created by Leptos on 11/27/18.
//  Copyright © 2018 Leptos. All rights reserved.
//

@import UIKit;

#import "LMInnerTubeSession.h"

#import "LMRequestCryptoManager.h"
#import "LMAccessTokenManager.h"

@implementation LMInnerTubeSession {
    NSURLSessionTaskCompletionBlock _completionBlock;
}

+ (instancetype)sessionWithRequest:(NSMutableURLRequest *)request completion:(NSURLSessionTaskCompletionBlock)completion {
    return [[self alloc] initWithRequest:request completion:completion];
}

- (instancetype)initWithRequest:(NSMutableURLRequest *)request completion:(NSURLSessionTaskCompletionBlock)completion {
    if (self = [self init]) {
        _urlRequest = request;
        _completionBlock = completion;
    }
    return self;
}

- (void)_testAndExecute {
    if (self.cryptoGreenLight && self.accessGreenLight) {
        [[NSURLSession.sharedSession dataTaskWithRequest:_urlRequest completionHandler:_completionBlock] resume];
    }
}

- (void)setCryptoGreenLight:(BOOL)cryptoGreenLight {
    _cryptoGreenLight = cryptoGreenLight;
    [self _testAndExecute];
}
- (void)setAccessGreenLight:(BOOL)accessGreenLight {
    _accessGreenLight = accessGreenLight;
    [self _testAndExecute];
}

- (BOOL)_tryCryptoSign {
    LMRequestCryptoManager *cryptoManager = LMRequestCryptoManager.sharedManager;
    
    NSError *signErr = nil;
    [cryptoManager signURLRequest:_urlRequest error:&signErr];
    if (signErr) {
        [self _callCompletionWithError:signErr];
        return NO;
    } else {
        return YES;
    }
}

- (void)_callCompletionWithError:(NSError *)err {
    _completionBlock(nil, nil, err);
}

/* this is Wikipedia's preferred format, which is sort of based on Mozilla's:
 * https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/User-Agent
 *
 * the decision to have this custom user agent was internal.
 * if you're not leptos, and you're using this code:
 * I'd prefer you leave this user agent in, as it is, however
 * the license of this project does not require it to be used
 */
- (NSString *)_userAgent {
    static NSString *ret;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSBundle *mainBundle = NSBundle.mainBundle;
        NSString *clientInfo = [mainBundle.bundleIdentifier stringByAppendingPathComponent:mainBundle.infoDictionary[@"CFBundleShortVersionString"]];
        
        NSString *contactInfo = @"@leptos_null; leptos.0.null@gmail.com";
        
        UIDevice *currentDevice = UIDevice.currentDevice;
        NSString *subClientInfo = [currentDevice.systemName stringByAppendingPathComponent:currentDevice.systemVersion];
        
        ret = [NSString stringWithFormat:@"%@ (%@) %@", clientInfo, contactInfo, subClientInfo];
    });
    return ret;
}

- (void)complete {
    [_urlRequest setValue:[self _userAgent] forHTTPHeaderField:@"User-Agent"];
    
    LMRequestCryptoManager *cryptoManager = LMRequestCryptoManager.sharedManager;
    if (cryptoManager.ready) {
        if ([self _tryCryptoSign]) {
            self.cryptoGreenLight = YES;
        }
    } else {
        __weak typeof(self) weakself = self;
        [cryptoManager addReadyCallback:^{
            if ([weakself _tryCryptoSign]) {
                weakself.cryptoGreenLight = YES;
            }
        }];
    }
    
    LMAccessTokenManager *tokenManager = LMAccessTokenManager.sharedManager;
    if (tokenManager.privateAccess.valid) {
        [tokenManager authorizePrivateRequest:_urlRequest];
        self.accessGreenLight = YES;
    } else {
        __weak typeof(self) weakself = self;
        [tokenManager updatePrivateAccessTokenWithCompletion:^(NSError *error) {
            if (error) {
                [weakself _callCompletionWithError:error];
            } else {
                [tokenManager authorizePrivateRequest:weakself.urlRequest];
                weakself.accessGreenLight = YES;
            }
        }];
    }
}

@end
