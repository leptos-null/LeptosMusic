//
//  LMInnerTubeURLBuilder.m
//  music
//
//  Created by Leptos on 12/1/18.
//  Copyright © 2018 Leptos. All rights reserved.
//

#import "LMInnerTubeURLBuilder.h"

@implementation LMInnerTubeURLBuilder

+ (NSString *)urlEncodedStringWithDictionary:(NSDictionary *)dict {
    NSMutableString *str = [NSMutableString string];
    for (NSString *key in dict) {
        [str appendFormat:@"%@=%@&", key, dict[key]];
    }
    if (str.length) {
        NSUInteger const trailCharacterDelete = 1;
        [str deleteCharactersInRange:NSMakeRange(str.length-trailCharacterDelete, trailCharacterDelete)];
    }
    return [str copy];
}

- (instancetype)init {
    if (self = [super init]) {
        _host = @"youtubei.googleapis.com";
        _collection = @"youtubei";
        _version = @"v1";
        _apiKey = @"AIzaSyDK3iBpDP9nHVTk2qL73FLJICfOC3c51Og";
    }
    return self;
}

- (instancetype)initWithScope:(NSString *)scope {
    if (self = [self init]) {
        _scope = scope;
    }
    return self;
}

- (NSURL *)URL {
    NSMutableDictionary *queries = [NSMutableDictionary dictionaryWithDictionary:@{
        @"key" : self.apiKey
    }];
    [queries addEntriesFromDictionary:self.additionalQueries];
    
    NSURLComponents *comps = [NSURLComponents new];
    comps.scheme = @"https";
    comps.host = self.host;
    comps.query = [LMInnerTubeURLBuilder urlEncodedStringWithDictionary:[queries copy]];
    comps.path = [NSString stringWithFormat:@"/%@/%@/%@", self.collection, self.version, self.scope];
    return comps.URL;
}

+ (NSURL *)defaultURLForScope:(NSString *)scope {
    LMInnerTubeURLBuilder *builder = [[self alloc] initWithScope:scope];
    return builder.URL;
}

@end
