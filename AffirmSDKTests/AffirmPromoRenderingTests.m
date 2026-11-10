//
//  AffirmPromoRenderingTests.m
//  AffirmSDKTests
//

#import <XCTest/XCTest.h>
#import <WebKit/WebKit.h>
#import <objc/runtime.h>
#import "../AffirmSDK/AffirmClient.h"
#import "../AffirmSDK/AffirmPromoRendering.h"
#import "../AffirmSDK/AffirmPromotionalButton.h"
#import "../AffirmSDK/AffirmConfiguration.h"
#import "../AffirmSDK/AffirmUtils.h"
#import "../AffirmSDK/AffirmRequest.h"

@class AffirmResponse;

@interface AffirmPromotionalButton (AffirmPromoRenderingTests)
- (void)configureWithAttributedText:(nullable NSAttributedString *)attributedText
                           response:(nullable AffirmResponse *)response
                              error:(nullable NSError *)error;
@end

@interface AffirmPromoRenderingTests : XCTestCase
@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) NSMutableArray<AffirmRequestHandler> *promoHandlers;
@property (nonatomic) IMP originalSendIMP;
@end

@implementation AffirmPromoRenderingTests

- (void)setUp
{
    [super setUp];
    [[AffirmConfiguration sharedInstance] configureWithPublicKey:@"PKNCHBIVYOT8JSOZ" environment:AffirmEnvironmentSandbox];

    // Promo requests are held so each test decides when, and with what, they complete.
    // Every other request (tracking) is dropped.
    NSMutableArray<AffirmRequestHandler> *handlers = [NSMutableArray array];
    self.promoHandlers = handlers;
    Method send = class_getClassMethod([AffirmClient class], @selector(send:handler:));
    self.originalSendIMP = method_setImplementation(send, imp_implementationWithBlock(^(id client, AffirmRequest *request, AffirmRequestHandler handler) {
        if ([request isKindOfClass:[AffirmPromoRequest class]] && handler) {
            [handlers addObject:[handler copy]];
        }
    }));
}

- (void)tearDown
{
    Method send = class_getClassMethod([AffirmClient class], @selector(send:handler:));
    method_setImplementation(send, self.originalSendIMP);
    self.promoHandlers = nil;
    self.window.hidden = YES;
    self.window = nil;
    [super tearDown];
}

#pragma mark - Render ownership

- (NSDecimalNumber *)amount
{
    return [NSDecimalNumber decimalNumberWithString:@"50"];
}

- (void)completePromoRequestAtIndex:(NSUInteger)index json:(NSString *)json
{
    self.promoHandlers[index]([self responseForJSON:json], nil);
}

- (void)configureNative:(AffirmPromotionalButton *)button
{
    [button configureWithAmount:[self amount]
                 affirmLogoType:AffirmLogoTypeText
                    affirmColor:AffirmColorTypeBlue
                           font:[UIFont systemFontOfSize:15]
                      textColor:[UIColor blackColor]];
}

- (void)configureExplicitHTML:(AffirmPromotionalButton *)button
{
    [button configureByHtmlStylingWithAmount:[self amount]
                              affirmLogoType:AffirmLogoTypeName
                                 affirmColor:AffirmColorTypeBlue];
}

- (XCTestExpectation *)expectRenderOf:(AffirmPromotionalButton *)button
                          finishingIn:(NSString *)state
                               reason:(nullable NSString *)reason
{
    return [self expectationForNotification:AffirmPromoRenderDidFinishNotification
                                     object:button
                                    handler:^BOOL(NSNotification *note) {
        AffirmPromoRenderOperation *operation = note.userInfo[AffirmPromoRenderOperationKey];
        XCTAssertEqualObjects(operation.terminalState, state);
        XCTAssertEqualObjects(operation.reason, reason);
        return YES;
    }];
}

- (NSString *)nativeTitleOf:(AffirmPromotionalButton *)button
{
    UIButton *nativeButton = [button valueForKey:@"button"];
    return [nativeButton attributedTitleForState:UIControlStateNormal].string;
}

- (void)testOperationChoosesOnceAndFinishesOnce
{
    AffirmPromoRenderOperation *operation = [[AffirmPromoRenderOperation alloc] initWithRequestedMode:AffirmPromoRenderModeNative];
    XCTAssertNil(operation.terminalState);
    XCTAssertFalse([operation selectMode:AffirmPromoRenderModeNone]);
    XCTAssertTrue([operation selectMode:AffirmPromoRenderModeNative]);
    XCTAssertFalse([operation selectMode:AffirmPromoRenderModeHTML]);
    XCTAssertEqual(operation.selectedMode, AffirmPromoRenderModeNative);

    XCTAssertTrue([operation finishWithOutcome:AffirmPromoRenderOutcomeSuccess actualRenderer:AffirmPromoRenderModeNative reason:nil]);
    XCTAssertFalse([operation finishWithOutcome:AffirmPromoRenderOutcomeCancelled actualRenderer:AffirmPromoRenderModeNone reason:AffirmPromoRenderReasonSuperseded]);
    XCTAssertEqual(operation.outcome, AffirmPromoRenderOutcomeSuccess);
    XCTAssertNil(operation.reason);
    XCTAssertEqualObjects(operation.terminalState, @"T1");
    XCTAssertFalse([operation selectMode:AffirmPromoRenderModeHTML]);
}

- (void)testOperationMapsEveryTerminalState
{
    NSString *(^state)(AffirmPromoRenderMode, AffirmPromoRenderMode, AffirmPromoRenderOutcome, AffirmPromoRenderMode, NSString *) =
    ^NSString *(AffirmPromoRenderMode requested, AffirmPromoRenderMode selected, AffirmPromoRenderOutcome outcome, AffirmPromoRenderMode actual, NSString *reason) {
        AffirmPromoRenderOperation *operation = [[AffirmPromoRenderOperation alloc] initWithRequestedMode:requested];
        [operation selectMode:selected];
        [operation finishWithOutcome:outcome actualRenderer:actual reason:reason];
        return operation.terminalState;
    };
    AffirmPromoRenderMode none = AffirmPromoRenderModeNone, native = AffirmPromoRenderModeNative, html = AffirmPromoRenderModeHTML;
    XCTAssertEqualObjects(state(native, native, AffirmPromoRenderOutcomeSuccess, native, nil), @"T1");
    XCTAssertEqualObjects(state(html, html, AffirmPromoRenderOutcomeSuccess, html, nil), @"T2");
    XCTAssertEqualObjects(state(native, html, AffirmPromoRenderOutcomeSuccess, native, nil), @"T3");
    XCTAssertEqualObjects(state(native, none, AffirmPromoRenderOutcomeFailure, none, AffirmPromoRenderReasonFetchError), @"T4");
    XCTAssertEqualObjects(state(html, html, AffirmPromoRenderOutcomeFailure, none, AffirmPromoRenderReasonHTMLTimeout), @"T5");
    XCTAssertEqualObjects(state(native, html, AffirmPromoRenderOutcomeFailure, none, AffirmPromoRenderReasonHTMLTimeout), @"T6");
    XCTAssertEqualObjects(state(html, html, AffirmPromoRenderOutcomeEmptyContent, none, AffirmPromoRenderReasonMissingHTML), @"T7");
    XCTAssertEqualObjects(state(native, native, AffirmPromoRenderOutcomeFailure, none, AffirmPromoRenderReasonNativeError), @"T8");
    XCTAssertEqualObjects(state(html, none, AffirmPromoRenderOutcomeCancelled, none, AffirmPromoRenderReasonSuperseded), @"T9");
    XCTAssertEqualObjects(state(native, native, AffirmPromoRenderOutcomeCancelled, none, AffirmPromoRenderReasonHostDestroyed), @"T9");
}

- (void)testNativeRenderFinishesAsT1
{
    AffirmPromotionalButton *button = [self promoButton];
    XCTestExpectation *finished = [self expectRenderOf:button finishingIn:@"T1" reason:nil];
    [self configureNative:button];
    XCTAssertEqual(self.promoHandlers.count, 1u);
    [self completePromoRequestAtIndex:0 json:@"{\"promo\": {\"ala\": \"Native message\"}}"];
    [self waitForExpectations:@[finished] timeout:1];
    XCTAssertEqualObjects([self nativeTitleOf:button], @"Native message");
    XCTAssertFalse(button.hidden);
}

- (void)testFetchErrorFinishesAsT4
{
    AffirmPromotionalButton *button = [self promoButton];
    XCTestExpectation *finished = [self expectRenderOf:button finishingIn:@"T4" reason:AffirmPromoRenderReasonFetchError];
    [self configureNative:button];
    self.promoHandlers[0](nil, [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut userInfo:nil]);
    [self waitForExpectations:@[finished] timeout:1];
    XCTAssertTrue(button.hidden);
}

- (void)testExplicitHTMLReadyFinishesAsT2
{
    AffirmPromotionalButton *button = [self promoButton];
    XCTestExpectation *finished = [self expectRenderOf:button finishingIn:@"T2" reason:nil];
    [self configureExplicitHTML:button];
    [self completePromoRequestAtIndex:0 json:@"{\"promo\": {\"ala\": \"Native\", \"html_ala\": \"<span>HTML</span>\"}}"];
    [self waitForExpectations:@[finished] timeout:10];
    XCTAssertFalse(button.hidden);
    XCTAssertFalse([[button valueForKey:@"webView"] isHidden]);
}

- (void)testExplicitHTMLFailureFinishesAsT5AndStaysHidden
{
    AffirmPromotionalButton *button = [self promoButton];
    XCTestExpectation *finished = [self expectRenderOf:button finishingIn:@"T5" reason:AffirmPromoRenderReasonHTMLEmpty];
    [self configureExplicitHTML:button];
    [self completePromoRequestAtIndex:0 json:@"{\"promo\": {\"ala\": \"Native\", \"html_ala\": \"<script>x()</script>\"}}"];
    [self waitForExpectations:@[finished] timeout:10];
    XCTAssertTrue(button.hidden);
    XCTAssertNil([self nativeTitleOf:button]);
}

- (void)testExplicitHTMLWithoutHTMLFinishesAsT7
{
    AffirmPromotionalButton *button = [self promoButton];
    XCTestExpectation *finished = [self expectRenderOf:button finishingIn:@"T7" reason:AffirmPromoRenderReasonMissingHTML];
    [self configureExplicitHTML:button];
    [self completePromoRequestAtIndex:0 json:@"{\"promo\": {\"ala\": \"Native\", \"html_ala\": \"\"}}"];
    [self waitForExpectations:@[finished] timeout:1];
    XCTAssertTrue(button.hidden);
}

- (void)testNewConfigureSupersedesOldRenderAndIgnoresItsLateReply
{
    AffirmPromotionalButton *button = [self promoButton];
    NSMutableArray<AffirmPromoRenderOperation *> *finishedOperations = [NSMutableArray array];
    id observer = [[NSNotificationCenter defaultCenter] addObserverForName:AffirmPromoRenderDidFinishNotification
                                                                    object:button
                                                                     queue:nil
                                                                usingBlock:^(NSNotification *note) {
        [finishedOperations addObject:note.userInfo[AffirmPromoRenderOperationKey]];
    }];

    [self configureNative:button];
    [self configureNative:button];
    XCTAssertEqual(finishedOperations.count, 1u);
    AffirmPromoRenderOperation *first = finishedOperations.firstObject;
    XCTAssertEqualObjects(first.terminalState, @"T9");
    XCTAssertEqualObjects(first.reason, AffirmPromoRenderReasonSuperseded);

    [self completePromoRequestAtIndex:1 json:@"{\"promo\": {\"ala\": \"Newer\"}}"];
    [self completePromoRequestAtIndex:0 json:@"{\"promo\": {\"ala\": \"Older\"}}"];
    [[NSNotificationCenter defaultCenter] removeObserver:observer];

    XCTAssertEqual(finishedOperations.count, 2u);
    XCTAssertEqualObjects(finishedOperations.lastObject.terminalState, @"T1");
    XCTAssertEqualObjects([self nativeTitleOf:button], @"Newer");
}

- (void)testNewConfigureStopsTheOldRendersPageLoad
{
    AffirmPromotionalButton *button = [self promoButton];
    [self configureExplicitHTML:button];
    [self completePromoRequestAtIndex:0 json:@"{\"promo\": {\"html_ala\": \"<span>Older</span>\"}}"];
    NSString *staleRenderID = [button valueForKey:@"htmlRenderID"];
    XCTAssertNotNil(staleRenderID);

    XCTestExpectation *pageOutcome = [self expectationForNotification:AffirmPromoHTMLRenderDidFinishNotification
                                                               object:button
                                                              handler:nil];
    pageOutcome.inverted = YES;
    [self configureNative:button];
    XCTAssertNil([button valueForKey:@"htmlRenderID"]);
    XCTAssertNil([button valueForKey:@"htmlTimeoutTimer"]);
    [self waitForExpectations:@[pageOutcome] timeout:2];
}

- (void)testUnmanagedHTMLSupersedesAManagedRender
{
    AffirmPromotionalButton *button = [self promoButton];
    XCTestExpectation *cancelled = [self expectRenderOf:button finishingIn:@"T9" reason:AffirmPromoRenderReasonSuperseded];
    [self configureNative:button];
    [button configureWithHtmlString:@"<span>direct</span>" amount:[self amount] remoteFontURL:nil remoteCssURL:nil];
    [self waitForExpectations:@[cancelled] timeout:1];

    XCTestExpectation *lateReport = [self expectationForNotification:AffirmPromoRenderDidFinishNotification
                                                              object:button
                                                             handler:nil];
    lateReport.inverted = YES;
    [self completePromoRequestAtIndex:0 json:@"{\"promo\": {\"ala\": \"Late\"}}"];
    XCTAssertNil([self nativeTitleOf:button]);
    [self waitForExpectations:@[lateReport] timeout:0.5];
}

- (void)testDeallocatedViewFinishesAsHostDestroyedAndIgnoresTheReply
{
    __weak AffirmPromotionalButton *weakButton = nil;
    XCTestExpectation *destroyed = [self expectationForNotification:AffirmPromoRenderDidFinishNotification
                                                             object:nil
                                                            handler:^BOOL(NSNotification *note) {
        AffirmPromoRenderOperation *operation = note.userInfo[AffirmPromoRenderOperationKey];
        XCTAssertNil(note.object);
        XCTAssertEqualObjects(operation.terminalState, @"T9");
        XCTAssertEqualObjects(operation.reason, AffirmPromoRenderReasonHostDestroyed);
        return YES;
    }];
    @autoreleasepool {
        AffirmPromotionalButton *button = [self promoButton];
        weakButton = button;
        [self configureNative:button];
        [button removeFromSuperview];
    }
    XCTAssertNil(weakButton);
    [self waitForExpectations:@[destroyed] timeout:1];

    XCTestExpectation *lateReport = [self expectationForNotification:AffirmPromoRenderDidFinishNotification
                                                              object:nil
                                                             handler:nil];
    lateReport.inverted = YES;
    [self completePromoRequestAtIndex:0 json:@"{\"promo\": {\"ala\": \"Late\"}}"];
    [self waitForExpectations:@[lateReport] timeout:0.5];
}

- (void)testLeavingTheWindowDoesNotCancelTheRender
{
    AffirmPromotionalButton *button = [self promoButton];
    XCTestExpectation *finished = [self expectRenderOf:button finishingIn:@"T1" reason:nil];
    [self configureNative:button];
    [button removeFromSuperview];
    XCTAssertNil(button.window);
    [self completePromoRequestAtIndex:0 json:@"{\"promo\": {\"ala\": \"Offscreen\"}}"];
    [self waitForExpectations:@[finished] timeout:1];
    XCTAssertEqualObjects([self nativeTitleOf:button], @"Offscreen");
}

- (void)testContentProcessLossBeforeReadyFailsTheRender
{
    AffirmPromotionalButton *button = [self promoButton];
    XCTestExpectation *finished = [self expectRenderOf:button finishingIn:@"T5" reason:AffirmPromoRenderReasonRenderProcessGone];
    [self configureExplicitHTML:button];
    [self completePromoRequestAtIndex:0 json:@"{\"promo\": {\"html_ala\": \"<span>HTML</span>\"}}"];
    WKWebView *webView = [button valueForKey:@"webView"];
    [(id<WKNavigationDelegate>)button webViewWebContentProcessDidTerminate:webView];
    [self waitForExpectations:@[finished] timeout:1];
    XCTAssertTrue(button.hidden);
}

- (void)testContentProcessLossAfterReadyHidesWithoutReporting
{
    AffirmPromotionalButton *button = [self promoButton];
    XCTestExpectation *finished = [self expectRenderOf:button finishingIn:@"T2" reason:nil];
    [self configureExplicitHTML:button];
    [self completePromoRequestAtIndex:0 json:@"{\"promo\": {\"html_ala\": \"<span>HTML</span>\"}}"];
    [self waitForExpectations:@[finished] timeout:10];
    XCTAssertFalse(button.hidden);

    XCTestExpectation *renderReport = [self expectationForNotification:AffirmPromoRenderDidFinishNotification
                                                                object:button
                                                               handler:nil];
    renderReport.inverted = YES;
    XCTestExpectation *pageReport = [self expectationForNotification:AffirmPromoHTMLRenderDidFinishNotification
                                                              object:button
                                                             handler:nil];
    pageReport.inverted = YES;
    WKWebView *webView = [button valueForKey:@"webView"];
    [(id<WKNavigationDelegate>)button webViewWebContentProcessDidTerminate:webView];
    XCTAssertTrue(button.hidden);
    XCTAssertTrue(webView.hidden);
    [self waitForExpectations:@[renderReport, pageReport] timeout:0.5];
}

- (AffirmResponse *)responseForJSON:(NSString *)json
{
    return [AffirmPromoResponse parse:[json dataUsingEncoding:NSUTF8StringEncoding]];
}

- (AffirmPromoResponse *)promoResponseWithConfig:(NSString *)config
{
    NSString *json = [NSString stringWithFormat:
                      @"{\"promo\": {\"ala\": \"Native message\", \"html_ala\": \"<span>HTML</span>\"%@}}",
                      config ? [@", \"config\": " stringByAppendingString:config] : @""];
    AffirmResponse *response = [self responseForJSON:json];
    XCTAssertTrue([response isKindOfClass:[AffirmPromoResponse class]], @"%@", json);
    return (AffirmPromoResponse *)response;
}

- (AffirmPromoResponse *)promoResponseWithFlag:(NSString *)flagJSON
{
    return [self promoResponseWithConfig:[NSString stringWithFormat:@"{\"ios_sdk_migrate_native_to_html_render\": %@}", flagJSON]];
}

- (void)testRenderFlagKeyIsTheDocumentedKey
{
    XCTAssertEqualObjects(AffirmPromoRenderFlagKey, @"ios_sdk_migrate_native_to_html_render");
}

- (void)testRenderFlagAcceptsOnlyAJSONBooleanTrue
{
    AffirmPromoResponse *flagOn = [self promoResponseWithFlag:@"true"];
    XCTAssertEqual(flagOn.renderFlagStatus, AffirmPromoRenderFlagStatusTrue);
    XCTAssertTrue(flagOn.renderFlagEnabled);

    AffirmPromoResponse *flagOff = [self promoResponseWithFlag:@"false"];
    XCTAssertEqual(flagOff.renderFlagStatus, AffirmPromoRenderFlagStatusFalse);
    XCTAssertFalse(flagOff.renderFlagEnabled);

    AffirmPromoResponse *flagNull = [self promoResponseWithFlag:@"null"];
    XCTAssertEqual(flagNull.renderFlagStatus, AffirmPromoRenderFlagStatusNull);
    XCTAssertFalse(flagNull.renderFlagEnabled);

    for (NSString *malformed in @[@"\"true\"", @"1", @"0", @"1.0", @"{}", @"{\"value\": true}", @"[]", @"[true]"]) {
        AffirmPromoResponse *response = [self promoResponseWithFlag:malformed];
        XCTAssertEqual(response.renderFlagStatus, AffirmPromoRenderFlagStatusMalformed, @"%@", malformed);
        XCTAssertFalse(response.renderFlagEnabled, @"%@", malformed);
    }
}

- (void)testRenderFlagIsMissingWithoutTheExactKey
{
    XCTAssertEqual([self promoResponseWithConfig:nil].renderFlagStatus, AffirmPromoRenderFlagStatusMissing);
    XCTAssertEqual([self promoResponseWithConfig:@"{}"].renderFlagStatus, AffirmPromoRenderFlagStatusMissing);
    XCTAssertEqual([self promoResponseWithConfig:@"null"].renderFlagStatus, AffirmPromoRenderFlagStatusMissing);
    XCTAssertEqual([self promoResponseWithConfig:@"\"config\""].renderFlagStatus, AffirmPromoRenderFlagStatusMissing);
    XCTAssertEqual([self promoResponseWithConfig:@"[true]"].renderFlagStatus, AffirmPromoRenderFlagStatusMissing);
    for (NSString *key in @[@"ios_sdk_migrate_native_to_html", @"IOS_SDK_MIGRATE_NATIVE_TO_HTML_RENDER",
                            @"android_sdk_migrate_native_to_html_render", @"migrate_native_to_html_render"]) {
        NSString *config = [NSString stringWithFormat:@"{\"%@\": true}", key];
        AffirmPromoResponse *response = [self promoResponseWithConfig:config];
        XCTAssertEqual(response.renderFlagStatus, AffirmPromoRenderFlagStatusMissing, @"%@", key);
        XCTAssertFalse(response.renderFlagEnabled, @"%@", key);
    }
}

- (void)testResponseKeepsBothMessagesWhateverTheFlag
{
    for (NSString *flag in @[@"true", @"false", @"null", @"\"yes\"", @"[]"]) {
        AffirmPromoResponse *response = [self promoResponseWithFlag:flag];
        XCTAssertEqualObjects(response.ala, @"Native message", @"%@", flag);
        XCTAssertEqualObjects(response.htmlAla, @"<span>HTML</span>", @"%@", flag);
    }
}

- (void)testRenderFlagAloneDoesNotTurnOnPrequal
{
    XCTAssertFalse([self promoResponseWithConfig:nil].showPrequal);
    XCTAssertFalse([self promoResponseWithFlag:@"true"].showPrequal);
    XCTAssertFalse([self promoResponseWithFlag:@"false"].showPrequal);
    XCTAssertFalse([self promoResponseWithFlag:@"\"malformed\""].showPrequal);

    XCTAssertTrue([self promoResponseWithConfig:@"{}"].showPrequal);
    XCTAssertTrue([self promoResponseWithConfig:@"{\"promo_style\": \"simple\"}"].showPrequal);
    XCTAssertTrue([self promoResponseWithConfig:@"{\"promo_style\": \"simple\", \"ios_sdk_migrate_native_to_html_render\": true}"].showPrequal);
    XCTAssertFalse([self promoResponseWithConfig:@"{\"promo_style\": \"fast\"}"].showPrequal);
    XCTAssertFalse([self promoResponseWithConfig:@"{\"promo_style\": \"fast\", \"ios_sdk_migrate_native_to_html_render\": true}"].showPrequal);
    XCTAssertTrue([self promoResponseWithConfig:@"{\"promo_style\": 1}"].showPrequal);
}

- (void)testParserToleratesUnexpectedTypes
{
    XCTAssertFalse([[self promoResponseWithConfig:@"null"] showPrequal]);
    XCTAssertFalse([[self promoResponseWithConfig:@"\"config\""] showPrequal]);
    XCTAssertFalse([[self promoResponseWithConfig:@"[{\"promo_style\": \"simple\"}]"] showPrequal]);

    AffirmPromoResponse *wrongTypes = (AffirmPromoResponse *)[self responseForJSON:
                                                              @"{\"promo\": {\"ala\": 42, \"html_ala\": [\"<b>x</b>\"], \"config\": {\"ios_sdk_migrate_native_to_html_render\": true}}}"];
    XCTAssertTrue([wrongTypes isKindOfClass:[AffirmPromoResponse class]]);
    XCTAssertEqualObjects(wrongTypes.ala, @"");
    XCTAssertEqualObjects(wrongTypes.htmlAla, @"");
    XCTAssertTrue(wrongTypes.renderFlagEnabled);

    AffirmPromoResponse *nulls = (AffirmPromoResponse *)[self responseForJSON:@"{\"promo\": {\"ala\": null, \"html_ala\": null}}"];
    XCTAssertEqualObjects(nulls.ala, @"");
    XCTAssertEqualObjects(nulls.htmlAla, @"");

    XCTAssertTrue([[self responseForJSON:@"{\"promo\": \"text\"}"] isKindOfClass:[AffirmErrorResponse class]]);
    XCTAssertTrue([[self responseForJSON:@"{\"promo\": [1, 2]}"] isKindOfClass:[AffirmErrorResponse class]]);
    XCTAssertTrue([[self responseForJSON:@"[{\"promo\": {}}]"] isKindOfClass:[AffirmErrorResponse class]]);
    XCTAssertTrue([[self responseForJSON:@"not json"] isKindOfClass:[AffirmErrorResponse class]]);
}

- (void)testAffirmLogoPlaceholderStillBecomesAffirm
{
    AffirmPromoResponse *response = (AffirmPromoResponse *)[self responseForJSON:
                                                            @"{\"promo\": {\"ala\": \"Pay with {affirm_logo}\", \"config\": {\"ios_sdk_migrate_native_to_html_render\": true}}}"];
    XCTAssertEqualObjects(response.ala, @"Pay with Affirm");
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
