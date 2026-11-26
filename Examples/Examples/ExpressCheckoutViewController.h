//
//  ExpressCheckoutViewController.h
//  Examples
//
//  Copyright © 2026 Affirm, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Starts an Express Checkout from AffirmCheckoutButton: one button with the default style and one
/// whose size, theme, shape, text and width can be switched.
@interface ExpressCheckoutViewController : UIViewController

- (instancetype)initWithAmount:(NSDecimalNumber *)amount NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
