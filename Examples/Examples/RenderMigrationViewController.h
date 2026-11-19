//
//  RenderMigrationViewController.h
//  Examples
//
//  Copyright © 2026 Affirm, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Shows the native-to-HTML promo render migration: the same native configure call rendered as
/// native text or as HTML, with the promo response it was rendered from.
@interface RenderMigrationViewController : UIViewController

- (instancetype)initWithAmount:(NSDecimalNumber *)amount NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
