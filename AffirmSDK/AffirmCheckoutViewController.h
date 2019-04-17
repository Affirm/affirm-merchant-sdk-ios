//
//  AffirmCheckoutViewController.h
//  AffirmSDK
//
//  Created by Paul on 3/18/19.
//  Copyright © 2019 Affirm, Inc. All rights reserved.
//

#import "AffirmBaseWebViewController.h"

@class AffirmCheckout;
@class AffirmConfiguration;
@protocol AffirmCheckoutDelegate;

NS_ASSUME_NONNULL_BEGIN

@interface AffirmCheckoutViewController : AffirmBaseWebViewController

/**
 The delegate which handles checkout events.
 */
@property (nonatomic, weak) id<AffirmCheckoutDelegate> delegate;

/**
 The checkout object used to start the checkout process.
 */
@property (nonatomic, copy, readonly) AffirmCheckout *checkout;

/**
 Use VCN Checkout
 */
@property (nonatomic, readonly) BOOL useVCN;

/**
 The checkout identifier.
 */
@property (nonatomic, copy, readonly) NSString *checkoutARI;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil
                         bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;

/**
 Initializer. See properties for more details. UseVCN is NO as default

 @param delegate A delegate object which responds to the checkout events created by the view controller.
 @param checkout A checkout object which contains information about the customer and the purchase.
 @param useVCN A boolean which determines whether the checkout flow should use virtual card network to handle the checkout
 @return The newly created checkout view controller.
 */
- (instancetype)initWithDelegate:(id<AffirmCheckoutDelegate>)delegate
                        checkout:(AffirmCheckout *)checkout
                          useVCN:(BOOL)useVCN
NS_SWIFT_NAME(init(delegate:checkout:useVCN:)) NS_DESIGNATED_INITIALIZER;

/**
 Convenience constructor starts the checkout process and notifies delegate regarding checkout events, useVCN is NO as default

 @param checkout A checkout object which contains information about the customer and the purchase.
 @param delegate A delegate object which responds to the checkout events created by the view controller.
 @return The newly created checkout view controller.
 */
+ (AffirmCheckoutViewController *)startCheckout:(AffirmCheckout *)checkout
                                       delegate:(id<AffirmCheckoutDelegate>)delegate
NS_SWIFT_NAME(start(checkout:delegate:));

/**
 Convenience constructor starts the checkout process and notifies delegate regarding checkout events

 @param checkout A checkout object which contains information about the customer and the purchase.
 @param useVCN A boolean which determines whether the checkout flow should use virtual card network to handle the checkout
 @param delegate A delegate object which responds to the checkout events created by the view controller.
 @return The newly created checkout view controller.
 */
+ (AffirmCheckoutViewController *)startCheckout:(AffirmCheckout *)checkout
                                         useVCN:(BOOL)useVCN
                                       delegate:(id<AffirmCheckoutDelegate>)delegate
NS_SWIFT_NAME(start(checkout:useVCN:delegate:));

@end

NS_ASSUME_NONNULL_END
