//
//  AffirmBaseWebViewController.m
//  AffirmSDK
//
//  Created by yijie on 2019/3/11.
//  Copyright © 2019 Affirm, Inc. All rights reserved.
//

#import "AffirmBaseWebViewController.h"
#import "AffirmActivityIndicatorView.h"
#import "AffirmConfiguration.h"
#import "AffirmLogger.h"

@interface AffirmBaseWebViewController ()

@property (nonatomic, strong, readwrite) WKWebView *webView;
@property (nonatomic, strong, readwrite) AffirmActivityIndicatorView *activityIndicatorView;

@end

@implementation AffirmBaseWebViewController

#pragma mark - Life Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    WKWebViewConfiguration *configuration = [WKWebViewConfiguration new];
    configuration.preferences.javaScriptCanOpenWindowsAutomatically = YES;
    configuration.preferences.javaScriptEnabled = YES;
    configuration.applicationNameForUserAgent = [NSString stringWithFormat:@"Affirm-iOS-SDK-%@", [AffirmConfiguration affirmSDKVersion]];
    configuration.processPool = [AffirmConfiguration sharedInstance].pool;
    WKWebView *webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:configuration];
    webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    webView.contentMode = UIViewContentModeScaleAspectFit;
    webView.multipleTouchEnabled = NO;
    webView.navigationDelegate = self;
    webView.UIDelegate = self;
    [webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
    [self.view addSubview:webView];
    self.webView = webView;

    AffirmActivityIndicatorView *activityIndicatorView = [[AffirmActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 80, 80)];
    [self.view addSubview:activityIndicatorView];
    self.activityIndicatorView = activityIndicatorView;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.activityIndicatorView.center = self.view.center;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if (@available(iOS 11.0, *)) {
        [[WKWebsiteDataStore defaultDataStore].httpCookieStore getAllCookies:^(NSArray<NSHTTPCookie *> * cookies) {
            for (NSHTTPCookie *cookie in cookies) {
                [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
            }
        }];
    }
}

- (void)dealloc
{
    if (self.webView) {
        [self.webView removeObserver:self
                          forKeyPath:@"estimatedProgress"
                             context:nil];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSString *,id> *)change
                       context:(void *)context
{
    if ([keyPath isEqualToString:@"estimatedProgress"]) {
        if ([[change valueForKey:@"new"] floatValue] >= 1.0) {
            [self.activityIndicatorView stopAnimating];
        } else {
            [self.activityIndicatorView startAnimating];
        }
    } else {
        [super observeValueForKeyPath:keyPath
                             ofObject:object
                               change:change
                              context:context];
    }
}

- (void)loadErrorPage:(NSError *)error
{
    [[AffirmLogger sharedInstance] trackEvent:@"Web load failed"
                                   parameters:@{@"error_description": error.localizedDescription}];
    NSString *errorDescription = [error.localizedDescription stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSString *url = [NSString stringWithFormat:@"https://www.%@/u/#/error?main=Error&sub=%@", [AffirmConfiguration sharedInstance].domain, errorDescription];
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
}

- (void)dismiss
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    [[AffirmLogger sharedInstance] logEvent:@"WebView failed to load"];
    [self loadErrorPage:error];
}

@end
