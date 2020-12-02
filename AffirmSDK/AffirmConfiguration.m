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

@property (nonatomic, copy, readwrite) NSString *publicKey;
@property (nonatomic, readwrite) AffirmEnvironment environment;
@property (nonatomic, readwrite) AffirmLocale locale;
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
        _locale = AffirmLocaleUS;
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
                        locale:(AffirmLocale)locale
                  merchantName:(NSString * _Nullable )merchantName
{
    self.publicKey = [publicKey copy];
    self.environment = environment;
    self.locale = locale;
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

- (NSString *)currency
{
    switch (self.locale) {
        case AffirmLocaleUS:
            return @"USD";
        case AffirmLocaleCA:
            return @"CAD";
    }
}

+ (NSString *)affirmSDKVersion
{
    return [[NSBundle resourceBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
}

- (NSString *)domain
{
    switch (self.locale) {
        case AffirmLocaleUS:
            return AFFIRM_US_DOMAIN;
        case AffirmLocaleCA:
            return AFFIRM_CA_DOMAIN;
    }
}

- (NSString *)jsURL
{
    switch (self.environment) {
        case AffirmEnvironmentSandbox:
            return [NSString stringWithFormat:@"https://cdn1-sandbox.%@/js/v2/affirm.js", self.domain];
        case AffirmEnvironmentProduction:
            return [NSString stringWithFormat:@"https://cdn1.%@/js/v2/affirm.js", self.domain];
    }
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
    for (NSHTTPCookie *cookie in cookies) {
        if ([cookie.domain rangeOfString:[AffirmConfiguration sharedInstance].domain].location != NSNotFound) {
            [ownedCookies addObject:cookie];
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
