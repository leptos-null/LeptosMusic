//
//  LMAccessTokenManager.h
//  music
//
//  Created by Leptos on 11/26/18.
//  Copyright © 2018 Leptos. All rights reserved.
//

@import Foundation;

#import "../Models/LMAccessTokenModel.h"

@interface LMAccessTokenManager : NSObject
/// Do not attempt to create another instance of this class. Use this sharedManager only.
@property (class, strong, nonatomic, readonly) LMAccessTokenManager *sharedManager;
/// A privileged refresh token for the current Google Account
@property (strong, nonatomic) NSString *refreshToken;
/// Token able to access public Google API
@property (strong, nonatomic, readonly) LMAccessTokenModel *generalAccess;
/// Token able to access private Google API
@property (strong, nonatomic, readonly) LMAccessTokenModel *privateAccess;

- (void)updateGeneralAccessTokenWithCompletion:(void(^)(NSError *error))completion;
- (void)updatePrivateAccessTokenWithCompletion:(void(^)(NSError *error))completion;

/// Convenience method to set the HTTP Authoization header.
/// A similar method is not provided for General because you should not be making general requests
- (void)authorizePrivateRequest:(NSMutableURLRequest *)request;
/// Makes a request to Google for a token's metadata.
/// More information: @c https://developers.google.com/identity/sign-in/web/backend-auth#calling-the-tokeninfo-endpoint
- (void)getMetadataForToken:(LMAccessTokenModel *)token completion:(void(^)(NSDictionary *metadata, NSError *error))completion;

@end
