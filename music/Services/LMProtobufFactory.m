//
//  LMProtobufFactory.m
//  music
//
//  Created by Leptos on 11/28/18.
//  Copyright © 2018 Leptos. All rights reserved.
//

#import "LMProtobufFactory.h"

#import <sys/utsname.h>
#import <sys/sysctl.h>

@implementation LMProtobufFactory

+ (YTIClientInfo *)_cachedClientInfoPortion {
    static YTIClientInfo *ret;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ret = [YTIClientInfo message];
        
        ret.deviceMake = @"Apple";
        ret.osName = UIDevice.currentDevice.systemName;
        
        struct utsname systemInfo;
        uname(&systemInfo);
        ret.deviceModel = @(systemInfo.machine);
        
        size_t size = 0;
        if (sysctlbyname("kern.osversion", NULL, &size, NULL, 0) != -1) {
            char machine[size];
            sysctlbyname("kern.osversion", machine, &size, NULL, 0);
            
            NSOperatingSystemVersion osVersion = NSProcessInfo.processInfo.operatingSystemVersion;
            ret.osVersion = [NSString stringWithFormat:@"%@.%@.%@.%s",
                 @(osVersion.majorVersion).stringValue,
                 @(osVersion.minorVersion).stringValue,
                 @(osVersion.patchVersion).stringValue,
                 machine];
        }
        
        // ret.screenWidthPoints = UIScreen.mainScreen.bounds.size.width;
        // ret.screenHeightPoints = UIScreen.mainScreen.bounds.size.height;
        // ret.screenPixelDensity = UIScreen.mainScreen.scale;
        // ret.screenDensityFloat = UIScreen.mainScreen.scale;
        
        ret.userInterfaceTheme = 2;
        ret.theme = 5;

        // don't touch. This is information from YouTube Music
        ret.clientName = 26; // enum
        ret.clientVersion = @"2.59.4";

    });
    return ret;
}

+ (YTIClientInfo *)currentClientInfo {
    /* [YTInnerTubeContextFactory clientInfoWithSendDeviceIdentifier:] */
    YTIClientInfo *ret = [self _cachedClientInfoPortion];
    
    // There's a lookup on `[CTTelephonyNetworkInfo subscriberCellularProvider]` and then an "isoFix"
    NSString *localISO = [NSLocale.currentLocale objectForKey:NSLocaleCountryCode];
    ret.carrierGeo = localISO;
    ret.acceptRegion = localISO;
    
    ret.acceptLanguage = NSLocale.preferredLanguages.firstObject;
    
    ret.applicationState = 1;
    ret.musicAppInfo.playBackMode = 1;
    ret.musicAppInfo.musicLocationMasterSwitch = 1;
    ret.musicAppInfo.musicActivityMasterSwitch = 1;
    
    // ret.locationInfo.locationInfoStatus = 5;
    // ret.locationInfo.locationPermissionAuthorizationStatus = 4;
    
    // ret.configInfo = nil; // there are some hashes here in the original implementation
    
    ret.timeZone = NSTimeZone.localTimeZone.name;
    ret.utcOffsetMinutes = (int)NSTimeZone.localTimeZone.secondsFromGMT/60;
    
    return ret;
}

@end
