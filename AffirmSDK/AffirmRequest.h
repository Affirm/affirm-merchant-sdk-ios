//
//  AffirmRequest.h
//  AffirmSDK
//
//  Created by Victor Zhu on 2019/3/15.
//  Copyright © 2019 Affirm, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AffirmClient.h"

@class AffirmItem, AffirmCheckout;

NS_ASSUME_NONNULL_BEGIN

@interface AffirmLogRequest : NSObject <AffirmRequestProtocol>

@property (nonatomic, readonly) NSInteger logCount;
@property (nonatomic, copy, readonly) NSDictionary *eventParameters;
@property (nonatomic, copy, readonly) NSString *eventName;

- (instancetype)initWithEventName:(NSString *)eventName
                  eventParameters:(NSDictionary *)eventParameters
                         logCount:(NSInteger)logCount;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

@interface AffirmPromoRequest : NSObject <AffirmRequestProtocol>

@property (nonatomic, copy, readonly) NSString *publicKey;
@property (nonatomic, copy, readonly) NSString *promoId;
@property (nonatomic, copy, readonly) NSDecimalNumber* amount;
@property (nonatomic, readonly) BOOL showCTA;
@property (nonatomic, copy, readonly, nullable) NSString *pageType;
@property (nonatomic, copy, readonly) NSString *logoType;
@property (nonatomic, copy, readonly) NSString *logoColor;
@property (nonatomic, copy, readonly) NSArray <AffirmItem *>*items;

- (instancetype)initWithPublicKey:(NSString *)publicKey
                          promoId:(NSString *)promoId
                           amount:(NSDecimalNumber *)amount
                          showCTA:(BOOL)showCTA
                         pageType:(nullable NSString *)pageType
                         logoType:(nullable NSString *)logoType
                        logoColor:(nullable NSString *)logoColor;
- (instancetype)initWithPublicKey:(NSString *)publicKey
                          promoId:(NSString *)promoId
                           amount:(NSDecimalNumber *)amount
                          showCTA:(BOOL)showCTA
                         pageType:(nullable NSString *)pageType
                         logoType:(nullable NSString *)logoType
                        logoColor:(nullable NSString *)logoColor
                            items:(nullable NSArray <AffirmItem *>*)items;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

@interface AffirmCheckoutRequest : NSObject <AffirmRequestProtocol>

@property (nonatomic, copy, readonly) NSString *publicKey;
@property (nonatomic, copy, readonly) AffirmCheckout *checkout;
@property (nonatomic, readonly) BOOL useVCN;
@property (nonatomic, readonly) NSInteger cardAuthWindow;

- (instancetype)initWithPublicKey:(NSString *)publicKey
                         checkout:(AffirmCheckout *)checkout
                           useVCN:(BOOL)useVCN
                   cardAuthWindow:(NSInteger)cardAuthWindow;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

@interface AffirmPromoResponse : NSObject <AffirmResponseProtocol>

@property (nonatomic, copy, readonly) NSString *htmlAla;
@property (nonatomic, copy, readonly) NSString *ala;
@property (nonatomic, readonly) BOOL showPrequal;

@end

@interface AffirmCheckoutResponse : NSObject <AffirmResponseProtocol>

@property (nonatomic, copy, readonly) NSURL *redirectURL;

- (NSDictionary *)dictionary;

@end

@interface AffirmErrorResponse : NSObject <AffirmResponseProtocol>

@property (nonatomic, copy, readonly) NSString *message;
@property (nonatomic, copy, readonly) NSString *code;
@property (nonatomic, copy, readonly) NSString *type;
@property (nonatomic, copy, readonly) NSNumber *statusCode;

- (instancetype)initWithMessage:(NSString *)message
                           code:(NSString *)code
                           type:(NSString *)type
                     statusCode:(NSNumber *)statusCode;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
- (NSDictionary *)dictionary;

@end

NS_ASSUME_NONNULL_END
