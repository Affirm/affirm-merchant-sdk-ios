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
    [[AffirmConfiguration sharedInstance] configureWithPublicKey:@"F6B2V0K9D5I8033Y"
                                                     environment:AffirmEnvironmentSandbox
                                                    merchantName:@"Affirm Example"];
    return YES;
}

@end
