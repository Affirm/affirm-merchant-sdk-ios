//
//  AffirmPromoModalViewController.h
//  AffirmSDK
//
//  Created by yijie on 2019/3/13.
//  Copyright © 2019 Affirm, Inc. All rights reserved.
//

#import "AffirmBaseWebViewController.h"
#import "AffirmPrequalDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface AffirmPromoModalViewController : AffirmBaseWebViewController

@property (nonatomic, weak) id<AffirmPrequalDelegate> delegate;

- (instancetype)initWithPromoId:(nullable NSString *)promoId
                         amount:(NSDecimalNumber *)amount
                       delegate:(id<AffirmPrequalDelegate>)delegate
NS_SWIFT_NAME(init(promoId:amount:delegate:)) NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil
                         bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
