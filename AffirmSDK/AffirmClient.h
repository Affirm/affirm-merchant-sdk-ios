//
//  AffirmClient.h
//  AffirmSDK
//
//  Created by Victor Zhu on 2019/3/18.
//  Copyright © 2019 Affirm, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    AffirmHTTPMethodGET,
    AffirmHTTPMethodPOST,
} AffirmHTTPMethod;

@interface AffirmRequest : NSObject

- (NSString *)path;
- (AffirmHTTPMethod)method;
- (NSDictionary *)parameters;
- (Class)responseClass;
- (NSDictionary *)headers;

@end

@interface AffirmResponse : NSObject

+ (AffirmResponse *)parse:(NSData *)data;
+ (nullable AffirmResponse *)parseError:(NSData *)data;

@end

typedef void (^AffirmRequestHandler)(AffirmResponse * _Nullable response, NSError * _Nullable error);

@interface AffirmClient : NSObject

+ (NSString *)host;
+ (void)send:(AffirmRequest *)request handler:(AffirmRequestHandler)handler;

@end

@interface AffirmTrackerClient : AffirmClient
@end

@interface AffirmPromoClient : AffirmClient
@end

@interface AffirmCheckoutClient : AffirmClient
@end

NS_ASSUME_NONNULL_END
