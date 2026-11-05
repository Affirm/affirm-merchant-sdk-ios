//
//  AffirmPromoRenderingTests.m
//  AffirmSDKTests
//

#import <XCTest/XCTest.h>
#import <WebKit/WebKit.h>
#import "../AffirmSDK/AffirmPromoRendering.h"
#import "../AffirmSDK/AffirmPromotionalButton.h"
#import "../AffirmSDK/AffirmConfiguration.h"
#import "../AffirmSDK/AffirmUtils.h"

@interface AffirmPromoRenderingTests : XCTestCase
@property (nonatomic, strong) UIWindow *window;
@end

@implementation AffirmPromoRenderingTests

- (void)setUp
{
    [super setUp];
    [[AffirmConfiguration sharedInstance] configureWithPublicKey:@"PKNCHBIVYOT8JSOZ" environment:AffirmEnvironmentSandbox];
}

- (void)tearDown
{
    self.window.hidden = YES;
    self.window = nil;
    [super tearDown];
}

- (void)testPageReasonsStayAndUnknownCodesBecomeScriptError
{
    XCTAssertEqualObjects(AffirmPromoRenderReasonFromPage(AffirmPromoRenderReasonHTMLEmpty), AffirmPromoRenderReasonHTMLEmpty);
    XCTAssertEqualObjects(AffirmPromoRenderReasonFromPage(AffirmPromoRenderReasonSanitizerUnavailable), AffirmPromoRenderReasonSanitizerUnavailable);
    XCTAssertEqualObjects(AffirmPromoRenderReasonFromPage(AffirmPromoRenderReasonResourceFailed), AffirmPromoRenderReasonResourceFailed);
    XCTAssertEqualObjects(AffirmPromoRenderReasonFromPage(AffirmPromoRenderReasonImageFailed), AffirmPromoRenderReasonImageFailed);
    XCTAssertEqualObjects(AffirmPromoRenderReasonFromPage(AffirmPromoRenderReasonHTMLTimeout), AffirmPromoRenderReasonHTMLTimeout);
    XCTAssertEqualObjects(AffirmPromoRenderReasonFromPage(AffirmPromoRenderReasonTemplateError), AffirmPromoRenderReasonTemplateError);
    XCTAssertEqualObjects(AffirmPromoRenderReasonFromPage(nil), AffirmPromoRenderReasonScriptError);
    XCTAssertEqualObjects(AffirmPromoRenderReasonFromPage(@""), AffirmPromoRenderReasonScriptError);
    XCTAssertEqualObjects(AffirmPromoRenderReasonFromPage(AffirmPromoRenderReasonLoadError), AffirmPromoRenderReasonScriptError);
    XCTAssertEqualObjects(AffirmPromoRenderReasonFromPage(@"<script>"), AffirmPromoRenderReasonScriptError);
}

- (void)testStylesheetURLsAllowHTTPSAndBundleFilesOnly
{
    XCTAssertTrue(AffirmPromoPermittedStylesheetURL(nil));
    XCTAssertTrue(AffirmPromoPermittedStylesheetURL([NSURL URLWithString:@"https://cdn.test/a.css"]));
    XCTAssertFalse(AffirmPromoPermittedStylesheetURL([NSURL URLWithString:@"http://cdn.test/a.css"]));
    XCTAssertFalse(AffirmPromoPermittedStylesheetURL([NSURL URLWithString:@"javascript:alert(1)"]));
    XCTAssertFalse(AffirmPromoPermittedStylesheetURL([NSURL fileURLWithPath:@"/etc/passwd"]));

    NSURL *insideMainBundle = [NSURL fileURLWithPath:[[NSBundle mainBundle].bundlePath stringByAppendingPathComponent:@"Promo.css"]];
    XCTAssertTrue(AffirmPromoPermittedStylesheetURL(insideMainBundle));
    NSString *bundledCSS = [[NSBundle resourceBundle] pathForResource:@"badge_styles" ofType:@"css"];
    XCTAssertNotNil(bundledCSS);
    XCTAssertTrue(AffirmPromoPermittedStylesheetURL([NSURL fileURLWithPath:bundledCSS]));
}

- (void)testCSSPixelsMapOntoPoints
{
    XCTAssertEqual(AffirmPromoHeightForCSSPixels(40.2), (CGFloat)41);
    XCTAssertEqual(AffirmPromoHeightForCSSPixels(0), (CGFloat)0);
    XCTAssertEqual(AffirmPromoHeightForCSSPixels(-5), (CGFloat)0);
}

- (void)testDocumentEscapesPromoHTML
{
    NSString *fragment = @"<script>alert(1)</script>";
    NSString *document = AffirmPromoHTMLDocumentWithPayload(@{
        @"renderId": @"render-1",
        @"html": fragment
    });
    XCTAssertNotNil(document);
    XCTAssertTrue([document containsString:@"application/json"]);
    XCTAssertFalse([document containsString:fragment]);
    XCTAssertTrue([document containsString:@"\\u003cscript\\u003ealert(1)\\u003c\\/script\\u003e"]);
    XCTAssertGreaterThan(AffirmPromoSanitizerSource().length, 0);
}

- (AffirmPromotionalButton *)promoButton
{
    UIViewController *controller = [UIViewController new];
    self.window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 320, 200)];
    self.window.rootViewController = controller;
    [self.window makeKeyAndVisible];
    AffirmPromotionalButton *button = [[AffirmPromotionalButton alloc] initWithPromoID:nil
                                                                              showCTA:YES
                                                             presentingViewController:(id)controller
                                                                                frame:CGRectMake(0, 0, 320, 44)];
    [controller.view addSubview:button];
    return button;
}

- (void)testWebViewShowsOnlyAfterSanitizedContentIsReady
{
    AffirmPromotionalButton *button = [self promoButton];
    NSString *html = @"<span class=\"affirm-ala-price\">$50/mo</span>"
        @"<img src=\"x\" onerror=\"window.pwned=1\"><script>window.pwned=2</script>"
        @"<a href=\"javascript:alert(1)\">js</a><a href=\"https://ok.test\">ok</a>";
    XCTestExpectation *finished = [self expectationForNotification:AffirmPromoHTMLRenderDidFinishNotification
                                                            object:button
                                                           handler:^BOOL(NSNotification *note) {
        return [note.userInfo[@"outcome"] isEqualToString:@"ready"];
    }];
    XCTAssertTrue(button.hidden);
    [button configureWithHtmlString:html
                             amount:[NSDecimalNumber decimalNumberWithString:@"50"]
                      remoteFontURL:nil
                       remoteCssURL:nil];
    XCTAssertTrue(button.hidden);
    [self waitForExpectations:@[finished] timeout:10];
    XCTAssertFalse(button.hidden);

    WKWebView *webView = [button valueForKey:@"webView"];
    XCTestExpectation *script = [self expectationWithDescription:@"root html"];
    [webView evaluateJavaScript:@"({html: document.getElementById('affirm-promo-root').innerHTML, pwned: window.pwned})"
              completionHandler:^(id result, NSError *error) {
        XCTAssertNil(error);
        NSString *root = result[@"html"];
        XCTAssertNil(result[@"pwned"]);
        XCTAssertTrue([root containsString:@"affirm-ala-price"]);
        XCTAssertTrue([root containsString:@"https://ok.test"]);
        XCTAssertFalse([root containsString:@"<script"]);
        XCTAssertFalse([root containsString:@"javascript:"]);
        XCTAssertFalse([root containsString:@"onerror"]);
        [script fulfill];
    }];
    [self waitForExpectations:@[script] timeout:5];
}

- (void)testEmptySanitizedContentStaysHidden
{
    AffirmPromotionalButton *button = [self promoButton];
    XCTestExpectation *finished = [self expectationForNotification:AffirmPromoHTMLRenderDidFinishNotification
                                                            object:button
                                                           handler:^BOOL(NSNotification *note) {
        XCTAssertEqualObjects(note.userInfo[@"outcome"], @"failure");
        XCTAssertEqualObjects(note.userInfo[@"reason"], AffirmPromoRenderReasonHTMLEmpty);
        return YES;
    }];
    [button configureWithHtmlString:@"<script>window.pwned=1</script>"
                             amount:[NSDecimalNumber decimalNumberWithString:@"50"]
                      remoteFontURL:nil
                       remoteCssURL:nil];
    [self waitForExpectations:@[finished] timeout:10];
    XCTAssertTrue(button.hidden);
}

- (void)testInsecureStylesheetFailsClosed
{
    AffirmPromotionalButton *button = [self promoButton];
    XCTestExpectation *finished = [self expectationForNotification:AffirmPromoHTMLRenderDidFinishNotification
                                                            object:button
                                                           handler:^BOOL(NSNotification *note) {
        XCTAssertEqualObjects(note.userInfo[@"reason"], AffirmPromoRenderReasonResourceFailed);
        return YES;
    }];
    [button configureWithHtmlString:@"<span>ok</span>"
                             amount:[NSDecimalNumber decimalNumberWithString:@"50"]
                      remoteFontURL:nil
                       remoteCssURL:[NSURL URLWithString:@"http://evil.test/a.css"]];
    [self waitForExpectations:@[finished] timeout:2];
    XCTAssertTrue(button.hidden);
    WKWebView *webView = [button valueForKey:@"webView"];
    XCTAssertTrue(webView.hidden);
}

- (void)testSameVisiblePromoDoesNotReload
{
    AffirmPromotionalButton *button = [self promoButton];
    NSString *html = @"<span>ok</span>";
    XCTestExpectation *finished = [self expectationForNotification:AffirmPromoHTMLRenderDidFinishNotification
                                                            object:button
                                                           handler:nil];
    [button configureWithHtmlString:html
                             amount:[NSDecimalNumber decimalNumberWithString:@"50"]
                      remoteFontURL:nil
                       remoteCssURL:nil];
    [self waitForExpectations:@[finished] timeout:10];

    XCTestExpectation *reloaded = [self expectationForNotification:AffirmPromoHTMLRenderDidFinishNotification
                                                            object:button
                                                           handler:nil];
    reloaded.inverted = YES;
    [button configureWithHtmlString:html
                             amount:[NSDecimalNumber decimalNumberWithString:@"50"]
                      remoteFontURL:nil
                       remoteCssURL:nil];
    [self waitForExpectations:@[reloaded] timeout:0.5];
    XCTAssertFalse(button.hidden);
}

@end
