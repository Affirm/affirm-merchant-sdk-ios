//
//  AffirmCheckoutButton.h
//  AffirmSDK
//
//  Copyright © 2026 Affirm, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AffirmConstants.h"

NS_ASSUME_NONNULL_BEGIN

/**
 An AffirmCheckoutButton displays a pre-styled Affirm call-to-action.

 It does not initiate checkout — add a target for UIControlEventTouchUpInside. It does not disable itself either; set enabled to NO when starting checkout and back to YES when checkout ends. While disabled, it is drawn faded.

 Its height comes from size: 44pt for small, 48pt for medium and 64pt for large. If the text and logo are wider than the button, they shrink to fit on one line.
 */
@interface AffirmCheckoutButton : UIControl

/**
 The page the button is on, sent with the button's click tracking. Default is AffirmPageTypeNone.
 */
@property (nonatomic) IBInspectable AffirmPageType pageType;

/**
 Sets the height, font size and horizontal padding. Default is AffirmCheckoutButtonSizeMedium.
 */
@property (nonatomic) IBInspectable AffirmCheckoutButtonSize size;

/**
 Sets the fill, text and logo colors. Default is AffirmCheckoutButtonThemeDark.
 */
@property (nonatomic) IBInspectable AffirmCheckoutButtonTheme theme;

/**
 Sets the corner radius. Default is AffirmCheckoutButtonShapePill.
 */
@property (nonatomic) IBInspectable AffirmCheckoutButtonShape shape;

/**
 Sets the text next to the Affirm logo. Default is AffirmCheckoutButtonTextTypeBuyNow.
 */
@property (nonatomic) IBInspectable AffirmCheckoutButtonTextType buttonText;

/**
 YES to stretch to the width of the container, NO to size to the content. Default is NO.
 */
@property (nonatomic) IBInspectable BOOL fullWidth;

/**
 Creates a button with the default size, theme, shape and text.

 @param pageType The page the button is on.
 @param frame The frame of the button.
 @return The initialized button.
 */
- (instancetype)initWithPageType:(AffirmPageType)pageType
                           frame:(CGRect)frame
NS_SWIFT_NAME(init(pageType:frame:));

/**
 Creates a button. See properties for more details.

 @param pageType The page the button is on.
 @param size The size.
 @param theme The theme.
 @param shape The shape.
 @param buttonText The text.
 @param fullWidth Whether to stretch to the width of the container.
 @param frame The frame of the button.
 @return The initialized button.
 */
- (instancetype)initWithPageType:(AffirmPageType)pageType
                            size:(AffirmCheckoutButtonSize)size
                           theme:(AffirmCheckoutButtonTheme)theme
                           shape:(AffirmCheckoutButtonShape)shape
                      buttonText:(AffirmCheckoutButtonTextType)buttonText
                       fullWidth:(BOOL)fullWidth
                           frame:(CGRect)frame
NS_SWIFT_NAME(init(pageType:size:theme:shape:buttonText:fullWidth:frame:));

- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
