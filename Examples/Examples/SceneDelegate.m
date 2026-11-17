//
//  SceneDelegate.m
//  Examples
//
//  Copyright © 2026 Affirm, Inc. All rights reserved.
//

#import "SceneDelegate.h"
#import "ViewController.h"

@implementation SceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions
{
    if (![scene isKindOfClass:[UIWindowScene class]]) {
        return;
    }
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.rootViewController = [ViewController new];
    [self.window makeKeyAndVisible];
}

@end
