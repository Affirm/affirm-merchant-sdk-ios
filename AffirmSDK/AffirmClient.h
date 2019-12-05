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

@protocol AffirmRequestProtocol <NSObject>

- (NSString *)path;
- (AffirmHTTPMethod)method;
- (NSDictionary *)parameters;

@optional
- (Class)responseClass;

@optional
- (NSDictionary *)headers;

@end

@protocol AffirmResponseProtocol <NSObject>

@optional
+ (id <AffirmResponseProtocol>)parse:(NSData *)data;
+ (nullable id <AffirmResponseProtocol>)parseError:(NSData *)data;

@end

typedef void (^AffirmRequestHandler)(id <AffirmResponseProtocol> _Nullable response, NSError * _Nullable error);

@protocol AffirmClientProtocol <NSObject>

+ (NSString *)host;
@optional
+ (void)send:(id <AffirmRequestProtocol>)request handler:(AffirmRequestHandler)handler;

@end

@interface AffirmTrackerClient : NSObject <AffirmClientProtocol>
@end

@interface AffirmPromoClient : NSObject <AffirmClientProtocol>

@end

@interface AffirmCheckoutClient : NSObject <AffirmClientProtocol>
@end

NS_ASSUME_NONNULL_END
