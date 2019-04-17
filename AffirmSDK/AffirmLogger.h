//
//  AffirmLogger.h
//  AffirmSDK
//
//  Created by Victor Zhu on 2019/3/12.
//  Copyright © 2019 Affirm, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AffirmLogger : NSObject

@property (nonatomic) BOOL enableLogPrinted;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@property (class, nonatomic, readonly, strong) AffirmLogger *sharedInstance
NS_SWIFT_NAME(shared);

- (void)logException:(NSString *)message;
- (void)logEvent:(NSString *)name;
- (void)logEvent:(NSString *)name parameters:(NSDictionary *)parameters;
- (void)trackEvent:(NSString *)name;
- (void)trackEvent:(NSString *)name parameters:(NSDictionary * _Nonnull)parameters;

@end

NS_ASSUME_NONNULL_END
