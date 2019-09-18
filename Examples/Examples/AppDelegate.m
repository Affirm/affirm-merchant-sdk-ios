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
    [[AffirmConfiguration sharedInstance] configureWithPublicKey:@"ZY2590ABAF62S9KM"
                                                     environment:AffirmEnvironmentSandbox
                                                    merchantName:@"Affirm Example"];
    return YES;
}

@end
