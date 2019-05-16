//
//  AffirmCheckoutViewController.m
//  AffirmSDK
//
//  Created by Paul on 3/18/19.
//  Copyright © 2019 Affirm, Inc. All rights reserved.
//

#import "AffirmCheckoutViewController.h"
#import "AffirmActivityIndicatorView.h"
#import "AffirmPopupViewController.h"
#import "AffirmCheckoutDelegate.h"
#import "AffirmConfiguration.h"
#import "AffirmCheckout.h"
#import "AffirmCreditCard.h"
#import "AffirmClient.h"
#import "AffirmRequest.h"
#import "AffirmLogger.h"
#import "AffirmConstants.h"
#import "AffirmUtils.h"

@interface AffirmCheckoutViewController ()

@property (nonatomic, copy, readwrite) NSString *checkoutARI;

@end

@implementation AffirmCheckoutViewController

- (instancetype)initWithDelegate:(id<AffirmCheckoutDelegate>)delegate
                        checkout:(AffirmCheckout *)checkout
                          useVCN:(BOOL)useVCN
{
    [AffirmValidationUtils checkNotNil:delegate name:@"checkout delegate"];
    [AffirmValidationUtils checkNotNil:checkout name:@"checkout"];
    
    if (self = [super initWithNibName:nil bundle:nil]) {
        _delegate = delegate;
        _checkout = [checkout copy];
        _useVCN = useVCN;
    }
    return self;
}

+ (AffirmCheckoutViewController *)startCheckout:(AffirmCheckout *)checkout
                                       delegate:(nonnull id<AffirmCheckoutDelegate>)delegate
{
    return [[self alloc] initWithDelegate:delegate
                                 checkout:checkout
                                   useVCN:NO];
}

+ (AffirmCheckoutViewController *)startCheckout:(AffirmCheckout *)checkout
                                         useVCN:(BOOL)useVCN
                                       delegate:(nonnull id<AffirmCheckoutDelegate>)delegate
{
    return [[self alloc] initWithDelegate:delegate
                                 checkout:checkout
                                   useVCN:useVCN];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self prepareForCheckout];
}

- (void)prepareForCheckout
{
    [[AffirmLogger sharedInstance] trackEvent:@"Checkout initiated"];
    [self.activityIndicatorView startAnimating];
    AffirmCheckoutRequest *request = [[AffirmCheckoutRequest alloc] initWithPublicKey:[AffirmConfiguration sharedInstance].publicKey
                                                                             checkout:self.checkout
                                                                               useVCN:self.useVCN];
    [AffirmCheckoutClient send:request handler:^(id<AffirmResponseProtocol>  _Nullable response, NSError * _Nullable error) {
        if (response && [response isKindOfClass:[AffirmCheckoutResponse class]]) {
            AffirmCheckoutResponse *checkoutResponse = (AffirmCheckoutResponse *)response;
            NSURL *redirectURL = checkoutResponse.redirectURL;
            if (redirectURL) {
                [self loadRedirectURL:redirectURL];
                self.checkoutARI = [redirectURL lastPathComponent];
                [[AffirmLogger sharedInstance] trackEvent:@"Checkout ready to present" parameters:@{@"checkout_ari": self.checkoutARI}];
            } else {
                [[AffirmLogger sharedInstance] trackEvent:@"Checkout redirect missing"];
                [self.activityIndicatorView stopAnimating];
                [self.delegate checkout:self didFailWithError:checkoutResponse.dictionary.convertToNSError];
            }
        } else if (response && [response isKindOfClass:[AffirmErrorResponse class]]) {
            AffirmErrorResponse *errorResponse = (AffirmErrorResponse *)response;
            [[AffirmLogger sharedInstance] trackEvent:@"Checkout creation failed" parameters:errorResponse.dictionary];
            [self.activityIndicatorView stopAnimating];
            [self.delegate checkout:self didFailWithError:[errorResponse.dictionary convertToNSErrorWithCode:errorResponse.statusCode]];
        } else {
            [self.delegate checkout:self didFailWithError:error];
        }
    }];
}

- (void)loadRedirectURL:(NSURL *)redirectURL
{
    if (_useVCN) {
        NSBundle *sdkBundle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"AffirmSDK" ofType:@"bundle"]];
        NSString *filePath = [sdkBundle pathForResource:@"vcn_checkout" ofType:@"html"];
        NSString *urlString = redirectURL.absoluteString;
        __block NSString *rawContent = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
        [@{@"{{URL}}": urlString,
           @"{{URL2}}": urlString,
           @"{{CONFIRM_CB_URL}}": AFFIRM_CHECKOUT_CONFIRMATION_URL,
           @"{{CANCELLED_CB_URL}}": AFFIRM_CHECKOUT_CANCELLATION_URL}
         enumerateKeysAndObjectsUsingBlock:^(NSString *  _Nonnull key, NSString *  _Nonnull obj, BOOL * _Nonnull stop) {
             rawContent = [rawContent stringByReplacingOccurrencesOfString:key
                                                                withString:obj
                                                                   options:NSLiteralSearch
                                                                     range:[rawContent rangeOfString:key]];
         }];
        NSString *baseUrl = [NSString stringWithFormat:@"https://%@", redirectURL.host];
        [self.webView loadData:[rawContent dataUsingEncoding:NSUTF8StringEncoding] MIMEType:@"text/html" characterEncodingName:@"utf-8" baseURL:[NSURL URLWithString:baseUrl]];
    } else {
        [self.webView loadRequest:[NSURLRequest requestWithURL:redirectURL]];
    }
}

#pragma mark - Webview

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    NSURL *URL = navigationAction.request.URL;
    NSString *strippedURL = [NSString stringWithFormat:@"%@://%@%@", URL.scheme, URL.host, URL.path];
    if ([strippedURL isEqualToString:AFFIRM_CHECKOUT_CONFIRMATION_URL]) {
        NSURLComponents *urlComponents = [[NSURLComponents alloc] initWithString:URL.absoluteString];
        for(NSURLQueryItem *item in urlComponents.queryItems) {
            if (_useVCN) {
                if([item.name isEqualToString:@"data"]) {
                    [self.delegate vcnCheckout:self
                       completedWithCreditCard:[AffirmCreditCard creditCardWithDict:item.value.convertToDictionary]];
                    [[AffirmLogger sharedInstance] trackEvent:@"Checkout completed" parameters:@{@"checkout_ari": self.checkoutARI, @"checkout_data_received": item.value != nil ? @"true" : @"false"}];
                    break;
                }
            } else {
                if([item.name isEqualToString:@"checkout_token"]) {
                    [self.delegate checkout:self completedWithToken:item.value];
                    [[AffirmLogger sharedInstance] trackEvent:@"Checkout completed" parameters:@{@"checkout_ari": self.checkoutARI, @"checkout_token_received": item.value != nil ? @"true" : @"false"}];
                    break;
                }
            }
        }
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    if ([strippedURL isEqualToString:AFFIRM_CHECKOUT_CANCELLATION_URL]) {
        [self.delegate checkoutCancelled:self];
        [[AffirmLogger sharedInstance] trackEvent:@"Checkout cancelled" parameters:@{@"checkout_ari": self.checkoutARI}];
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    [self webView:webView checkIfURL:URL.absoluteString isPopupWithCompletion:^(BOOL isPopup) {
        if (isPopup) {
            AffirmPopupViewController *viewController = [[AffirmPopupViewController alloc] initWithURL:URL];
            UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:viewController];
            [self presentViewController:navController animated:YES completion:nil];
            [[AffirmLogger sharedInstance] trackEvent:@"External link selected from checkout" parameters:@{@"checkout_ari": self.checkoutARI, @"selected_link": URL.absoluteString}];
            decisionHandler(WKNavigationActionPolicyCancel);
        }
        else {
            decisionHandler(WKNavigationActionPolicyAllow);
        }
    }];
}

- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL))completionHandler
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:message
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                                        style:UIAlertActionStyleCancel
                                                      handler:^(UIAlertAction *action) {
                                                          completionHandler(NO);
                                                      }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action) {
                                                          completionHandler(YES);
                                                      }]];
    [self presentViewController:alertController animated:YES completion:^{}];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    [self loadErrorPage:error];
    [self.delegate checkout:self didFailWithError:error];
}

- (void)webView:(WKWebView *)webView checkIfURL:(NSString *)URLString isPopupWithCompletion:(void(^)(BOOL isPopup))completion
{
    NSString *JSCodeFormat = @"javascript: (function () {"
    "var anchors = document.getElementsByTagName('a');"
    "for (var i = 0; i < anchors.length; i++) {"
    "if (anchors[i].target == '_blank' && anchors[i].href == '%@') {"
    "return true;"
    "}"
    "}"
    "return false;"
    "})();"
    ;
    NSString *JSCode = [NSString stringWithFormat:JSCodeFormat, URLString];
    [webView evaluateJavaScript:JSCode completionHandler:^(id result, NSError *error) {
        completion([result boolValue]);
    }];
}

@end
