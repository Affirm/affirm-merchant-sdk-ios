//
//  AppDelegate.m
//  Examples
//
//  Created by Victor Zhu on 2019/3/5.
//  Copyright © 2019 Affirm, Inc. All rights reserved.
//

#import "AppDelegate.h"
#import <AffirmSDK/AffirmSDK.h>
#import <objc/runtime.h>

// Sample-app-only routing for the live emulator suite. The SDK binary is unchanged.
#if DEBUG
@interface AffirmConfiguration (LivePromoTest)
- (NSString *)sdkLivePromoURL;
@end
@implementation AffirmConfiguration (LivePromoTest)
- (NSString *)sdkLivePromoURL
{
    NSString *url = [[NSProcessInfo processInfo] environment][@"AFFIRM_PROMO_BASE_URL"];
    return url.length > 0 ? url : [self sdkLivePromoURL];
}
@end
#endif

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
#if DEBUG
    NSDictionary *liveInputs = [[NSProcessInfo processInfo] environment];
    if ([liveInputs[@"AFFIRM_PROMO_BASE_URL"] length] > 0) {
        Method original = class_getInstanceMethod(AffirmConfiguration.class, @selector(promosURL));
        Method test = class_getInstanceMethod(AffirmConfiguration.class, @selector(sdkLivePromoURL));
        NSAssert(original != NULL && test != NULL, @"SDK promo URL routing is unavailable");
        method_exchangeImplementations(original, test);
    }
#endif
    // US sandbox publicKey: the previous GB key no longer works for this example.
    [[AffirmConfiguration sharedInstance] configureWithPublicKey:@"Y8CQXFF044903JC0"
                                                     environment:AffirmEnvironmentSandbox
                                                          locale:@"en_US"
                                                     countryCode:@"USA"
                                                        currency:@"USD"
                                                    merchantName:@"Affirm Example"];
#if DEBUG
    if ([liveInputs[@"AFFIRM_PUBLIC_KEY"] length] > 0) {
        [[AffirmConfiguration sharedInstance] configureWithPublicKey:liveInputs[@"AFFIRM_PUBLIC_KEY"]
                                                         environment:AffirmEnvironmentSandbox
                                                              locale:@"en_US"
                                                         countryCode:@"USA"
                                                            currency:@"USD"
                                                        merchantName:@"Live Thor SDK test"];
    }
#endif
    [AffirmConfiguration sharedInstance].cardTip = @"We've added these card details to Rakuten Autofill for quick, easy checkout.";
    return YES;
}

@end
