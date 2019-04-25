//
//  AffirmConfiguration.h
//  AffirmSDK
//
//  Created by Victor Zhu on 2019/3/18.
//  Copyright © 2019 Affirm, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "AffirmConstants.h"

NS_ASSUME_NONNULL_BEGIN

@interface AffirmConfiguration : NSObject

@property (nonatomic, copy, readonly) NSString *publicKey;
@property (nonatomic, readonly) AffirmEnvironment environment;
@property (nonatomic, copy, readonly, nullable) NSString *merchantName;
@property (nonatomic, readonly) BOOL isProductionEnvironment;
@property (nonatomic, strong, readonly) WKProcessPool *pool;

@property (class, nonatomic, readonly, strong) AffirmConfiguration *sharedInstance
NS_SWIFT_NAME(shared);

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (void)configureWithPublicKey:(NSString *)publicKey
                   environment:(AffirmEnvironment)environment
NS_SWIFT_NAME(configure(publicKey:environment:));

- (void)configureWithPublicKey:(NSString *)publicKey
                   environment:(AffirmEnvironment)environment
                  merchantName:(NSString * _Nullable )merchantName
NS_SWIFT_NAME(configure(publicKey:environment:merchantName:));

+ (NSString *)affirmSDKVersion;

- (NSString *)environmentDescription;

+ (NSArray <NSHTTPCookie *> *)cookiesForAffirm;

+ (void)deleteAffirmCookies;

@end

NS_ASSUME_NONNULL_END
