//
//  AffirmPromoModalViewController.m
//  AffirmSDK
//
//  Created by yijie on 2019/3/13.
//  Copyright © 2019 Affirm, Inc. All rights reserved.
//

#import "AffirmPromoModalViewController.h"
#import "AffirmConfiguration.h"
#import "AffirmUtils.h"

@interface AffirmPromoModalViewController ()

@property (nonatomic, copy) NSString *htmlString;

@end

@implementation AffirmPromoModalViewController

- (instancetype)initWithPromoId:(nullable NSString *)promoId
                         amount:(NSDecimalNumber *)amount
                       delegate:(id<AffirmPrequalDelegate>)delegate
{
    [AffirmValidationUtils checkNotNil:amount name:@"amount"];
    [AffirmValidationUtils checkNotNil:delegate name:@"delegate"];
    
    if (self = [super initWithNibName:nil bundle:nil]) {
        NSString *jsURL = [AffirmConfiguration sharedInstance].isProductionEnvironment ? AFFIRM_JS_URL : AFFIRM_SANDBOX_JS_URL;
        NSString *filePath = [[NSBundle resourceBundle] pathForResource:@"promo_modal_template"
                                                                 ofType:@"html"];
        NSString *rawContent = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
        _htmlString = [NSString stringWithFormat:rawContent, [AffirmConfiguration sharedInstance].publicKey, jsURL, amount, promoId ?: @"", AFFIRM_CHECKOUT_CANCELLATION_URL];
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
    [self.webView loadHTMLString:self.htmlString baseURL:nil];
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    NSString *urlString = navigationAction.request.URL.absoluteString;
    if ([urlString isEqualToString:AFFIRM_CHECKOUT_CANCELLATION_URL]) {
        [self dismiss];
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    [webView evaluateJavaScript:@"document.getElementById('affirm_learn_more_splitpay').src = 'applewebdata://';" completionHandler:nil];
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
