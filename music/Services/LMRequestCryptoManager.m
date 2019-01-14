//
//  LMRequestCryptoManager.m
//  music
//
//  Created by Leptos on 11/26/18.
//  Copyright © 2018 Leptos. All rights reserved.
//

#import "LMRequestCryptoManager.h"

#import "LMApiaryDeviceCrypto.h"
#import "../Models/LMInnerTubeURLBuilder.h"

#define LMRequestCryptoManagerApiaryUserDefaultsKey @"LMRequestCryptoManagerApiaryUserDefaultsKey"

@implementation LMRequestCryptoManager {
    LMApiaryDeviceCrypto *_crypto;
    NSMutableArray<LMRequestCryptoManagerReadyCallback> *_readyCallbacks;
}

+ (instancetype)sharedManager {
    static LMRequestCryptoManager *ret;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ret = [self new];
    });
    return ret;
}

- (instancetype)init {
    if (self = [super init]) {
        NSData *cryptoData = [NSUserDefaults.standardUserDefaults dataForKey:LMRequestCryptoManagerApiaryUserDefaultsKey];
        if (cryptoData) {
            if (@available(iOS 11.0, *)) {
                _crypto = [NSKeyedUnarchiver unarchivedObjectOfClass:[LMApiaryDeviceCrypto class] fromData:cryptoData error:NULL];
            } else {
                _crypto = [NSKeyedUnarchiver unarchiveObjectWithData:cryptoData];
            }
            _ready = YES;
        } else {
            _readyCallbacks = [NSMutableArray array];
            
            NSData *projectKey = [[NSData alloc] initWithBase64EncodedString:kYouTubeMusicBase64EncodedProjectKey options:0];
            LMApiaryDeviceCrypto *crypto = [[LMApiaryDeviceCrypto alloc] initWithProjectKey:projectKey HMACLength:4];
            _crypto = crypto;
            
            __weak typeof(self) weakself = self;
            [self _setupDeviceCrypto:crypto completion:^(NSError *error) {
                if (!error) {
                    if (weakself) {
                        typeof(self) strongself = weakself;
                        strongself->_ready = YES;
                        for (LMRequestCryptoManagerReadyCallback callback in strongself->_readyCallbacks) {
                            callback();
                        }
                    }
                    
                    NSData *archive = nil;
                    if (@available(iOS 11.0, *)) {
                        archive = [NSKeyedArchiver archivedDataWithRootObject:crypto requiringSecureCoding:YES error:&error];
                    } else {
                        archive = [NSKeyedArchiver archivedDataWithRootObject:crypto];
                    }
                    [NSUserDefaults.standardUserDefaults setObject:archive forKey:LMRequestCryptoManagerApiaryUserDefaultsKey];
                }
            }];
        }
    }
    return self;
}

- (void)_setupDeviceCrypto:(LMApiaryDeviceCrypto *)crypto completion:(void(^)(NSError *error))completion {
    NSUUID *rawDevice = [NSUUID UUID];

    LMInnerTubeURLBuilder *innerTubeReq = [[LMInnerTubeURLBuilder alloc] initWithScope:@"devices"];
    innerTubeReq.collection = @"deviceregistration";
    innerTubeReq.additionalQueries = @{
        @"rawDeviceId" : rawDevice.UUIDString
    };
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:innerTubeReq.URL];
    request.HTTPMethod = @"POST";
    
    [[NSURLSession.sharedSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (data) {
            NSDictionary *parsedTree = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if (parsedTree) {
                [crypto setDeviceID:parsedTree[@"id"] deviceKey:parsedTree[@"key"] error:&error];
            } else {
                error = [NSError errorWithDomain:@"null.leptos.music.cryptomanager" code:1 userInfo:@{
                    @"message" : @"Unknown server response, registering device",
                    @"response" : (data ?: @"(NULL)")
                }];
            }
        }
        if (completion) {
            completion(error);
        }
    }] resume];
}

- (BOOL)signURLRequest:(NSMutableURLRequest *)request error:(NSError **)error {
    if (self.ready) {
        return [_crypto signURLRequest:request error:error];
    } else {
        if (error) {
            *error = [NSError errorWithDomain:@"null.leptos.music.cryptomanager" code:1 userInfo:@{
                @"message" : @"DeviceCrypto is not yet ready"
            }];
        }
        return NO;
    }
}

- (void)addReadyCallback:(LMRequestCryptoManagerReadyCallback)callback {
    [_readyCallbacks addObject:callback];
}

@end
