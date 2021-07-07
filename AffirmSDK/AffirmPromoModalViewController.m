//
//  AffirmPromoModalViewController.m
//  AffirmSDK
//
//  Created by yijie on 2019/3/13.
//  Copyright © 2019 Affirm, Inc. All rights reserved.
//

#import "AffirmPromoModalViewController.h"
#import "AffirmPromotionalButton.h"
#import "AffirmConfiguration.h"
#import "AffirmUtils.h"
#import "AffirmClient.h"

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
        [self initializeHtmlWithPromoId:promoId amount:amount pageType:AffirmPageTypeNone delegate:delegate];
    }
    return self;
}

- (instancetype)initWithPromoId:(nullable NSString *)promoId
                         amount:(NSDecimalNumber *)amount
                       pageType:(AffirmPageType)pageType
                       delegate:(id<AffirmPrequalDelegate>)delegate
{
    [AffirmValidationUtils checkNotNil:amount name:@"amount"];
    [AffirmValidationUtils checkNotNil:delegate name:@"delegate"];

    if (self = [super initWithNibName:nil bundle:nil]) {
        [self initializeHtmlWithPromoId:promoId amount:amount pageType:pageType delegate:delegate];
    }
    return self;
}

- (void)initializeHtmlWithPromoId:(nullable NSString *)promoId
                           amount:(NSDecimalNumber *)amount
                         pageType:(AffirmPageType)pageType
                         delegate:(id<AffirmPrequalDelegate>)delegate
{
    NSString *jsURL = [AffirmConfiguration sharedInstance].jsURL;
    NSString *filePath = [[NSBundle resourceBundle] pathForResource:@"promo_modal_template"
                                                             ofType:@"html"];
    NSString *rawContent = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];

    NSString *promoIdString = promoId ?: @"";
    NSString *pageTypeString = FormatAffirmPageTypeString(pageType) ?: @"";
    _htmlString = [NSString stringWithFormat:rawContent, [AffirmConfiguration sharedInstance].publicKey, jsURL, amount, promoIdString, pageTypeString, promoIdString, AFFIRM_PREQUAL_REFERRING_URL];
    _delegate = delegate;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Close"
                                                                              style:UIBarButtonItemStyleDone
                                                                             target:self
                                                                             action:@selector(dismiss)];
    [self.webView loadHTMLString:self.htmlString baseURL:[NSURL URLWithString:AffirmPromoClient.host]];
}

#pragma mark - WKUIDelegate

- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures
{
    NSURL *url = navigationAction.request.URL;
    if (navigationAction.targetFrame == nil && [url.absoluteString rangeOfString:@"affirm.com/apps/prequal"].location != NSNotFound) {
        NSString *fullURL = [url.absoluteString stringByAppendingString:[NSString stringWithFormat:@"&referring_url=%@", AFFIRM_PREQUAL_REFERRING_URL]];
        [webView loadRequest:[[NSURLRequest alloc] initWithURL:[NSURL URLWithString:fullURL]]];
    }
    return nil;
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
