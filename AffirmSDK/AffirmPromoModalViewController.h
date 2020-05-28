//
//  AffirmPromoModalViewController.h
//  AffirmSDK
//
//  Created by yijie on 2019/3/13.
//  Copyright © 2019 Affirm, Inc. All rights reserved.
//

#import "AffirmBaseWebViewController.h"
#import "AffirmPrequalDelegate.h"
#import "AffirmConstants.h"

NS_ASSUME_NONNULL_BEGIN

@interface AffirmPromoModalViewController : AffirmBaseWebViewController

/**
 The delegate which handles promo modal events.
 */
@property (nonatomic, weak) id<AffirmPrequalDelegate> delegate;

/**
 Initializer. See properties for more details. UseVCN is NO as default
 
 @param promoId Promo ID to use when getting terms (provided by Affirm)
 @param amount Amount of the transaction
 @param delegate A delegate object which responds to the promo modal events created by the view controller.
 @return The newly created promo view controller.
 */
- (instancetype)initWithPromoId:(nullable NSString *)promoId
                         amount:(NSDecimalNumber *)amount
                       delegate:(id<AffirmPrequalDelegate>)delegate
NS_SWIFT_NAME(init(promoId:amount:delegate:)) NS_DESIGNATED_INITIALIZER;

/**
 Initializer. See properties for more details. UseVCN is NO as default
 
 @param promoId Promo ID to use when getting terms (provided by Affirm)
 @param amount Amount of the transaction
 @param pageType type of Affirm page to display
 @param delegate A delegate object which responds to the promo modal events created by the view controller.
 @return The newly created promo view controller.
 */
- (instancetype)initWithPromoId:(nullable NSString *)promoId
                         amount:(NSDecimalNumber *)amount
                       pageType:(AffirmPageType)pageType
                       delegate:(id<AffirmPrequalDelegate>)delegate
NS_SWIFT_NAME(init(promoId:amount:pageType:delegate:)) NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil
                         bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
