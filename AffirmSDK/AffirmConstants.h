//
//  AffirmConstants.h
//  AffirmSDK
//
//  Created by Victor Zhu on 2019/3/14.
//  Copyright © 2019 Affirm, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0

FOUNDATION_EXPORT NSErrorDomain const AffirmSDKErrorDomain;

#else

FOUNDATION_EXPORT NSString *const AffirmSDKErrorDomain;

#endif

typedef NS_ERROR_ENUM(AffirmSDKErrorDomain, AffirmSDKError) {
    /// An Express Checkout is missing a required field. The description lists the missing fields.
    AffirmSDKErrorMissingExpressCheckoutFields = 1000,
};

FOUNDATION_EXPORT NSString *const AFFIRM_DEFAULT_LOCALE;
FOUNDATION_EXPORT NSString *const AFFIRM_DEFAULT_COUNTRY_CODE;
FOUNDATION_EXPORT NSString *const AFFIRM_DEFAULT_CURRENCY;

FOUNDATION_EXPORT NSString *const AFFIRM_JS_SANDBOX_URL;
FOUNDATION_EXPORT NSString *const AFFIRM_JS_PRODUCTION_URL;

FOUNDATION_EXPORT NSString *const AFFIRM_CHECKOUT_SANDBOX_URL;
FOUNDATION_EXPORT NSString *const AFFIRM_CHECKOUT_PRODUCTION_URL;

FOUNDATION_EXPORT NSString *const AFFIRM_PROMOS_US_SANDBOX_URL;
FOUNDATION_EXPORT NSString *const AFFIRM_PROMOS_US_PRODUCTION_URL;
FOUNDATION_EXPORT NSString *const AFFIRM_PROMOS_CA_SANDBOX_URL;
FOUNDATION_EXPORT NSString *const AFFIRM_PROMOS_CA_PRODUCTION_URL;
FOUNDATION_EXPORT NSString *const AFFIRM_PROMOS_UK_SANDBOX_URL;
FOUNDATION_EXPORT NSString *const AFFIRM_PROMOS_UK_PRODUCTION_URL;

FOUNDATION_EXPORT NSString *const AFFIRM_TRACKER_US_URL;
FOUNDATION_EXPORT NSString *const AFFIRM_TRACKER_CA_URL;
FOUNDATION_EXPORT NSString *const AFFIRM_TRACKER_UK_URL;

FOUNDATION_EXPORT NSString *const AFFIRM_CHECKOUT_CONFIRMATION_URL;
FOUNDATION_EXPORT NSString *const AFFIRM_CHECKOUT_CANCELLATION_URL;
FOUNDATION_EXPORT NSString *const AFFIRM_PREQUAL_REFERRING_URL;

typedef NS_ENUM(NSInteger, AffirmEnvironment) {
    AffirmEnvironmentProduction,
    AffirmEnvironmentSandbox
};

typedef NS_ENUM(NSInteger, AffirmPageType) {
    AffirmPageTypeNone,
    AffirmPageTypeBanner,
    AffirmPageTypeCart,
    AffirmPageTypeCategory,
    AffirmPageTypeHomepage,
    AffirmPageTypeLanding,
    AffirmPageTypePayment,
    AffirmPageTypeProduct,
    AffirmPageTypeSearch
};

typedef NS_ENUM(NSInteger, AffirmLogoType) {
    AffirmLogoTypeName,
    AffirmLogoTypeText,
    AffirmLogoTypeSymbol,
    AffirmLogoTypeSymbolHollow
};

typedef NS_ENUM(NSInteger, AffirmColorType) {
    AffirmColorTypeDefault,
    AffirmColorTypeBlue,
    AffirmColorTypeBlack,
    AffirmColorTypeWhite,
    AffirmColorTypeBlueBlack
};

typedef NS_ENUM(NSInteger, AffirmCheckoutButtonSize) {
    AffirmCheckoutButtonSizeSmall,
    AffirmCheckoutButtonSizeMedium,
    AffirmCheckoutButtonSizeLarge
};

typedef NS_ENUM(NSInteger, AffirmCheckoutButtonTheme) {
    AffirmCheckoutButtonThemeDark,
    AffirmCheckoutButtonThemeLight
};

typedef NS_ENUM(NSInteger, AffirmCheckoutButtonShape) {
    AffirmCheckoutButtonShapeSharp,
    AffirmCheckoutButtonShapePill,
    AffirmCheckoutButtonShapeRounded
};

typedef NS_ENUM(NSInteger, AffirmCheckoutButtonTextType) {
    AffirmCheckoutButtonTextTypeBuyNow,
    AffirmCheckoutButtonTextTypeCheckout,
    AffirmCheckoutButtonTextTypeLogoOnly
};

/// Checkout button colors, as 0xRRGGBB.
FOUNDATION_EXPORT const uint32_t AFFIRM_CHECKOUT_BUTTON_DARK_FILL_COLOR;
FOUNDATION_EXPORT const uint32_t AFFIRM_CHECKOUT_BUTTON_LIGHT_FILL_COLOR;
FOUNDATION_EXPORT const uint32_t AFFIRM_CHECKOUT_BUTTON_DARK_TEXT_COLOR;
FOUNDATION_EXPORT const uint32_t AFFIRM_CHECKOUT_BUTTON_LIGHT_TEXT_COLOR;

NSString * FormatAffirmPageTypeString(AffirmPageType type);
NSString * FormatAffirmColorString(AffirmColorType type);
NSString * AffirmCheckoutButtonAccessibilityLabel(AffirmCheckoutButtonTextType type);

NS_ASSUME_NONNULL_END
