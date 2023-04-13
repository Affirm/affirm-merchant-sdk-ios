//
//  AffirmConfiguration.m
//  AffirmSDK
//
//  Created by Victor Zhu on 2019/3/18.
//  Copyright © 2019 Affirm, Inc. All rights reserved.
//

#import "AffirmConfiguration.h"
#import "AffirmUtils.h"
#import "AffirmLogger.h"
#import <WebKit/WebKit.h>
#import "AffirmFontLoader.h"
#import "AffirmCreditCard.h"

@interface AffirmConfiguration ()

@property (nonatomic, copy, readwrite) NSString *publicKey, *countryCode, *currency;
@property (nonatomic, readwrite) AffirmEnvironment environment;
@property (nonatomic, readwrite) NSString *locale;
@property (nonatomic, copy, readwrite, nullable) NSString *merchantName;
@property (nonatomic, strong, readwrite) WKProcessPool *pool;
@property (nonatomic, strong, readwrite, nullable) AffirmCreditCard *creditCard;

@end

@implementation AffirmConfiguration

+ (instancetype)sharedInstance
{
    static AffirmConfiguration *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    return _sharedInstance;
}

+ (void)initialize
{
    if (self == [AffirmConfiguration class]) {
        [AffirmFontLoader loadFontIfNeeded];
    }
}

- (instancetype)init
{
    if (self = [super init]) {
        _environment = AffirmEnvironmentSandbox;
        _locale = AFFIRM_DEFAULT_LOCALE;
        _countryCode = AFFIRM_DEFAULT_COUNTRY_CODE;
        _currency = AFFIRM_DEFAULT_CURRENCY;
    }
    return self;
}

- (WKProcessPool *)pool
{
    if (!_pool) {
        _pool = [WKProcessPool new];
    }
    return _pool;
}

- (void)configureWithPublicKey:(NSString *)publicKey
                   environment:(AffirmEnvironment)environment
{
    [self configureWithPublicKey:publicKey
                     environment:environment
                    merchantName:nil];
}

- (void)configureWithPublicKey:(NSString *)publicKey
                   environment:(AffirmEnvironment)environment
                  merchantName:(NSString * _Nullable )merchantName
{
    self.publicKey = [publicKey copy];
    self.environment = environment;
    self.merchantName = [merchantName copy];
}

- (void)configureWithPublicKey:(NSString *)publicKey
                   environment:(AffirmEnvironment)environment
                        locale:(NSString *)locale
                    coutryCode:(NSString *)coutryCode
                      currency:(NSString *)currency
                  merchantName:(NSString * _Nullable )merchantName
{
    self.publicKey = [publicKey copy];
    self.environment = environment;
    self.locale = locale;
    self.countryCode = coutryCode;
    self.currency = currency;
    self.merchantName = [merchantName copy];
}

- (BOOL)isProductionEnvironment
{
    return self.environment == AffirmEnvironmentProduction;
}

- (NSString *)publicKey
{
    if (_publicKey == nil) {
        return @"";
    }
    return _publicKey;
}

+ (NSString *)affirmSDKVersion
{
    return [[NSBundle resourceBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
}

- (NSString *)jsURL
{
    switch (self.environment) {
        case AffirmEnvironmentSandbox:
            return AFFIRM_JS_SANDBOX_URL;
        case AffirmEnvironmentProduction:
            return AFFIRM_JS_PRODUCTION_URL;
    }
}

- (NSString *)promosDomain
{
    if ([self.countryCode isEqualToString:@"CAN"]) {
        return AFFIRM_PROMOS_CA_DOMAIN;
    }
    return AFFIRM_PROMOS_US_DOMAIN;
}

- (NSString *)promosURL
{
    NSString *prefix = self.isProductionEnvironment ? @"www" : @"sandbox";
    return [NSString stringWithFormat:@"https://%@.%@", prefix, self.promosDomain];
}

- (NSString *)checkoutURL
{
    switch (self.environment) {
        case AffirmEnvironmentSandbox:
            return AFFIRM_CHECKOUT_SANDBOX_URL;
        case AffirmEnvironmentProduction:
            return AFFIRM_CHECKOUT_PRODUCTION_URL;
    }
}

- (NSString *)trackerURL
{
    return [NSString stringWithFormat:@"https://tracker.%@", self.promosDomain];
}

- (NSString *)environmentDescription
{
    switch(self.environment) {
        case AffirmEnvironmentProduction:
            return @"production";
        case AffirmEnvironmentSandbox:
            return @"sandbox";
    }
}

- (BOOL)isCreditCardExists
{
    return self.creditCard != nil;
}

- (void)updateCreditCard:(nullable AffirmCreditCard *)creditCard
{
    self.creditCard = creditCard;
}

+ (NSArray <NSHTTPCookie *> *)cookiesForAffirm
{
    NSMutableArray *ownedCookies = [NSMutableArray array];
    NSArray *cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage].cookies;
    NSArray *urls = @[AFFIRM_PROMOS_US_DOMAIN, AFFIRM_PROMOS_CA_DOMAIN];
    for (NSHTTPCookie *cookie in cookies) {
        for (NSString *url in urls) {
            if ([cookie.domain rangeOfString:url].location != NSNotFound) {
                [ownedCookies addObject:cookie];
            }
        }
    }
    return ownedCookies;
}

+ (void)deleteAffirmCookies
{
    NSArray *cookies = [self cookiesForAffirm];
    for (NSHTTPCookie *cookie in cookies) {
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
    }
    if (@available(iOS 11.0, *)) {
        WKWebsiteDataStore *dataStore = [WKWebsiteDataStore defaultDataStore];
        [dataStore fetchDataRecordsOfTypes:WKWebsiteDataStore.allWebsiteDataTypes completionHandler:^(NSArray<WKWebsiteDataRecord *> *records) {
            for (WKWebsiteDataRecord *record in records) {
                [dataStore removeDataOfTypes:WKWebsiteDataStore.allWebsiteDataTypes forDataRecords:@[record] completionHandler:^{
                }];
            }
        }];
    }
    [AffirmConfiguration sharedInstance].pool = nil;
}

@end
