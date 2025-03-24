//
//  AppDelegate.m
//  Examples
//
//  Created by Victor Zhu on 2019/3/5.
//  Copyright © 2019 Affirm, Inc. All rights reserved.
//

#import "AppDelegate.h"
#import <AffirmSDK/AffirmSDK.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[AffirmConfiguration sharedInstance] configureWithPublicKey:@"3HCWTVU5BYWZB9RK"
                                                     environment:AffirmEnvironmentSandbox
                                                          locale:@"en_GB"
                                                     countryCode:@"GBR"
                                                        currency:@"GBP"
                                                    merchantName:@"Affirm Example"];
    [AffirmConfiguration sharedInstance].cardTip = @"We've added these card details to Rakuten Autofill for quick, easy checkout.";
    return YES;
}

@end
