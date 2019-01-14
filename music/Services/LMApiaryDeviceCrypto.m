//
//  LMApiaryDeviceCrypto.m
//
//  Created by Leptos on 11/18/18.
//  Copyright © 2018 Leptos. All rights reserved.
//

#import <CommonCrypto/CommonCrypto.h>

#import "LMApiaryDeviceCrypto.h"
#import "GTMStringEncoding.h"

#define kYTApiaryDeviceCryptoDeviceIdKey  @"kYTApiaryDeviceCryptoDeviceIdKey"
#define kYTApiaryDeviceCryptoDeviceKeyKey @"kYTApiaryDeviceCryptoDeviceKeyKey"
#define kYTDeviceCryptoProjectKeyKey      @"kYTDeviceCryptoProjectKeyKey"
#define kYTDeviceCryptoHMACKeyKey         @"kYTDeviceCryptoHMACKeyKey"
#define kYTDeviceCryptoHMACLengthKey      @"kYTDeviceCryptoHMACLengthKey"

@interface NSError (LMNetCryptoError)
+ (instancetype)netCryptoErrorWithMessage:(NSString *)message;
@end

@implementation LMApiaryDeviceCrypto {
    NSString *_deviceID;
    NSData *_deviceKey;
    NSData *_projectKey;
    NSData *_hmacKey;
    NSUInteger _hmacLength;
}

- (instancetype)init {
    /* original implementation calls [self class] first? */
    return nil;
}

- (instancetype)initWithProjectKey:(NSData *)projectKey HMACLength:(NSUInteger)hmacLength {
    if (self = [super init]) {
        _hmacLength = hmacLength;
        NSUInteger internalHmacLength = 0x10;
        NSUInteger projectKeyLength = projectKey.length;
        if (projectKeyLength >= internalHmacLength) {
            _projectKey = [projectKey subdataWithRange:NSMakeRange(0, internalHmacLength)];
            _hmacKey = [projectKey subdataWithRange:NSMakeRange(internalHmacLength, projectKeyLength-internalHmacLength)];
        }
    }
    return self;
}

- (BOOL)setDeviceID:(NSString *)deviceID deviceKey:(NSString *)deviceKey error:(NSError **)error {
    NSError *derefError = nil;
    _deviceKey = [self decryptEncodedString:deviceKey error:&derefError];
    if (derefError) {
        if (error) {
            *error = derefError;
        }
        return NO;
    } else {
        _deviceID = [deviceID copy];
        return YES;
    }
}

- (BOOL)signURLRequest:(NSMutableURLRequest *)request error:(NSError **)error {
    NSData *urlData = [request.URL.absoluteString dataUsingEncoding:NSUTF8StringEncoding];
    
    NSString *signedURL = [self signData:urlData padData:YES HMACLength:4];
    NSString *signedContent = [self signData:request.HTTPBody padData:NO HMACLength:CC_SHA1_DIGEST_LENGTH];
    
    NSString *compoundValue = [NSString stringWithFormat:@"device_id=%@,data=%@,content=%@", _deviceID, signedURL, signedContent];
    [request setValue:compoundValue forHTTPHeaderField:@"X-Goog-Device-Auth"];
    
    return YES;
}

- (NSString *)signData:(NSData *)data padData:(BOOL)shouldPad HMACLength:(NSUInteger)hmacLength {
    uint8_t sha1Digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(_deviceKey.bytes, (CC_LONG)_deviceKey.length, sha1Digest);
    NSData *hashedData = [NSData dataWithBytes:sha1Digest length:4];
    
    if (shouldPad) {
        NSUInteger padDataCapacity = data.length + 1;
        NSMutableData *padData = [NSMutableData dataWithCapacity:padDataCapacity];
        [padData appendData:data];
        padData.length = padDataCapacity;
        data = [padData copy];
    }
    CCHmac(kCCHmacAlgSHA1, _deviceKey.bytes, (size_t)_deviceKey.length, data.bytes, data.length, sha1Digest);
    NSMutableData *newData = [NSMutableData data];
    
    uint8_t zeroByte = 0;
    [newData appendBytes:&zeroByte length:sizeof(zeroByte)];
    [newData appendData:hashedData];
    size_t appendLength = sizeof(sha1Digest);
    if (hmacLength < appendLength) {
        appendLength = hmacLength;
    }
    [newData appendBytes:sha1Digest length:appendLength];
    
    GTMStringEncoding *stringEncoder = [GTMStringEncoding rfc4648Base64StringEncoding];
    stringEncoder.doPad = NO;
    return [stringEncoder encode:newData error:NULL];
}

- (NSData *)performCrypto:(NSData *)data outputLength:(NSUInteger)length IV:(NSData *)iv operation:(CCOperation)op {
    CCCryptorRef cryptor;
    CCCryptorStatus status = CCCryptorCreateWithMode(op, kCCModeCTR, kCCAlgorithmAES, ccNoPadding,
                                                     iv.bytes, _projectKey.bytes, 0x10, NULL, 0, 0, kCCModeOptionCTR_BE, &cryptor);
    if (status == kCCSuccess) {
        size_t cryptorLen = CCCryptorGetOutputLength(cryptor, data.length, true);
        NSMutableData *ret = [NSMutableData dataWithLength:cryptorLen];
        size_t dataMoved;
        status = CCCryptorUpdate(cryptor, data.bytes, data.length, ret.mutableBytes, cryptorLen, &dataMoved);
        if (status == kCCSuccess) {
            // CCCryptorRelease(cryptor); /* original has this, but cryptor is on the stack? */
            ret.length = length;
            return [ret copy];
        }
    }
    return nil;
}

- (NSData *)paddedData:(NSData *)data {
    NSUInteger dataLength = data.length;
    NSUInteger lengthMod = dataLength & 0xf;
    if (lengthMod) {
        NSMutableData *padData = [NSMutableData dataWithLength:dataLength + 0x10 - lengthMod];
        [padData replaceBytesInRange:NSMakeRange(0, dataLength) withBytes:data.bytes];
        return [padData copy]; /* copy call not in original */
    } else {
        return data;
    }
}

- (NSData *)projectKeySignature {
    NSMutableData *data = [NSMutableData dataWithCapacity:_hmacKey.length + 0x20];
    uint64_t magic = 0x1000000000000000;
    [data appendBytes:&magic length:sizeof(magic)];
    [data appendData:_projectKey];
    [data appendBytes:&magic length:sizeof(magic)];
    [data appendData:_hmacKey];
    
    uint8_t sha1Digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(data.bytes, (CC_LONG)data.length, sha1Digest);
    
    return [NSData dataWithBytes:sha1Digest length:4];
}

- (NSData *)decryptEncodedString:(NSString *)encodedString error:(NSError **)error {
    GTMStringEncoding *strEnc = [GTMStringEncoding rfc4648Base64StringEncoding];
    NSData *decoded = [strEnc decode:encodedString error:error];
    uint8_t firstByte;
    [decoded getBytes:&firstByte length:sizeof(firstByte)];
    if (firstByte == 0) {
        if (decoded.length > 0xc) {
            NSData *lowPad = [self paddedData:[decoded subdataWithRange:NSMakeRange(5, 8)]];
            NSInteger someVal = decoded.length - _hmacLength - 0xd;
            if (someVal >= 0) {
                if ([self verifySignedData:decoded]) {
                    NSData *highPad = [self paddedData:[decoded subdataWithRange:NSMakeRange(0xd, someVal)]];
                    return [self performCrypto:highPad outputLength:someVal IV:lowPad operation:kCCDecrypt];
                } else if (error) {
                    *error = [NSError netCryptoErrorWithMessage:@"Could not verify encrypted data"];
                }
            } else if (error) {
                *error = [NSError netCryptoErrorWithMessage:@"Could not determine cipher"];
            }
        } else if (error) {
            *error = [NSError netCryptoErrorWithMessage:@"Could not determine initializion vector"];
        }
    } else if (error) {
        *error = [NSError netCryptoErrorWithMessage:@"Could not determine key sign"];
    }
    return nil;
}

- (NSString *)encryptAndEncodeData:(NSData *)data error:(NSError **)error {
    NSMutableData *mutData = [NSMutableData data];
    int8_t zeroByte = 0;
    [mutData appendBytes:&zeroByte length:sizeof(zeroByte)];
    [mutData appendData:[self projectKeySignature]];
    
    uint8_t buff[8]; /* however you want this to be 8 bytes; could use a single uint64_t */
    arc4random_buf(buff, sizeof(buff));
    NSData *ivData = [NSData dataWithBytes:buff length:sizeof(buff)];
    [mutData appendData:ivData];
    
    NSData *crypto = [self performCrypto:[self paddedData:data] outputLength:data.length IV:[self paddedData:ivData] operation:kCCEncrypt];
    if (crypto) {
        [mutData appendData:crypto];
        NSMutableData *moreData = [NSMutableData dataWithLength:mutData.length + 9];
        
        uint8_t magicByte = 83;
        [moreData replaceBytesInRange:NSMakeRange(0, 1) withBytes:&magicByte];
        [moreData replaceBytesInRange:NSMakeRange(9, mutData.length) withBytes:mutData.bytes];
        
        uint8_t sha1Digest[CC_SHA1_DIGEST_LENGTH];
        CCHmac(kCCHmacAlgSHA1, _hmacKey.bytes, (size_t)_hmacKey.length, moreData.bytes, moreData.length, sha1Digest);
        [mutData appendBytes:sha1Digest length:_hmacLength];
        
        GTMStringEncoding *strEncode = [GTMStringEncoding rfc4648Base64StringEncoding];
        return [strEncode encode:mutData error:error];
    } else if (error) {
        *error = [NSError netCryptoErrorWithMessage:@"Generic crypto error."];
    }
    return nil;
}

- (BOOL)verifySignedData:(NSData *)data {
    NSData *projectHash = [data subdataWithRange:NSMakeRange(1, 4)];
    if ([projectHash isEqualToData:[self projectKeySignature]]) {
        NSInteger lengthDiff = data.length - _hmacLength;
        if (lengthDiff >= 0) {
            NSData *highData = [data subdataWithRange:NSMakeRange(lengthDiff, _hmacLength)];
            NSData *lowData = [data subdataWithRange:NSMakeRange(0, lengthDiff)];
            NSMutableData *mutData = [NSMutableData dataWithLength:lengthDiff + 9];
            
            uint8_t magicByte = 83;
            [mutData replaceBytesInRange:NSMakeRange(0, 1) withBytes:&magicByte];
            [mutData replaceBytesInRange:NSMakeRange(9, lengthDiff) withBytes:lowData.bytes];
            
            uint8_t hmacBytes[CC_SHA1_DIGEST_LENGTH];
            CCHmac(kCCHmacAlgSHA1, _hmacKey.bytes, _hmacKey.length, mutData.bytes, mutData.length, hmacBytes);
            NSData *checkData = [NSData dataWithBytes:hmacBytes length:_hmacLength];
            return [highData isEqualToData:checkData];
        }
    }
    return NO;
}

// MARK: - Coding

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        _deviceID   = [aDecoder decodeObjectForKey:kYTApiaryDeviceCryptoDeviceIdKey];
        _deviceKey  = [aDecoder decodeObjectForKey:kYTApiaryDeviceCryptoDeviceKeyKey];
        _projectKey = [aDecoder decodeObjectForKey:kYTDeviceCryptoProjectKeyKey];
        _hmacKey    = [aDecoder decodeObjectForKey:kYTDeviceCryptoHMACKeyKey];
        /* Original uses decodeIntForKey, which is not optimal here */
        _hmacLength = [aDecoder decodeIntegerForKey:kYTDeviceCryptoHMACLengthKey];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_deviceID    forKey:kYTApiaryDeviceCryptoDeviceIdKey];
    [aCoder encodeObject:_deviceKey   forKey:kYTApiaryDeviceCryptoDeviceKeyKey];
    [aCoder encodeObject:_projectKey  forKey:kYTDeviceCryptoProjectKeyKey];
    [aCoder encodeObject:_hmacKey     forKey:kYTDeviceCryptoHMACKeyKey];
    [aCoder encodeInteger:_hmacLength forKey:kYTDeviceCryptoHMACLengthKey];
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

@end

// MARK: -
@implementation NSError (LMNetCryptoError)

+ (instancetype)netCryptoErrorWithMessage:(NSString *)message {
    return [NSError errorWithDomain:@"com.google.ios.youtube.Net.ErrorDomain" code:0 userInfo:@{
        @"message" : message
    }];
}

@end
