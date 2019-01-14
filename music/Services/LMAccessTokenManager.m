//
//  LMAccessTokenManager.m
//  music
//
//  Created by Leptos on 11/26/18.
//  Copyright © 2018 Leptos. All rights reserved.
//

#import "LMAccessTokenManager.h"
#import "../Models/LMInnerTubeURLBuilder.h"

#if defined(__has_include)
#   if __has_include("LMPrivateGoogleAccessToken.h")
#       include "LMPrivateGoogleAccessToken.h"
#   endif
#endif

#ifndef LMPrivateGoogleAccessToken
#   error Create a file called LMPrivateGoogleAccessToken.h in this directory, and put your access token in it. See README for more information
#endif

#define LMAccessTokenManagerGeneralAccessUserDefaultsKey @"LMAccessTokenManagerGeneralAccessUserDefaultsKey"
#define LMAccessTokenManagerPrivateAccessUserDefaultsKey @"LMAccessTokenManagerPrivateAccessUserDefaultsKey"
#define LMAccessTokenManagerAuthorizationUserDefaultsKey @"LMAccessTokenManagerAuthorizationUserDefaultsKey"

@implementation LMAccessTokenManager {
    /// HTTP Authorization prefix, e.g. Basic, Bearer, Digest
    NSString *_authorizationType;
}

+ (instancetype)sharedManager {
    static LMAccessTokenManager *ret;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ret = [self new];
    });
    return ret;
}

- (instancetype)init {
    if (self = [super init]) {
#ifdef LMPrivateGoogleAccessToken
        _refreshToken = LMPrivateGoogleAccessToken;
#endif
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        NSData *generalData = [defaults dataForKey:LMAccessTokenManagerGeneralAccessUserDefaultsKey];
        _generalAccess = [[LMAccessTokenModel alloc] initWithDataStore:generalData];
        
        NSData *privateData = [defaults dataForKey:LMAccessTokenManagerPrivateAccessUserDefaultsKey];
        _privateAccess = [[LMAccessTokenModel alloc] initWithDataStore:privateData];
        
        _authorizationType = [defaults stringForKey:LMAccessTokenManagerAuthorizationUserDefaultsKey];
    }
    return self;
}

- (NSString *)_authorizationValueForToken:(LMAccessTokenModel *)token {
    return [NSString stringWithFormat:@"%@ %@", _authorizationType, token.token];
}

- (void)_authorizeRequest:(NSMutableURLRequest *)request withToken:(LMAccessTokenModel *)token {
    [request setValue:[self _authorizationValueForToken:token] forHTTPHeaderField:@"Authorization"];
}

- (void)setRefreshToken:(NSString *)refreshToken {
    _refreshToken = refreshToken;
    _generalAccess = nil;
    _privateAccess = nil;
}

// MARK: Public methods
- (void)authorizePrivateRequest:(NSMutableURLRequest *)request {
    [self _authorizeRequest:request withToken:self.privateAccess];
}

- (void)updateGeneralAccessTokenWithCompletion:(void (^)(NSError *))completion {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://www.googleapis.com/oauth2/v4/token"]];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    NSDictionary *requestData = @{
        @"client_id" : @"936475272427.apps.googleusercontent.com", /* YouTube Music's client ID */
        @"grant_type" : @"refresh_token",
        @"refresh_token" : self.refreshToken
    };
    
    request.HTTPBody = [[LMInnerTubeURLBuilder urlEncodedStringWithDictionary:requestData] dataUsingEncoding:NSUTF8StringEncoding];
    
    __weak typeof(self) weakself = self;
    [[NSURLSession.sharedSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (data) {
            NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if (jsonResponse && weakself) {
                NSNumber *expiresInValue = jsonResponse[@"expires_in"];
                NSDate *expiry = [NSDate dateWithTimeIntervalSinceNow:expiresInValue.doubleValue];
                
                NSString *accessToken = jsonResponse[@"access_token"];
                
                LMAccessTokenModel *token = [[LMAccessTokenModel alloc] initWithToken:accessToken expiry:expiry];
                NSString *authType = jsonResponse[@"token_type"];
                
                typeof(self) strongself = weakself;
                strongself->_generalAccess = token;
                strongself->_authorizationType = authType;
                
                NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
                [defaults setObject:token.dataStore forKey:LMAccessTokenManagerPrivateAccessUserDefaultsKey];
                [defaults setObject:authType forKey:LMAccessTokenManagerAuthorizationUserDefaultsKey];
            }
        }
        if (completion) {
            completion(error);
        }
    }] resume];
}

- (void)updatePrivateAccessTokenWithCompletion:(void(^)(NSError *))completion {
    if (!self.generalAccess.valid) {
        [self updateGeneralAccessTokenWithCompletion:^(NSError *error) {
            if (error) {
                if (completion) {
                    completion(error);
                }
            } else {
                [self updatePrivateAccessTokenWithCompletion:completion];
            }
        }];
        return;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://www.googleapis.com/oauth2/v2/IssueToken"]];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [self _authorizeRequest:request withToken:self.generalAccess];
    
    NSArray<NSString *> *apiScopes = @[
        @"https://www.googleapis.com/auth/youtube",
        @"https://www.googleapis.com/auth/youtube.force-ssl",
        @"https://www.googleapis.com/auth/plus.pages.manage",
        @"https://www.google.com/accounts/OAuthLogin",
        @"https://www.googleapis.com/auth/identity.plus.page.impersonation",
        @"https://www.googleapis.com/auth/supportcontent",
        @"https://www.googleapis.com/auth/account_settings_mobile",
        @"https://www.googleapis.com/auth/plus.circles.read"
    ];
    
    NSDictionary *requestData = @{
        @"app_id" : @"com.google.ios.youtubemusic", /* YouTube M*/
        @"client_id" : @"755973059757-iigsfdoqt2c4qm209soqp2dlrh33almr.apps.googleusercontent.com",
        @"hl" : [NSLocale.currentLocale objectForKey:NSLocaleLanguageCode],
        @"lib_ver" : @"3.3",
        @"response_type" : @"token",
        @"scope" : [apiScopes componentsJoinedByString:@" "]
    };
    request.HTTPBody = [[LMInnerTubeURLBuilder urlEncodedStringWithDictionary:requestData] dataUsingEncoding:NSUTF8StringEncoding];
    
    __weak typeof(self) weakself = self;
    [[NSURLSession.sharedSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (data) {
            NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if (jsonResponse && weakself) {
                NSNumber *expiresInValue = jsonResponse[@"expiresIn"];
                NSDate *expiry = [NSDate dateWithTimeIntervalSinceNow:expiresInValue.doubleValue];
                
                NSString *accessToken = jsonResponse[@"token"];
                
                LMAccessTokenModel *token = [[LMAccessTokenModel alloc] initWithToken:accessToken expiry:expiry];
                
                typeof(self) strongself = weakself;
                strongself->_privateAccess = token;
                
                [NSUserDefaults.standardUserDefaults setObject:token.dataStore forKey:LMAccessTokenManagerPrivateAccessUserDefaultsKey];
            }
        }
        if (completion) {
            completion(error);
        }
    }] resume];
}

- (void)getMetadataForToken:(LMAccessTokenModel *)token completion:(void (^)(NSDictionary *, NSError *))completion {
    NSString *endpoint = [@"https://www.googleapis.com/oauth2/v2/tokeninfo?access_token=" stringByAppendingString:token.token];
    NSURL *target = [NSURL URLWithString:endpoint];
    [[NSURLSession.sharedSession dataTaskWithURL:target completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSDictionary *dict = nil;
        if (data) {
            dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        }
        if (completion) {
            completion(dict, error);
        }
    }] resume];
}

@end
