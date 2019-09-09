//
//  AffirmBaseWebViewController.h
//  AffirmSDK
//
//  Created by yijie on 2019/3/11.
//  Copyright © 2019 Affirm, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@class AffirmActivityIndicatorView;

NS_ASSUME_NONNULL_BEGIN

@interface AffirmBaseWebViewController : UIViewController <WKNavigationDelegate, WKUIDelegate>

/**
 The webview which displays the user interface for the checkuot.
 */
@property (nonatomic, strong, readonly) WKWebView *webView;

/**
 The loading indicator to be displayed while loading content.
 */
@property (nonatomic, strong, readonly) AffirmActivityIndicatorView *activityIndicatorView;

/**
 Load error page if webview request failed.
 
 @param error An instance error object
 */
- (void)loadErrorPage:(NSError *)error;

/**
 Dismiss current modal viewController
 */
- (void)dismiss;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
