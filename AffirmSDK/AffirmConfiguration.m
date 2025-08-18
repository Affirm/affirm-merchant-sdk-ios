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
                    countryCode:(NSString *)countryCode
                      currency:(NSString *)currency
                  merchantName:(NSString * _Nullable )merchantName
{
    self.publicKey = [publicKey copy];
    self.environment = environment;
    self.locale = locale;
    self.countryCode = countryCode;
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

- (NSString *)promosURL
{
    switch (self.environment) {
        case AffirmEnvironmentSandbox:
            if ([self.countryCode isEqualToString:@"CAN"]) {
                return AFFIRM_PROMOS_CA_SANDBOX_URL;
            } else if ([self.countryCode isEqualToString:@"GBR"]) {
                return AFFIRM_PROMOS_UK_SANDBOX_URL;
            }
            return AFFIRM_PROMOS_US_SANDBOX_URL;
        case AffirmEnvironmentProduction:
            if ([self.countryCode isEqualToString:@"CAN"]) {
                return AFFIRM_PROMOS_CA_PRODUCTION_URL;
            } else if ([self.countryCode isEqualToString:@"GBR"]) {
                return AFFIRM_PROMOS_UK_PRODUCTION_URL;
            }
            return AFFIRM_PROMOS_US_PRODUCTION_URL;
    }
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
    if ([self.countryCode isEqualToString:@"CAN"]) {
        return AFFIRM_TRACKER_CA_URL;
    } else if ([self.countryCode isEqualToString:@"GBR"]) {
        return AFFIRM_TRACKER_UK_URL;
    }
    return AFFIRM_TRACKER_US_URL;
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
    NSArray *urls = @[AFFIRM_PROMOS_US_SANDBOX_URL, AFFIRM_PROMOS_US_PRODUCTION_URL, AFFIRM_PROMOS_CA_SANDBOX_URL, AFFIRM_PROMOS_CA_PRODUCTION_URL, AFFIRM_PROMOS_UK_SANDBOX_URL, AFFIRM_PROMOS_UK_PRODUCTION_URL];
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
