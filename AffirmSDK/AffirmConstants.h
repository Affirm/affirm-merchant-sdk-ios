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

FOUNDATION_EXPORT NSString *const AFFIRM_US_DOMAIN;
FOUNDATION_EXPORT NSString *const AFFIRM_CA_DOMAIN;

FOUNDATION_EXPORT NSString *const AFFIRM_MAX_PROMO_AMOUNT;

FOUNDATION_EXPORT NSString *const AFFIRM_CHECKOUT_CONFIRMATION_URL;
FOUNDATION_EXPORT NSString *const AFFIRM_CHECKOUT_CANCELLATION_URL;
FOUNDATION_EXPORT NSString *const AFFIRM_PREQUAL_REFERRING_URL;

FOUNDATION_EXPORT NSString *const AffirmFontFamilyNameCalibre;
FOUNDATION_EXPORT NSString *const AffirmFontNameCalibreMedium;
FOUNDATION_EXPORT NSString *const AffirmFontNameCalibreBold;
FOUNDATION_EXPORT NSString *const AffirmFontNameCalibreSemibold;
FOUNDATION_EXPORT NSString *const AffirmFontNameCalibreRegular;

FOUNDATION_EXPORT NSString *const AffirmFontFamilyNameAlmaMono;
FOUNDATION_EXPORT NSString *const AffirmFontNameAlmaMonoBold;

typedef NS_ENUM(NSInteger, AffirmEnvironment) {
    AffirmEnvironmentProduction,
    AffirmEnvironmentSandbox
};

typedef NS_ENUM(NSInteger, AffirmLocale) {
    AffirmLocaleUS,
    AffirmLocaleCA
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

NSString * FormatAffirmPageTypeString(AffirmPageType type);
NSString * FormatAffirmColorString(AffirmColorType type);

NS_ASSUME_NONNULL_END
