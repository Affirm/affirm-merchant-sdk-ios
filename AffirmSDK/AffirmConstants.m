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

NSString *const AFFIRM_PREQUAL_REFERRING_URL = @"https://iossdk/";
NSString *const AFFIRM_CHECKOUT_CONFIRMATION_URL = @"affirm://checkout/confirmed";
NSString *const AFFIRM_CHECKOUT_CANCELLATION_URL = @"affirm://checkout/cancelled";
NSString *const AFFIRM_JS_URL = @"https://cdn1.affirm.com/js/v2/affirm.js";
NSString *const AFFIRM_SANDBOX_JS_URL = @"https://cdn1-sandbox.affirm.com/js/v2/affirm.js";

