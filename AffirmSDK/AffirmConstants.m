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

NSString *const AFFIRM_US_DOMAIN = @"affirm.com";
NSString *const AFFIRM_CA_DOMAIN = @"affirm.ca";

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
        case AffirmColorTypeBlue:
            return @"blue";
        case AffirmColorTypeBlack:
            return @"black";
        case AffirmColorTypeWhite:
            return @"white";
        case AffirmColorTypeBlueBlack:
            return @"blue-black";
        case AffirmColorTypeDefault:
            return @"blue";
    }
}
