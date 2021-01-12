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
 Get Reason Codes
 */
@property (nonatomic, readonly) BOOL getReasonCodes;

/**
 The checkout identifier.
 */
@property (nonatomic, copy, readonly) NSString *checkoutARI;

/**
  Card auth window
 */
@property (nonatomic, readonly) NSInteger cardAuthWindow;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil
                         bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;

/**
 Initializer. See properties for more details. UseVCN is NO as default

 @param delegate A delegate object which responds to the checkout events created by the view controller.
 @param checkout A checkout object which contains information about the customer and the purchase.
 @param useVCN A boolean which determines whether the checkout flow should use virtual card network to handle the checkout.
 @param getReasonCodes A boolean which determines whether to return the reason why the checkout was canceled.
 @return The newly created checkout view controller.
 */
- (instancetype)initWithDelegate:(id<AffirmCheckoutDelegate>)delegate
                        checkout:(AffirmCheckout *)checkout
                          useVCN:(BOOL)useVCN
                  getReasonCodes:(BOOL)getReasonCodes
NS_SWIFT_NAME(init(delegate:checkout:useVCN:getReasonCodes:)) NS_DESIGNATED_INITIALIZER;

/**
 Initializer. See properties for more details. UseVCN is NO as default

 @param delegate A delegate object which responds to the checkout events created by the view controller.
 @param checkout A checkout object which contains information about the customer and the purchase.
 @param useVCN A boolean which determines whether the checkout flow should use virtual card network to handle the checkout.
 @param getReasonCodes A boolean which determines whether to return the reason why the checkout was canceled.
 @param cardAuthWindow A positive integer.
 @return The newly created checkout view controller.
 */
- (instancetype)initWithDelegate:(id<AffirmCheckoutDelegate>)delegate
                        checkout:(AffirmCheckout *)checkout
                          useVCN:(BOOL)useVCN
                  getReasonCodes:(BOOL)getReasonCodes
                  cardAuthWindow:(NSInteger)cardAuthWindow
NS_SWIFT_NAME(init(delegate:checkout:useVCN:getReasonCodes:cardAuthWindow:)) NS_DESIGNATED_INITIALIZER;

+ (UINavigationController *)startCheckoutWithNavigation:(AffirmCheckout *)checkout
                                                 useVCN:(BOOL)useVCN
                                         getReasonCodes:(BOOL)getReasonCodes
                                               delegate:(nonnull id<AffirmCheckoutDelegate>)delegate API_DEPRECATED("Use initWithDelegate:checkout:useVCN:getReasonCodes: instead.", ios(2.0, 14.0))
NS_SWIFT_NAME(startNavigation(checkout:useVCN:getReasonCodes:delegate:));

/**
 Convenience constructor starts the checkout process and notifies delegate regarding checkout events, useVCN is NO as default

 @param checkout A checkout object which contains information about the customer and the purchase.
 @param delegate A delegate object which responds to the checkout events created by the view controller.
 @return The newly created checkout view controller.
 */
+ (AffirmCheckoutViewController *)startCheckout:(AffirmCheckout *)checkout
                                       delegate:(id<AffirmCheckoutDelegate>)delegate API_DEPRECATED("Use initWithDelegate:checkout:useVCN:getReasonCodes: instead.", ios(2.0, 14.0))
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
                                       delegate:(id<AffirmCheckoutDelegate>)delegate API_DEPRECATED("Use initWithDelegate:checkout:useVCN:getReasonCodes: instead.", ios(2.0, 14.0))
NS_SWIFT_NAME(start(checkout:useVCN:delegate:));

/**
 Convenience constructor starts the checkout process and notifies delegate regarding checkout events
 
 @param checkout A checkout object which contains information about the customer and the purchase.
 @param useVCN A boolean which determines whether the checkout flow should use virtual card network to handle the checkout
 @param getReasonCodes A boolean which determines whether to return the reason code when a checkout is canceled
 @param delegate A delegate object which responds to the checkout events created by the view controller.
 @return The newly created checkout view controller.
 */
+ (AffirmCheckoutViewController *)startCheckout:(AffirmCheckout *)checkout
                                         useVCN:(BOOL)useVCN
                                 getReasonCodes:(BOOL)getReasonCodes
                                       delegate:(id<AffirmCheckoutDelegate>)delegate API_DEPRECATED("Use initWithDelegate:checkout:useVCN:getReasonCodes: instead.", ios(2.0, 14.0))
NS_SWIFT_NAME(start(checkout:useVCN:getReasonCodes:delegate:));

@end

NS_ASSUME_NONNULL_END
