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

@class AffirmResponse;

@interface AffirmPromotionalButton (AffirmPromoRenderingTests)
- (void)configureWithAttributedText:(nullable NSAttributedString *)attributedText
                           response:(nullable AffirmResponse *)response
                              error:(nullable NSError *)error;
@end

@interface AffirmPromoRenderingTests : XCTestCase
@property (nonatomic, strong) UIWindow *window;
@end

@implementation AffirmPromoRenderingTests

+ (void)setUp
{
    [super setUp];
    // The first WebView in the process pays for launching WebKit's helper processes. On CI that
    // alone can exceed the 5s render budget, so pay it once here instead of in the first test.
    WKWebView *webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    __block BOOL done = NO;
    [webView loadHTMLString:@"<p>warm</p>" baseURL:nil];
    [webView evaluateJavaScript:@"document.readyState" completionHandler:^(id result, NSError *error) {
        done = YES;
    }];
    NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:30];
    while (!done && [deadline timeIntervalSinceNow] > 0) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
    }
}

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
                                                           handler:^BOOL(NSNotification *note) {
        XCTAssertEqualObjects(note.userInfo[@"outcome"], @"ready", @"first render failed: %@", note.userInfo[@"reason"]);
        return YES;
    }];
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

- (void)testWebViewDoesNotRetainButton
{
    __weak AffirmPromotionalButton *weakButton = nil;
    @autoreleasepool {
        AffirmPromotionalButton *button = [self promoButton];
        weakButton = button;
        XCTestExpectation *finished = [self expectationWithDescription:@"ready"];
        id observer = [[NSNotificationCenter defaultCenter] addObserverForName:AffirmPromoHTMLRenderDidFinishNotification
                                                                        object:nil
                                                                         queue:nil
                                                                    usingBlock:^(NSNotification *note) {
            [finished fulfill];
        }];
        [button configureWithHtmlString:@"<span>ok</span>"
                                 amount:[NSDecimalNumber decimalNumberWithString:@"50"]
                          remoteFontURL:nil
                           remoteCssURL:nil];
        [self waitForExpectations:@[finished] timeout:10];
        [[NSNotificationCenter defaultCenter] removeObserver:observer];
        [button removeFromSuperview];
    }
    XCTAssertNil(weakButton);
}

- (void)testStaleRenderMessagesAreIgnored
{
    AffirmPromotionalButton *button = [self promoButton];
    NSDecimalNumber *amount = [NSDecimalNumber decimalNumberWithString:@"50"];
    __block NSUInteger outcomes = 0;
    XCTestExpectation *finished = [self expectationForNotification:AffirmPromoHTMLRenderDidFinishNotification
                                                            object:button
                                                           handler:^BOOL(NSNotification *note) {
        outcomes += 1;
        XCTAssertEqualObjects(note.userInfo[@"outcome"], @"ready");
        return YES;
    }];
    [button configureWithHtmlString:@"<span>first</span>" amount:amount remoteFontURL:nil remoteCssURL:nil];
    NSString *staleRenderID = [button valueForKey:@"htmlRenderID"];
    [button configureWithHtmlString:@"<span>second</span>" amount:amount remoteFontURL:nil remoteCssURL:nil];
    XCTAssertNotEqualObjects([button valueForKey:@"htmlRenderID"], staleRenderID);
    [self waitForExpectations:@[finished] timeout:10];

    XCTestExpectation *staleOutcome = [self expectationForNotification:AffirmPromoHTMLRenderDidFinishNotification
                                                                object:button
                                                               handler:nil];
    staleOutcome.inverted = YES;
    WKWebView *webView = [button valueForKey:@"webView"];
    NSString *script = [NSString stringWithFormat:
                        @"window.webkit.messageHandlers.affirmPromo.postMessage({event: 'failure', reason: 'html_empty', renderId: '%@'});"
                        @"document.getElementById('affirm-promo-root').textContent", staleRenderID];
    XCTestExpectation *evaluated = [self expectationWithDescription:@"root text"];
    [webView evaluateJavaScript:script completionHandler:^(id result, NSError *error) {
        XCTAssertNil(error);
        XCTAssertEqualObjects(result, @"second");
        [evaluated fulfill];
    }];
    [self waitForExpectations:@[evaluated, staleOutcome] timeout:1];
    XCTAssertEqual(outcomes, 1u);
    XCTAssertFalse(button.hidden);
    XCTAssertFalse(webView.hidden);
}

- (void)testNativeConfigurationCancelsInFlightHTMLRender
{
    AffirmPromotionalButton *button = [self promoButton];
    XCTestExpectation *htmlOutcome = [self expectationForNotification:AffirmPromoHTMLRenderDidFinishNotification
                                                               object:button
                                                              handler:nil];
    htmlOutcome.inverted = YES;
    [button configureWithHtmlString:@"<span>html</span>"
                             amount:[NSDecimalNumber decimalNumberWithString:@"50"]
                      remoteFontURL:nil
                       remoteCssURL:nil];
    NSAttributedString *text = [[NSAttributedString alloc] initWithString:@"native"];
    [button configureWithAttributedText:text response:nil error:nil];
    [self waitForExpectations:@[htmlOutcome] timeout:AffirmPromoHTMLTimeoutSeconds + 1];

    WKWebView *webView = [button valueForKey:@"webView"];
    XCTAssertTrue(webView.hidden);
    XCTAssertFalse(button.hidden);
    XCTAssertNil([button valueForKey:@"htmlRenderID"]);
    UIButton *nativeButton = [button valueForKey:@"button"];
    XCTAssertEqualObjects([nativeButton attributedTitleForState:UIControlStateNormal].string, @"native");
}

@end
