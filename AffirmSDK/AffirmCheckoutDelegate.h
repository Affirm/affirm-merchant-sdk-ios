//
//  AffirmCheckoutDelegate.h
//  AffirmSDK
//
//  Created by Paul on 3/18/19.
//  Copyright © 2019 Affirm, Inc. All rights reserved.
//

@class AffirmCheckoutViewController;
@class AffirmCreditCard;
@class AffirmReasonCode;

NS_ASSUME_NONNULL_BEGIN

/**
 A delegate which handles checkout events.
 */
@protocol AffirmCheckoutDelegate <NSObject>

/**
 This method is called when the user has completed the checkout.
 It should be forwarded to your server, which should then authorize it with Affirm and create a charge.

 @param checkoutViewController The checkoutViewController that manages the checkout process.
 @param checkoutToken This token represents the completed checkout.
 */
- (void)checkout:(AffirmCheckoutViewController *)checkoutViewController completedWithToken:(NSString *)checkoutToken;

/**
 This method is called when the user has completed the vcn checkout.
 It should use the debit card information to fill out the checkout page and submit.

 @param checkoutViewController The checkoutViewController that manages the vcn checkout process.
 @param creditCard This credit card info represents the completed vcn checkout.
 */
- (void)vcnCheckout:(UIViewController *)checkoutViewController completedWithCreditCard:(AffirmCreditCard *)creditCard;

/**
 This method is called when the user has cancelled the checkout.

 @param checkoutViewController The checkoutViewController that manages the checkout process.
 */
- (void)checkoutCancelled:(UIViewController *)checkoutViewController;

/**
 This method is called when the user has completed the vcn checkout.
 It should use the debit card information to fill out the checkout page and submit.
 
 @param checkoutViewController The checkoutViewController that manages the vcn checkout process.
 @param reasonCode This reasonCode represents the reason why the checkout was canceled.
 */
- (void)checkoutCancelled:(AffirmCheckoutViewController *)checkoutViewController checkoutCanceledWithReason:(AffirmReasonCode *)reasonCode;

/**
 This method is called when checkout creation has failed.

 @param checkoutViewController The checkoutViewController that manages the checkout process.
 @param error Checkout error
 */
- (void)checkout:(AffirmCheckoutViewController *)checkoutViewController didFailWithError:(NSError *)error;

@end

NS_ASSUME_NONNULL_END
