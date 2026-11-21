//
//  AffirmCheckoutSessionCodeTests.m
//  AffirmSDKTests
//

#import <XCTest/XCTest.h>
#import "../AffirmSDK/AffirmCheckoutViewController.h"
#import "../AffirmSDK/AffirmCheckoutDelegate.h"
#import "../AffirmSDK/AffirmCheckout.h"
#import "../AffirmSDK/AffirmItem.h"
#import "../AffirmSDK/AffirmPrepareAuth.h"

static NSString *const RedirectURL = @"https://sandbox.affirm.com/products/checkout?checkout_ari=TEST";

@interface AffirmPrepareAuth (SessionCodeTesting)
+ (nullable NSString *)consumeStoredCodeVerifier;
+ (NSString *)codeChallengeForVerifier:(NSString *)verifier;
@end

@interface AffirmCheckoutViewController (SessionCodeTesting)
+ (NSURL *)redirectURL:(NSURL *)redirectURL addingSessionCode:(nullable NSString *)sessionCode;
- (void)loadRedirectURL:(NSURL *)redirectURL;
- (void)prepareForCheckout;
@end

// Loads its view without creating a checkout on the network.
@interface SessionCodeTestCheckoutViewController : AffirmCheckoutViewController
@end

@implementation SessionCodeTestCheckoutViewController
- (void)prepareForCheckout {}
@end

@interface SessionCodeTestDelegate : NSObject <AffirmCheckoutDelegate>
@end

@implementation SessionCodeTestDelegate
- (void)checkout:(AffirmCheckoutViewController *)checkoutViewController completedWithToken:(NSString *)checkoutToken {}
- (void)vcnCheckout:(UIViewController *)checkoutViewController completedWithCreditCard:(AffirmCreditCard *)creditCard {}
- (void)checkoutCancelled:(UIViewController *)checkoutViewController {}
- (void)checkoutCancelled:(AffirmCheckoutViewController *)checkoutViewController checkoutCanceledWithReason:(AffirmReasonCode *)reasonCode {}
- (void)checkout:(AffirmCheckoutViewController *)checkoutViewController didFailWithError:(NSError *)error {}
@end

@interface AffirmCheckoutSessionCodeTests : XCTestCase
@property (nonatomic, strong) SessionCodeTestDelegate *delegate;
@end

@implementation AffirmCheckoutSessionCodeTests

- (void)setUp
{
    self.continueAfterFailure = NO;
    self.delegate = [SessionCodeTestDelegate new];
    [AffirmPrepareAuth consumeStoredCodeVerifier];
}

- (void)tearDown
{
    [AffirmPrepareAuth consumeStoredCodeVerifier];
}

- (NSString *)prepareAuth
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"prepareAuth completion"];
    __block NSString *challenge;
    [AffirmPrepareAuth prepareAuthWithCompletion:^(AffirmPrepareAuthResult *result) {
        challenge = result.codeChallenge;
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:2 handler:nil];
    XCTAssertNotNil(challenge);
    return challenge;
}

- (NSDictionary<NSString *, NSString *> *)queryOfURL:(NSURL *)url
{
    NSMutableDictionary *query = [NSMutableDictionary dictionary];
    for (NSURLQueryItem *item in [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO].queryItems) {
        XCTAssertNil(query[item.name], @"%@ appears more than once", item.name);
        query[item.name] = item.value;
    }
    return query;
}

- (SessionCodeTestCheckoutViewController *)loadedCheckoutWithVCN:(BOOL)useVCN sessionCode:(NSString *)sessionCode
{
    AffirmItem *item = [AffirmItem itemWithName:@"Affirm Test Item" SKU:@"test_item" unitPrice:[NSDecimalNumber decimalNumberWithString:@"15.00"] quantity:1 URL:[NSURL URLWithString:@"https://sandbox.affirm.com/item"]];
    AffirmCheckout *checkout = [AffirmCheckout checkoutWithItems:@[item] shipping:nil totalAmount:[NSDecimalNumber decimalNumberWithString:@"15.00"]];
    SessionCodeTestCheckoutViewController *controller = [[SessionCodeTestCheckoutViewController alloc] initWithDelegate:self.delegate
                                                                                                               checkout:checkout
                                                                                                                 useVCN:useVCN
                                                                                                         getReasonCodes:NO];
    controller.sessionCode = sessionCode;
    [controller loadViewIfNeeded];
    [controller loadRedirectURL:[NSURL URLWithString:RedirectURL]];
    return controller;
}

#pragma mark - Adding the session code to the URL

- (void)testAddsSessionCodeAndVerifierWhenBothArePresent
{
    NSString *challenge = [self prepareAuth];
    NSURL *url = [AffirmCheckoutViewController redirectURL:[NSURL URLWithString:RedirectURL] addingSessionCode:@"auth_abc123"];

    NSDictionary *query = [self queryOfURL:url];
    XCTAssertEqualObjects(query[@"checkout_ari"], @"TEST");
    XCTAssertEqualObjects(query[@"session_code"], @"auth_abc123");
    XCTAssertEqualObjects([AffirmPrepareAuth codeChallengeForVerifier:query[@"code_verifier"]], challenge,
                          @"the URL should carry the verifier behind the challenge the merchant used");
    XCTAssertEqualObjects(url.host, @"sandbox.affirm.com");
    XCTAssertEqualObjects(url.path, @"/products/checkout");
    XCTAssertNil([AffirmPrepareAuth consumeStoredCodeVerifier], @"the verifier should be single-use");
}

- (void)testLeavesTheURLUnchangedWithoutAVerifier
{
    NSURL *redirect = [NSURL URLWithString:RedirectURL];
    XCTAssertEqualObjects([AffirmCheckoutViewController redirectURL:redirect addingSessionCode:@"auth_abc123"], redirect);
}

- (void)testLeavesTheURLAndTheVerifierAloneWithoutASessionCode
{
    [self prepareAuth];
    NSURL *redirect = [NSURL URLWithString:RedirectURL];
    XCTAssertEqualObjects([AffirmCheckoutViewController redirectURL:redirect addingSessionCode:nil], redirect);
    XCTAssertNotNil([AffirmPrepareAuth consumeStoredCodeVerifier], @"a checkout without a session code should not use up the verifier");
}

- (void)testEncodesTheSessionCodeSoItCannotBreakTheURL
{
    [self prepareAuth];
    NSString *sessionCode = @"eyJh.b-c_d&e=f\"g h#i";
    NSURL *url = [AffirmCheckoutViewController redirectURL:[NSURL URLWithString:RedirectURL] addingSessionCode:sessionCode];

    NSDictionary *query = [self queryOfURL:url];
    XCTAssertEqualObjects(query[@"session_code"], sessionCode);
    XCTAssertEqualObjects(query[@"checkout_ari"], @"TEST");
    XCTAssertNotNil(query[@"code_verifier"]);
    // The VCN page puts the URL inside a double-quoted JavaScript string.
    XCTAssertFalse([url.absoluteString containsString:@"\""], @"%@", url.absoluteString);
    XCTAssertFalse([url.absoluteString containsString:@"\\"], @"%@", url.absoluteString);
}

#pragma mark - Loading the checkout

- (void)testRegularCheckoutLoadsTheURLWithTheSessionCode
{
    [self prepareAuth];
    SessionCodeTestCheckoutViewController *controller = [self loadedCheckoutWithVCN:NO sessionCode:@"auth_abc123"];

    NSPredicate *loaded = [NSPredicate predicateWithBlock:^BOOL(WKWebView *webView, NSDictionary *bindings) {
        return [webView.URL.absoluteString containsString:@"code_verifier="];
    }];
    [self waitForExpectations:@[[[XCTNSPredicateExpectation alloc] initWithPredicate:loaded object:controller.webView]] timeout:5];
    XCTAssertEqualObjects([self queryOfURL:controller.webView.URL][@"session_code"], @"auth_abc123");
}

- (void)testRegularCheckoutWithoutAVerifierLoadsTheOriginalURL
{
    SessionCodeTestCheckoutViewController *controller = [self loadedCheckoutWithVCN:NO sessionCode:@"auth_abc123"];

    NSPredicate *loaded = [NSPredicate predicateWithBlock:^BOOL(WKWebView *webView, NSDictionary *bindings) {
        return webView.URL != nil;
    }];
    [self waitForExpectations:@[[[XCTNSPredicateExpectation alloc] initWithPredicate:loaded object:controller.webView]] timeout:5];
    XCTAssertEqualObjects(controller.webView.URL.absoluteString, RedirectURL);
}

- (void)testVCNCheckoutPageOpensTheURLWithTheSessionCode
{
    [self prepareAuth];
    SessionCodeTestCheckoutViewController *controller = [self loadedCheckoutWithVCN:YES sessionCode:@"auth_abc123"];

    __block NSString *html;
    NSPredicate *loaded = [NSPredicate predicateWithBlock:^BOOL(WKWebView *webView, NSDictionary *bindings) {
        [webView evaluateJavaScript:@"document.documentElement.outerHTML" completionHandler:^(id result, NSError *error) {
            html = result;
        }];
        return [html containsString:@"var url"];
    }];
    [self waitForExpectations:@[[[XCTNSPredicateExpectation alloc] initWithPredicate:loaded object:controller.webView]] timeout:5];

    NSRange start = [html rangeOfString:@"var url = \""];
    NSString *rest = [html substringFromIndex:NSMaxRange(start)];
    NSURL *url = [NSURL URLWithString:[rest substringToIndex:[rest rangeOfString:@"\""].location]];
    NSDictionary *query = [self queryOfURL:url];
    XCTAssertEqualObjects(query[@"session_code"], @"auth_abc123");
    XCTAssertNotNil(query[@"code_verifier"]);
    XCTAssertEqualObjects(query[@"checkout_ari"], @"TEST");
}

@end
