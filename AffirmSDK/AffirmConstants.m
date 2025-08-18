//
//  AffirmConstants.m
//  AffirmSDK
//
//  Created by Victor Zhu on 2019/3/14.
//  Copyright © 2019 Affirm, Inc. All rights reserved.
//

#import "AffirmConstants.h"

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0

NSErrorDomain const AffirmSDKErrorDomain = @"com.affirm.sdk";

#else

NSString *const AffirmSDKErrorDomain = @"com.affirm.sdk";

#endif

NSString *const AFFIRM_DEFAULT_LOCALE = @"en_US";
NSString *const AFFIRM_DEFAULT_COUNTRY_CODE = @"USA";
NSString *const AFFIRM_DEFAULT_CURRENCY = @"USD";

// Global Affirm JS URL
NSString *const AFFIRM_JS_SANDBOX_URL = @"https://cdn1-sandbox.affirm.com/js/v2/affirm.js";
NSString *const AFFIRM_JS_PRODUCTION_URL = @"https://cdn1.affirm.com/js/v2/affirm.js";

// Global Checkout URL
NSString *const AFFIRM_CHECKOUT_SANDBOX_URL = @"https://api.global-sandbox.affirm.com";
NSString *const AFFIRM_CHECKOUT_PRODUCTION_URL = @"https://api.global.affirm.com";

// Promos & Prequal URL
NSString *const AFFIRM_PROMOS_US_SANDBOX_URL = @"https://sandbox.affirm.com";
NSString *const AFFIRM_PROMOS_US_PRODUCTION_URL = @"https://www.affirm.com";

NSString *const AFFIRM_PROMOS_CA_SANDBOX_URL = @"https://sandbox.affirm.ca";
NSString *const AFFIRM_PROMOS_CA_PRODUCTION_URL = @"https://www.affirm.ca";

NSString *const AFFIRM_PROMOS_UK_SANDBOX_URL = @"https://sandbox.uk.affirm.com";
NSString *const AFFIRM_PROMOS_UK_PRODUCTION_URL = @"https://api.uk.affirm.com";

// Tracker
NSString *const AFFIRM_TRACKER_US_URL = @"https://tracker.affirm.com";
NSString *const AFFIRM_TRACKER_CA_URL = @"https://tracker.affirm.ca";
NSString *const AFFIRM_TRACKER_UK_URL = @"https://tracker.uk.affirm.com";

// App Scheme
NSString *const AFFIRM_PREQUAL_REFERRING_URL = @"https://iossdk/";
NSString *const AFFIRM_CHECKOUT_CONFIRMATION_URL = @"affirm://checkout/confirmed";
NSString *const AFFIRM_CHECKOUT_CANCELLATION_URL = @"affirm://checkout/cancelled";

NSString * FormatAffirmPageTypeString(AffirmPageType type)
{
    switch (type) {
        case AffirmPageTypeNone:
            return nil;
        case AffirmPageTypeBanner:
            return @"banner";
        case AffirmPageTypeCart:
            return @"cart";
        case AffirmPageTypeCategory:
            return @"category";
        case AffirmPageTypeHomepage:
            return @"homepage";
        case AffirmPageTypeLanding:
            return @"landing";
        case AffirmPageTypePayment:
            return @"payment";
        case AffirmPageTypeProduct:
            return @"product";
        case AffirmPageTypeSearch:
            return @"search";
    }
}

NSString * FormatAffirmColorString(AffirmColorType type)
{
    switch (type) {
        case AffirmColorTypeBlack:
            return @"black";
        case AffirmColorTypeWhite:
            return @"white";
        default:
            return @"blue-black";
    }
}
