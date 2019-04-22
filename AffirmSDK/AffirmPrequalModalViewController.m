//
//  AffirmPrequalModalViewController.m
//  AffirmSDK
//
//  Created by yijie on 2019/3/13.
//  Copyright © 2019 Affirm, Inc. All rights reserved.
//

#import "AffirmPrequalModalViewController.h"
#import "AffirmPrequalDelegate.h"
#import "AffirmConstants.h"
#import "AffirmUtils.h"
#import "AffirmConfiguration.h"

@interface AffirmPrequalModalViewController ()

@property (nonatomic, strong) NSURL *requestURL;

@end

@implementation AffirmPrequalModalViewController

- (instancetype)initWithURL:(NSURL *)URL delegate:(id<AffirmPrequalDelegate>)delegate
{
    [AffirmValidationUtils checkNotNil:URL name:@"URL"];
    [AffirmValidationUtils checkNotNil:delegate name:@"delegate"];

    if (self = [super initWithNibName:nil bundle:nil]) {
        _requestURL = URL;
        _delegate = delegate;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Close"
                                                                              style:UIBarButtonItemStyleDone
                                                                             target:self
                                                                             action:@selector(dismiss)];
    if (@available(iOS 11.0, *)) {
        WKHTTPCookieStore *store = self.webView.configuration.websiteDataStore.httpCookieStore;
        [store getAllCookies:^(NSArray<NSHTTPCookie *> *cookies) {
            for (NSHTTPCookie *cookie in cookies) {
                [store deleteCookie:cookie completionHandler:nil];
            }
        }];
    }
    [self.webView loadRequest:[NSURLRequest requestWithURL:self.requestURL
                                               cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                           timeoutInterval:30]];
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

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    NSString *urlString = navigationAction.request.URL.absoluteString;
    if ([urlString isEqualToString:AFFIRM_PREQUAL_REFERRING_URL]) {
        [self dismiss];
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    [self loadErrorPage:error];
    if (self.delegate && [self.delegate respondsToSelector:@selector(webViewController:didFailWithError:)]) {
        [self.delegate webViewController:self didFailWithError:error];
    }
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(webViewController:didFailWithError:)]) {
        [self.delegate webViewController:self didFailWithError:error];
    }
}

@end
