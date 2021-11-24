//
//  AffirmRequest.m
//  AffirmSDK
//
//  Created by Victor Zhu on 2019/3/15.
//  Copyright © 2019 Affirm, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AffirmRequest.h"
#import "AffirmConfiguration.h"
#import "AffirmCheckout.h"
#import "AffirmItem.h"

@implementation AffirmLogRequest

- (instancetype)initWithEventName:(NSString *)eventName
                  eventParameters:(NSDictionary *)eventParameters
                         logCount:(NSInteger)logCount
{
    if (self = [super init]) {
        _eventName = [eventName copy];
        _eventParameters = [eventParameters copy];
        _logCount = logCount;
    }
    return self;
}

- (NSString *)path
{
    return @"/collect";
}

- (AffirmHTTPMethod)method
{
    return AffirmHTTPMethodPOST;
}

- (NSDictionary *)parameters
{
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithDictionary:self.eventParameters];
    [parameters addEntriesFromDictionary:@{
                                           @"app_id": @"iOS SDK",
                                           @"device_type": [UIDevice currentDevice].model,
                                           @"release": [AffirmConfiguration affirmSDKVersion],
                                           @"app_name": [AffirmConfiguration sharedInstance].merchantName ?: @"",
                                           @"environment": [AffirmConfiguration sharedInstance].environmentDescription,
                                           @"ts": @([NSDate date].timeIntervalSince1970 * 1000),
                                           @"event_name": self.eventName,
                                           @"local_log_counter": @(self.logCount)
                                           }];
    return parameters;
}

@end

@implementation AffirmPromoRequest

- (instancetype)initWithPublicKey:(NSString *)publicKey
                          promoId:(NSString *)promoId
                           amount:(NSDecimalNumber *)amount
                          showCTA:(BOOL)showCTA
                         pageType:(nullable NSString *)pageType
                         logoType:(nullable NSString *)logoType
                        logoColor:(nullable NSString *)logoColor
{
    if (self = [super init]) {
        _publicKey = [publicKey copy];
        _promoId = [promoId copy];
        _amount = [amount copy];
        _showCTA = showCTA;
        _pageType = [pageType copy];
        _logoType = [logoType copy];
        _logoColor = [logoColor copy];
    }
    return self;
}


- (instancetype)initWithPublicKey:(NSString *)publicKey
                          promoId:(NSString *)promoId
                           amount:(NSDecimalNumber *)amount
                          showCTA:(BOOL)showCTA
                         pageType:(nullable NSString *)pageType
                         logoType:(nullable NSString *)logoType
                        logoColor:(nullable NSString *)logoColor
                            items:(nullable NSArray <AffirmItem *>*)items
{
    if (self = [super init]) {
        _publicKey = [publicKey copy];
        _promoId = [promoId copy];
        _amount = [amount copy];
        _showCTA = showCTA;
        _pageType = [pageType copy];
        _logoType = [logoType copy];
        _logoColor = [logoColor copy];
        _items = [[NSArray alloc] initWithArray:items copyItems:YES];
    }
    return self;
}

- (NSString *)path
{
    return [NSString stringWithFormat:@"/api/promos/v2/%@", self.publicKey];
}

- (AffirmHTTPMethod)method
{
    return AffirmHTTPMethodGET;
}

- (NSDictionary *)parameters
{
    NSMutableDictionary *_parameters = [@{@"is_sdk": @"true",
                                          @"field": @"ala",
                                          @"show_cta": self.showCTA ? @"true" : @"false",
                                          @"amount": self.amount.stringValue
                                          } mutableCopy];
    if (self.promoId) {
        _parameters[@"promo_external_id"] = self.promoId;
    }
    if (self.pageType) {
        _parameters[@"page_type"] = self.pageType;
    }
    if (self.logoType) {
        _parameters[@"logo_type"] = self.logoType;
    }
    if (self.logoColor) {
        _parameters[@"logo_color"] = self.logoColor;
    }
    if (self.items) {
        NSMutableArray *items = [[NSMutableArray alloc] init];
        for (AffirmItem *item in self.items) {
            [items addObject:[item toJSONDictionary]];
        }
        _parameters[@"items"] = items;
    }
    return _parameters;
}

- (Class)responseClass
{
    return AffirmPromoResponse.class;
}

@end

@implementation AffirmCheckoutRequest

- (instancetype)initWithPublicKey:(NSString *)publicKey
                         checkout:(AffirmCheckout *)checkout
                           useVCN:(BOOL)useVCN
                   cardAuthWindow:(NSInteger)cardAuthWindow
{
    if (self = [super init]) {
        _publicKey = [publicKey copy];
        _checkout = [checkout copy];
        _useVCN = useVCN;
        _cardAuthWindow = cardAuthWindow;
    }
    return self;
}

- (NSString *)path
{
    return @"/api/v2/checkout/";
}

- (AffirmHTTPMethod)method
{
    return AffirmHTTPMethodPOST;
}

- (NSDictionary *)parameters
{
    NSMutableDictionary *checkout = [self.checkout toJSONDictionary];
    NSDictionary *data = [checkout objectForKey: @"metadata"];
    NSMutableDictionary *metaData = data ? [data mutableCopy] : [[NSMutableDictionary alloc] init];
    [metaData setValue:@"Affirm iOS SDK" forKey:@"platform_type"];
    [metaData setValue:[AffirmConfiguration affirmSDKVersion] forKey:@"platform_affirm"];
    NSMutableDictionary *merchant = [@{
        @"name": [AffirmConfiguration sharedInstance].merchantName ?: @"",
        @"public_api_key": self.publicKey,
        @"user_confirmation_url": AFFIRM_CHECKOUT_CONFIRMATION_URL,
        @"user_cancel_url": AFFIRM_CHECKOUT_CANCELLATION_URL,
        @"user_confirmation_url_action": @"GET",
        @"use_vcn": @(self.useVCN)
    } mutableCopy];
    if (self.checkout.caas) {
        merchant[@"caas"] = self.checkout.caas;
    }
    if (self.cardAuthWindow > 0) {
        merchant[@"card_auth_window"] = @(self.cardAuthWindow);
    }
    [checkout addEntriesFromDictionary:@{
        @"merchant": merchant,
        @"metadata": metaData
    }];
    return @{@"checkout": checkout};
}

- (Class)responseClass
{
    return AffirmCheckoutResponse.class;
}

@end

@implementation AffirmPromoResponse

- (instancetype)initWithAla:(NSString *)ala
                    htmlAla:(NSString *)htmlAla
                showPrequal:(BOOL)showPrequal
{
    if (self = [super init]) {
        _ala = [ala copy];
        _htmlAla = [htmlAla copy];
        _showPrequal = showPrequal;
    }
    return self;
}

+ (AffirmResponse *)parse:(NSData *)data
{
    NSError *error = nil;
    id responseObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    NSString *ala = (NSString *)[responseObject valueForKeyPath:@"promo.ala"];
    ala = [ala stringByReplacingOccurrencesOfString:@"{affirm_logo}" withString:@"Affirm"];
    NSString *htmlAla = [responseObject valueForKeyPath:@"promo.html_ala"];
    NSString *style = [responseObject valueForKeyPath:@"promo.config.promo_style"];
    BOOL showPrequal = ![style isEqualToString:@"fast"];
    return [[AffirmPromoResponse alloc] initWithAla:ala htmlAla:htmlAla showPrequal:showPrequal];
}

@end

@implementation AffirmCheckoutResponse

- (instancetype)initWithRedirectURL:(NSURL *)redirectURL
{
    if (self = [super init]) {
        _redirectURL = [redirectURL copy];
    }
    return self;
}

- (NSDictionary *)dictionary
{
    return @{@"redirect_url": self.redirectURL};
}

+ (AffirmResponse *)parse:(NSData *)data
{
    NSError *error = nil;
    id responseObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    NSString *redirectUrl = [responseObject valueForKey:@"redirect_url"];
    return [[AffirmCheckoutResponse alloc] initWithRedirectURL:[NSURL URLWithString:redirectUrl]];
}

@end

@implementation AffirmErrorResponse

- (instancetype)initWithMessage:(NSString *)message
                           code:(NSString *)code
                           type:(NSString *)type
                     statusCode:(NSNumber *)statusCode
{
    if (self = [super init]) {
        _message = [message copy];
        _code = [code copy];
        _type = [type copy];
        _statusCode = [statusCode copy];
    }
    return self;
}

- (NSDictionary *)dictionary
{
    return @{
             @"message": self.message,
             @"code": self.code ?: @"",
             @"type": self.type,
             @"statusCode": self.statusCode,
             };
}

@end
