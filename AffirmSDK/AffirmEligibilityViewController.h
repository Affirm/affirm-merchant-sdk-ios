//
//  AffirmEligibilityViewController.h
//  AffirmSDK
//
//  Created by Victor Zhu on 2020/9/21.
//  Copyright © 2020 Affirm, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AffirmCheckout;
@protocol AffirmCheckoutDelegate;

NS_ASSUME_NONNULL_BEGIN

@interface AffirmEligibilityViewController : UIViewController

/**
 The delegate which handles checkout events.
 */
@property (nonatomic, weak) id<AffirmCheckoutDelegate> delegate;

/**
 The checkout object used to start the checkout process.
 */
@property (nonatomic, copy, readonly) AffirmCheckout *checkout;

/**
 Get Reason Codes
 */
@property (nonatomic, readonly) BOOL getReasonCodes;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil
                         bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;

/**
 Convenience constructor starts the checkout process and notifies delegate regarding checkout events
 
 @param checkout A checkout object which contains information about the customer and the purchase.
 @param getReasonCodes A boolean which determines whether to return the reason why the checkout was canceled.
 @param delegate A delegate object which responds to the checkout events created by the view controller.
 @return The newly created navigation controller with checkout view controller.
 */
+ (UINavigationController *)startCheckoutWithNavigation:(AffirmCheckout *)checkout
                                         getReasonCodes:(BOOL)getReasonCodes
                                               delegate:(nonnull id<AffirmCheckoutDelegate>)delegate
NS_SWIFT_NAME(startNavigation(checkout:getReasonCodes:delegate:));

@end

NS_ASSUME_NONNULL_END
