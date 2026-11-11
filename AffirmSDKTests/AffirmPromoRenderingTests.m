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
    [AffirmConfiguration sharedInstance].useLegacyNativeRendering = NO;
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

#pragma mark - Renderer selection

- (void)configureNative:(AffirmPromotionalButton *)button font:(UIFont *)font
{
    [button configureWithAmount:[self amount]
                 affirmLogoType:AffirmLogoTypeText
                    affirmColor:AffirmColorTypeBlue
                           font:font
                      textColor:[UIColor blackColor]];
}

- (NSString *)promoJSONWithAla:(NSString *)ala html:(NSString *)html flag:(NSString *)flag
{
    NSMutableArray *fields = [NSMutableArray array];
    if (ala) {
        [fields addObject:[NSString stringWithFormat:@"\"ala\": \"%@\"", ala]];
    }
    if (html) {
        [fields addObject:[NSString stringWithFormat:@"\"html_ala\": \"%@\"", html]];
    }
    if (flag) {
        [fields addObject:[NSString stringWithFormat:@"\"config\": {\"ios_sdk_migrate_native_to_html_render\": %@}", flag]];
    }
    return [NSString stringWithFormat:@"{\"promo\": {%@}}", [fields componentsJoinedByString:@", "]];
}

- (XCTestExpectation *)expectRenderOf:(AffirmPromotionalButton *)button
                          finishingIn:(NSString *)state
                       decisionReason:(NSString *)decisionReason
                       fallbackReason:(nullable NSString *)fallbackReason
{
    return [self expectationForNotification:AffirmPromoRenderDidFinishNotification
                                     object:button
                                    handler:^BOOL(NSNotification *note) {
        AffirmPromoRenderOperation *operation = note.userInfo[AffirmPromoRenderOperationKey];
        XCTAssertEqualObjects(operation.terminalState, state);
        XCTAssertEqualObjects(operation.decisionReason, decisionReason);
        XCTAssertEqualObjects(operation.fallbackReason, fallbackReason);
        return YES;
    }];
}

- (UIFont *)font:(UIFont *)font withTraits:(UIFontDescriptorSymbolicTraits)traits
{
    return [UIFont fontWithDescriptor:[font.fontDescriptor fontDescriptorWithSymbolicTraits:traits] size:font.pointSize];
}

- (void)assertFont:(UIFont *)font mapsTo:(NSString *)family bold:(BOOL)bold italic:(BOOL)italic
{
    AffirmPromoFontStyle *style = AffirmPromoFontStyleForFont(font);
    XCTAssertNotNil(style, @"%@", font.fontName);
    XCTAssertEqualObjects(style.cssFamily, family, @"%@", font.fontName);
    XCTAssertEqual(style.bold, bold, @"%@", font.fontName);
    XCTAssertEqual(style.italic, italic, @"%@", font.fontName);
    XCTAssertEqual(style.pointSize, font.pointSize, @"%@", font.fontName);
}

- (void)testTheTwelveBuiltInFontsMapToHTML
{
    UIFont *system = [UIFont systemFontOfSize:17];
    UIFont *serif = [UIFont fontWithDescriptor:[system.fontDescriptor fontDescriptorWithDesign:UIFontDescriptorSystemDesignSerif] size:17];
    UIFont *mono = [UIFont monospacedSystemFontOfSize:17 weight:UIFontWeightRegular];
    NSDictionary<NSString *, UIFont *> *designs = @{@"system-ui": system, @"ui-serif": serif, @"ui-monospace": mono};
    for (NSString *family in designs) {
        UIFont *base = designs[family];
        [self assertFont:base mapsTo:family bold:NO italic:NO];
        [self assertFont:[self font:base withTraits:UIFontDescriptorTraitBold] mapsTo:family bold:YES italic:NO];
        [self assertFont:[self font:base withTraits:UIFontDescriptorTraitItalic] mapsTo:family bold:NO italic:YES];
        [self assertFont:[self font:base withTraits:UIFontDescriptorTraitBold | UIFontDescriptorTraitItalic] mapsTo:family bold:YES italic:YES];
    }
    [self assertFont:[UIFont boldSystemFontOfSize:13] mapsTo:@"system-ui" bold:YES italic:NO];
    [self assertFont:[UIFont italicSystemFontOfSize:13] mapsTo:@"system-ui" bold:NO italic:YES];
    [self assertFont:[UIFont preferredFontForTextStyle:UIFontTextStyleBody] mapsTo:@"system-ui" bold:NO italic:NO];
}

- (void)testOtherFontsHaveNoHTMLMapping
{
    UIFont *system = [UIFont systemFontOfSize:17];
    UIFont *rounded = [UIFont fontWithDescriptor:[system.fontDescriptor fontDescriptorWithDesign:UIFontDescriptorSystemDesignRounded] size:17];
    NSArray<UIFont *> *fonts = @[
        rounded,
        [UIFont systemFontOfSize:17 weight:UIFontWeightLight],
        [UIFont systemFontOfSize:17 weight:UIFontWeightHeavy],
        [UIFont monospacedSystemFontOfSize:17 weight:UIFontWeightLight],
        [UIFont fontWithName:@"Georgia" size:17],
        [UIFont fontWithName:@"Helvetica" size:17],
        [UIFont fontWithName:@"Courier" size:17],
    ];
    for (UIFont *font in fonts) {
        XCTAssertNil(AffirmPromoFontStyleForFont(font), @"%@", font.fontName);
    }
    XCTAssertNil(AffirmPromoFontStyleForFont(nil));
}

- (void)testDecisionAppliesTheFirstMatchingRule
{
    UIFont *supported = [UIFont systemFontOfSize:15];
    UIFont *unsupported = [UIFont fontWithName:@"Georgia" size:15];
    AffirmPromoRenderMode native = AffirmPromoRenderModeNative, html = AffirmPromoRenderModeHTML;

    void (^check)(AffirmPromoRenderMode, BOOL, UIFont *, AffirmPromoRenderFlagStatus, AffirmPromoRenderMode, NSString *) =
    ^(AffirmPromoRenderMode requested, BOOL optOut, UIFont *font, AffirmPromoRenderFlagStatus flag, AffirmPromoRenderMode expected, NSString *expectedReason) {
        AffirmPromoRenderPolicy *policy = [[AffirmPromoRenderPolicy alloc] initWithRequestedMode:requested optOut:optOut font:font];
        NSString *reason = nil;
        XCTAssertEqual([policy modeForFlagStatus:flag reason:&reason], expected, @"%@", expectedReason);
        XCTAssertEqualObjects(reason, expectedReason);
    };
    // 1. Explicit HTML beats the opt-out, the font and the flag.
    check(html, YES, nil, AffirmPromoRenderFlagStatusFalse, html, AffirmPromoDecisionReasonExplicitHTML);
    check(html, NO, unsupported, AffirmPromoRenderFlagStatusMissing, html, AffirmPromoDecisionReasonExplicitHTML);
    // 2. Opt-out beats the font and the flag.
    check(native, YES, unsupported, AffirmPromoRenderFlagStatusTrue, native, AffirmPromoDecisionReasonOptOut);
    check(native, YES, supported, AffirmPromoRenderFlagStatusTrue, native, AffirmPromoDecisionReasonOptOut);
    // 3. An unsupported font beats the flag.
    check(native, NO, unsupported, AffirmPromoRenderFlagStatusTrue, native, AffirmPromoDecisionReasonUnsupportedFont);
    check(native, NO, nil, AffirmPromoRenderFlagStatusTrue, native, AffirmPromoDecisionReasonUnsupportedFont);
    // 4. A true flag gives HTML. 5. Anything else gives native.
    check(native, NO, supported, AffirmPromoRenderFlagStatusTrue, html, AffirmPromoDecisionReasonFlagTrue);
    check(native, NO, supported, AffirmPromoRenderFlagStatusFalse, native, AffirmPromoDecisionReasonFlagFalse);
    check(native, NO, supported, AffirmPromoRenderFlagStatusMissing, native, AffirmPromoDecisionReasonFlagMissing);
    check(native, NO, supported, AffirmPromoRenderFlagStatusNull, native, AffirmPromoDecisionReasonFlagNull);
    check(native, NO, supported, AffirmPromoRenderFlagStatusMalformed, native, AffirmPromoDecisionReasonFlagMalformed);
}

- (void)testDecisionIsMadeOncePerRender
{
    AffirmPromoRenderPolicy *policy = [[AffirmPromoRenderPolicy alloc] initWithRequestedMode:AffirmPromoRenderModeNative
                                                                                      optOut:NO
                                                                                        font:[UIFont systemFontOfSize:15]];
    AffirmPromoRenderOperation *operation = [[AffirmPromoRenderOperation alloc] initWithPolicy:policy];
    XCTAssertEqual([operation decideWithFlagStatus:AffirmPromoRenderFlagStatusTrue], AffirmPromoRenderModeHTML);
    XCTAssertEqual([operation decideWithFlagStatus:AffirmPromoRenderFlagStatusFalse], AffirmPromoRenderModeHTML);
    XCTAssertEqualObjects(operation.decisionReason, AffirmPromoDecisionReasonFlagTrue);
}

- (void)testOptOutIsReadWhenConfigureStarts
{
    AffirmPromotionalButton *button = [self promoButton];
    XCTestExpectation *finished = [self expectRenderOf:button finishingIn:@"T2"
                                        decisionReason:AffirmPromoDecisionReasonFlagTrue fallbackReason:nil];
    [self configureNative:button font:[UIFont systemFontOfSize:15]];
    [AffirmConfiguration sharedInstance].useLegacyNativeRendering = YES;
    [self completePromoRequestAtIndex:0 json:[self promoJSONWithAla:@"Native" html:@"<span>HTML</span>" flag:@"true"]];
    [self waitForExpectations:@[finished] timeout:10];

    XCTestExpectation *optedOut = [self expectRenderOf:button finishingIn:@"T1"
                                        decisionReason:AffirmPromoDecisionReasonOptOut fallbackReason:nil];
    [self configureNative:button font:[UIFont systemFontOfSize:15]];
    [AffirmConfiguration sharedInstance].useLegacyNativeRendering = NO;
    [self completePromoRequestAtIndex:1 json:[self promoJSONWithAla:@"Native" html:@"<span>HTML</span>" flag:@"true"]];
    [self waitForExpectations:@[optedOut] timeout:1];
    XCTAssertEqualObjects([self nativeTitleOf:button], @"Native");
}

- (void)testUnsupportedFontStaysNativeWhenTheFlagIsOn
{
    AffirmPromotionalButton *button = [self promoButton];
    XCTestExpectation *finished = [self expectRenderOf:button finishingIn:@"T1"
                                        decisionReason:AffirmPromoDecisionReasonUnsupportedFont fallbackReason:nil];
    [self configureNative:button font:[UIFont fontWithName:@"Georgia" size:15]];
    [self completePromoRequestAtIndex:0 json:[self promoJSONWithAla:@"Native" html:@"<span>HTML</span>" flag:@"true"]];
    [self waitForExpectations:@[finished] timeout:1];
    XCTAssertEqualObjects([self nativeTitleOf:button], @"Native");
    XCTAssertTrue([[button valueForKey:@"webView"] isHidden]);
}

- (void)testFlagOffStaysNative
{
    AffirmPromotionalButton *button = [self promoButton];
    XCTestExpectation *finished = [self expectRenderOf:button finishingIn:@"T1"
                                        decisionReason:AffirmPromoDecisionReasonFlagFalse fallbackReason:nil];
    [self configureNative:button font:[UIFont systemFontOfSize:15]];
    [self completePromoRequestAtIndex:0 json:[self promoJSONWithAla:@"Native" html:@"<span>HTML</span>" flag:@"false"]];
    [self waitForExpectations:@[finished] timeout:1];
    XCTAssertEqualObjects([self nativeTitleOf:button], @"Native");
}

- (void)testMigratedCallShowsHTMLOnATransparentWebView
{
    AffirmPromotionalButton *button = [self promoButton];
    XCTestExpectation *finished = [self expectRenderOf:button finishingIn:@"T2"
                                        decisionReason:AffirmPromoDecisionReasonFlagTrue fallbackReason:nil];
    [self configureNative:button font:[UIFont boldSystemFontOfSize:15]];
    [self completePromoRequestAtIndex:0 json:[self promoJSONWithAla:@"Native" html:@"<span>HTML</span>" flag:@"true"]];
    [self waitForExpectations:@[finished] timeout:10];
    WKWebView *webView = [button valueForKey:@"webView"];
    XCTAssertFalse(webView.hidden);
    XCTAssertFalse(webView.opaque);
    XCTAssertNil([self nativeTitleOf:button]);
}

- (void)testExplicitHTMLKeepsTheOpaqueWebView
{
    AffirmPromotionalButton *button = [self promoButton];
    XCTestExpectation *finished = [self expectRenderOf:button finishingIn:@"T2"
                                        decisionReason:AffirmPromoDecisionReasonExplicitHTML fallbackReason:nil];
    [AffirmConfiguration sharedInstance].useLegacyNativeRendering = YES;
    [self configureExplicitHTML:button];
    [self completePromoRequestAtIndex:0 json:[self promoJSONWithAla:@"Native" html:@"<span>HTML</span>" flag:@"false"]];
    [self waitForExpectations:@[finished] timeout:10];
    XCTAssertTrue([[button valueForKey:@"webView"] isOpaque]);
}

- (void)testMigratedHTMLFailureFallsBackToNativeText
{
    AffirmPromotionalButton *button = [self promoButton];
    XCTestExpectation *finished = [self expectRenderOf:button finishingIn:@"T3"
                                        decisionReason:AffirmPromoDecisionReasonFlagTrue
                                        fallbackReason:AffirmPromoRenderReasonHTMLEmpty];
    [self configureNative:button font:[UIFont systemFontOfSize:15]];
    [self completePromoRequestAtIndex:0 json:[self promoJSONWithAla:@"Native" html:@"<script>x()</script>" flag:@"true"]];
    [self waitForExpectations:@[finished] timeout:10];
    XCTAssertEqualObjects([self nativeTitleOf:button], @"Native");
    XCTAssertFalse(button.hidden);
    XCTAssertTrue([[button valueForKey:@"webView"] isHidden]);
    XCTAssertEqual(self.promoHandlers.count, 1u);
}

- (void)testMigratedCallWithoutHTMLFallsBackToNativeText
{
    AffirmPromotionalButton *button = [self promoButton];
    XCTestExpectation *finished = [self expectRenderOf:button finishingIn:@"T3"
                                        decisionReason:AffirmPromoDecisionReasonFlagTrue
                                        fallbackReason:AffirmPromoRenderReasonMissingHTML];
    [self configureNative:button font:[UIFont systemFontOfSize:15]];
    [self completePromoRequestAtIndex:0 json:[self promoJSONWithAla:@"Native" html:@"" flag:@"true"]];
    [self waitForExpectations:@[finished] timeout:1];
    XCTAssertEqualObjects([self nativeTitleOf:button], @"Native");
}

- (void)testMigratedHTMLFailureWithoutNativeTextHides
{
    AffirmPromotionalButton *button = [self promoButton];
    XCTestExpectation *finished = [self expectRenderOf:button finishingIn:@"T6"
                                        decisionReason:AffirmPromoDecisionReasonFlagTrue
                                        fallbackReason:AffirmPromoRenderReasonHTMLEmpty];
    [self configureNative:button font:[UIFont systemFontOfSize:15]];
    [self completePromoRequestAtIndex:0 json:[self promoJSONWithAla:@"" html:@"<script>x()</script>" flag:@"true"]];
    [self waitForExpectations:@[finished] timeout:10];
    XCTAssertTrue(button.hidden);
}

- (void)testMigratedCallWithNoContentFinishesAsT7
{
    AffirmPromotionalButton *button = [self promoButton];
    XCTestExpectation *finished = [self expectRenderOf:button finishingIn:@"T7"
                                        decisionReason:AffirmPromoDecisionReasonFlagTrue
                                        fallbackReason:AffirmPromoRenderReasonMissingHTML];
    [self configureNative:button font:[UIFont systemFontOfSize:15]];
    [self completePromoRequestAtIndex:0 json:[self promoJSONWithAla:nil html:nil flag:@"true"]];
    [self waitForExpectations:@[finished] timeout:1];
    XCTAssertTrue(button.hidden);
}

#pragma mark - Existing web view

- (void)assertWebViewIsSetUpIn:(AffirmPromotionalButton *)button
{
    WKWebView *webView = [button valueForKey:@"webView"];
    UIButton *overlay = [button valueForKey:@"button"];
    XCTAssertNotNil(webView);
    XCTAssertTrue(webView.hidden);
    XCTAssertEqual(webView.superview, button);
    XCTAssertEqual(overlay.superview, button);
    XCTAssertGreaterThan([button.subviews indexOfObject:overlay], [button.subviews indexOfObject:webView]);
    XCTAssertEqualObjects([overlay actionsForTarget:button forControlEvent:UIControlEventTouchUpInside], @[@"showALAModal:"]);

    NSArray<WKUserScript *> *scripts = webView.configuration.userContentController.userScripts;
    XCTAssertEqual(scripts.count, 1u);
    XCTAssertEqual(scripts.firstObject.injectionTime, WKUserScriptInjectionTimeAtDocumentStart);
    XCTAssertTrue(scripts.firstObject.isForMainFrameOnly);
    XCTAssertEqualObjects(scripts.firstObject.source, AffirmPromoSanitizerSource());
}

- (void)testSetupCreatesTheWebViewAndOverlayBeforeAnyResponse
{
    AffirmPromotionalButton *button = [self promoButton];
    [self assertWebViewIsSetUpIn:button];
    XCTAssertEqual(self.promoHandlers.count, 0u);
}

- (void)testNibLoadedViewGetsTheWebView
{
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initRequiringSecureCoding:NO];
    [archiver setClassName:NSStringFromClass([AffirmPromotionalButton class]) forClass:[UIView class]];
    [archiver encodeObject:[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 44)] forKey:NSKeyedArchiveRootObjectKey];
    [archiver finishEncoding];
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingFromData:archiver.encodedData error:nil];
    unarchiver.requiresSecureCoding = NO;
    AffirmPromotionalButton *button = [unarchiver decodeObjectForKey:NSKeyedArchiveRootObjectKey];
    XCTAssertTrue([button isKindOfClass:[AffirmPromotionalButton class]]);
    [button awakeFromNib];
    [self assertWebViewIsSetUpIn:button];
}

- (void)testEveryRenderReusesTheSameWebView
{
    AffirmPromotionalButton *button = [self promoButton];
    WKWebView *webView = [button valueForKey:@"webView"];

    XCTestExpectation *explicitReady = [self expectRenderOf:button finishingIn:@"T2" reason:nil];
    [self configureExplicitHTML:button];
    [self completePromoRequestAtIndex:0 json:[self promoJSONWithAla:@"Native" html:@"<span>Explicit</span>" flag:nil]];
    [self waitForExpectations:@[explicitReady] timeout:10];
    XCTAssertEqual([button valueForKey:@"webView"], webView);
    XCTAssertTrue(webView.opaque);

    XCTestExpectation *migratedReady = [self expectRenderOf:button finishingIn:@"T2" reason:nil];
    [self configureNative:button font:[UIFont systemFontOfSize:15]];
    [self completePromoRequestAtIndex:1 json:[self promoJSONWithAla:@"Native" html:@"<span>Migrated</span>" flag:@"true"]];
    [self waitForExpectations:@[migratedReady] timeout:10];
    XCTAssertEqual([button valueForKey:@"webView"], webView);
    XCTAssertFalse(webView.opaque);
    XCTAssertEqualObjects(webView.backgroundColor, [UIColor clearColor]);

    XCTestExpectation *directReady = [self expectationForNotification:AffirmPromoHTMLRenderDidFinishNotification
                                                               object:button
                                                              handler:^BOOL(NSNotification *note) {
        return [note.userInfo[@"outcome"] isEqualToString:@"ready"];
    }];
    [button configureWithHtmlString:@"<span>Direct</span>" amount:[self amount] remoteFontURL:nil remoteCssURL:nil];
    [self waitForExpectations:@[directReady] timeout:10];
    XCTAssertEqual([button valueForKey:@"webView"], webView);
    XCTAssertTrue(webView.opaque);
    XCTAssertEqualObjects(webView.backgroundColor, [button valueForKey:@"defaultWebViewBackgroundColor"]);
    XCTAssertEqual(webView.configuration.userContentController.userScripts.count, 1u);
}

- (void)testOverlayReceivesTapsWhileHTMLIsShown
{
    AffirmPromotionalButton *button = [self promoButton];
    XCTestExpectation *finished = [self expectRenderOf:button finishingIn:@"T2" reason:nil];
    [self configureNative:button font:[UIFont systemFontOfSize:15]];
    [self completePromoRequestAtIndex:0 json:[self promoJSONWithAla:@"Native" html:@"<span>HTML</span>" flag:@"true"]];
    [self waitForExpectations:@[finished] timeout:10];
    [button layoutIfNeeded];

    CGPoint center = CGPointMake(CGRectGetMidX(button.bounds), CGRectGetMidY(button.bounds));
    XCTAssertEqual([button hitTest:center withEvent:nil], [button valueForKey:@"button"]);
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

#pragma mark - Sanitization and fallback

// Real sandbox responses, read from the source tree; tests run on the simulator only.
- (NSDictionary<NSString *, NSDictionary *> *)promoFixtures
{
    NSString *directory = [[NSString stringWithUTF8String:__FILE__] stringByDeletingLastPathComponent];
    NSData *data = [NSData dataWithContentsOfFile:[directory stringByAppendingPathComponent:@"Fixtures/promo-responses.json"]];
    XCTAssertNotNil(data);
    NSMutableDictionary *fixtures = [[NSJSONSerialization JSONObjectWithData:data options:0 error:nil] mutableCopy];
    [fixtures removeObjectForKey:@"_source"];
    return fixtures;
}

- (id)evaluate:(NSString *)script in:(AffirmPromotionalButton *)button
{
    WKWebView *webView = [button valueForKey:@"webView"];
    XCTestExpectation *done = [self expectationWithDescription:script];
    __block id value;
    [webView evaluateJavaScript:script completionHandler:^(id result, NSError *error) {
        XCTAssertNil(error, @"%@", script);
        value = result;
        [done fulfill];
    }];
    [self waitForExpectations:@[done] timeout:5];
    return value;
}

- (XCTestExpectation *)expectPageReadyOf:(AffirmPromotionalButton *)button
{
    return [self expectationForNotification:AffirmPromoHTMLRenderDidFinishNotification
                                     object:button
                                    handler:^BOOL(NSNotification *note) {
        XCTAssertEqualObjects(note.userInfo[@"outcome"], @"ready", @"%@", note.userInfo[@"reason"]);
        return YES;
    }];
}

- (void)showHTML:(NSString *)html in:(AffirmPromotionalButton *)button remoteCssURL:(nullable NSURL *)css
{
    XCTestExpectation *ready = [self expectPageReadyOf:button];
    [button configureWithHtmlString:html amount:[self amount] remoteFontURL:nil remoteCssURL:css];
    [self waitForExpectations:@[ready] timeout:10];
}

- (void)testRealPromoResponsesKeepEveryElementAfterSanitizing
{
    AffirmPromotionalButton *button = [self promoButton];
    NSMutableSet<NSString *> *seen = [NSMutableSet set];
    [[self promoFixtures] enumerateKeysAndObjectsUsingBlock:^(NSString *name, NSDictionary *response, BOOL *stop) {
        NSString *html = response[@"promo"][@"html_ala"];
        // The same HTML on a visible button is reused without a new page load.
        if ([seen containsObject:html]) {
            return;
        }
        [seen addObject:html];
        [self showHTML:html in:button remoteCssURL:nil];
        NSData *source = [NSJSONSerialization dataWithJSONObject:@[html] options:0 error:nil];
        NSString *script = [NSString stringWithFormat:
            @"(function (source) {"
            @"  var reference = document.createElement('div');"
            @"  reference.innerHTML = source;"
            @"  return reference.innerHTML === document.getElementById('affirm-promo-root').innerHTML;"
            @"})(%@[0])", [[NSString alloc] initWithData:source encoding:NSUTF8StringEncoding]];
        XCTAssertEqualObjects([self evaluate:script in:button], @YES, @"%@", name);
        NSString *root = [self evaluate:@"document.getElementById('affirm-promo-root').innerHTML" in:button];
        XCTAssertTrue([root containsString:@"class=\"affirm-ala-price\""], @"%@", name);
        XCTAssertTrue([root containsString:@"class=\"affirm-modal-trigger\""], @"%@", name);
        if ([html containsString:@"__apr_badge"]) {
            XCTAssertTrue([root containsString:@"class=\"__apr_badge __apr_badge_indigo\""], @"%@", name);
        }
    }];
}

- (void)testMigratedRealResponseRendersAsHTMLWithoutBodyMargin
{
    AffirmPromotionalButton *button = [self promoButton];
    XCTestExpectation *finished = [self expectRenderOf:button finishingIn:@"T2"
                                        decisionReason:AffirmPromoDecisionReasonFlagTrue fallbackReason:nil];
    [self configureNative:button];
    NSData *json = [NSJSONSerialization dataWithJSONObject:[self promoFixtures][@"installment_badge_logo_flag_on"] options:0 error:nil];
    [self completePromoRequestAtIndex:0 json:[[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding]];
    [self waitForExpectations:@[finished] timeout:10];
    XCTAssertEqualObjects([self evaluate:@"getComputedStyle(document.body).marginTop" in:button], @"0px");
    NSString *root = [self evaluate:@"document.getElementById('affirm-promo-root').innerHTML" in:button];
    XCTAssertTrue([root containsString:@"__apr_badge_indigo"]);
}

- (void)testExplicitHTMLKeepsTheBrowserBodyMargin
{
    AffirmPromotionalButton *button = [self promoButton];
    [self showHTML:@"<span>ok</span>" in:button remoteCssURL:nil];
    XCTAssertEqualObjects([self evaluate:@"getComputedStyle(document.body).marginTop" in:button], @"8px");
}

- (void)testSameHTMLReloadsWhenSwitchingBetweenMigratedAndExplicit
{
    AffirmPromotionalButton *button = [self promoButton];
    XCTestExpectation *migrated = [self expectRenderOf:button finishingIn:@"T2"
                                        decisionReason:AffirmPromoDecisionReasonFlagTrue fallbackReason:nil];
    [self configureNative:button];
    [self completePromoRequestAtIndex:0 json:[self promoJSONWithAla:@"Native" html:@"<span>HTML</span>" flag:@"true"]];
    [self waitForExpectations:@[migrated] timeout:10];

    [self showHTML:@"<span>HTML</span>" in:button remoteCssURL:nil];
    XCTAssertEqualObjects([self evaluate:@"getComputedStyle(document.body).marginTop" in:button], @"8px");
}

- (void)testRejectedMarkupNeverReachesWebKit
{
    AffirmPromotionalButton *button = [self promoButton];
    NSString *html = @"<span class=\"keep\">keep</span>"
        @"<iframe src=\"https://frame.test\"></iframe><frameset><frame src=\"https://frame.test\"></frameset>"
        @"<form action=\"https://evil.test\"><input name=\"x\"></form>"
        @"<style>body{display:none}</style>"
        @"<span style=\"color:red\" aria-label=\"a\" data-x=\"d\" onclick=\"window.pwned=1\">s</span>"
        @"<a id=\"clobber\" name=\"cookie\" href=\"http://evil.test\">h</a>"
        @"<a href=\"javascript:window.pwned=2\">j</a><a href=\"data:text/html,x\">d</a>"
        @"<img src=\"data:image/png;base64,AA\"><img src=\"http://evil.test/x.png\">"
        @"<svg onload=\"window.pwned=3\"></svg>";
    [self showHTML:html in:button remoteCssURL:nil];
    NSDictionary *result = [self evaluate:
        @"(function () {"
        @"  var root = document.getElementById('affirm-promo-root');"
        @"  var all = Array.prototype.slice.call(root.querySelectorAll('*'));"
        @"  return {"
        @"    blocked: root.querySelectorAll('iframe, frame, frameset, form, input, style, script').length,"
        @"    attrs: all.filter(function (el) {"
        @"      return Array.prototype.some.call(el.attributes, function (a) {"
        @"        return /^(style|id|name|on|aria-|data-)/.test(a.name);"
        @"      });"
        @"    }).length,"
        @"    urls: all.filter(function (el) { return el.hasAttribute('href') || el.hasAttribute('src'); }).length,"
        @"    clobbered: typeof window.clobber !== 'undefined' || typeof document.cookie !== 'string',"
        @"    pwned: typeof window.pwned !== 'undefined',"
        @"    visible: getComputedStyle(document.body).display !== 'none',"
        @"    keep: !!root.querySelector('span.keep')"
        @"  };"
        @"})()" in:button];
    XCTAssertEqualObjects(result[@"blocked"], @0);
    XCTAssertEqualObjects(result[@"attrs"], @0);
    XCTAssertEqualObjects(result[@"urls"], @0);
    XCTAssertEqualObjects(result[@"clobbered"], @NO);
    XCTAssertEqualObjects(result[@"pwned"], @NO);
    XCTAssertEqualObjects(result[@"visible"], @YES);
    XCTAssertEqualObjects(result[@"keep"], @YES);
}

- (void)testMerchantStylesheetLoadsAfterTheBundledCSS
{
    AffirmPromotionalButton *button = [self promoButton];
    NSURL *css = [[NSBundle resourceBundle] URLForResource:@"badge_styles" withExtension:@"css"];
    XCTAssertNotNil(css);
    [self showHTML:@"<span>ok</span>" in:button remoteCssURL:css];
    // affirm.js may append its own <style> later, so compare only the first style with the link.
    NSArray *order = [self evaluate:
        @"Array.prototype.map.call(document.head.querySelectorAll('style, link'), function (el) {"
        @"  return el.tagName === 'STYLE' ? 'bundled' : 'merchant';"
        @"}).slice(0, 2)" in:button];
    XCTAssertEqualObjects(order, (@[@"bundled", @"merchant"]));
}

- (void)testHeightFollowsContentChanges
{
    AffirmPromotionalButton *button = [self promoButton];
    [self showHTML:@"<span>ok</span>" in:button remoteCssURL:nil];
    NSLayoutConstraint *height = [button valueForKey:@"webViewHeightConstraint"];
    CGFloat before = height.constant;
    [self evaluate:@"document.getElementById('affirm-promo-root').style.paddingBottom = '120px'" in:button];
    NSPredicate *grew = [NSPredicate predicateWithBlock:^BOOL(NSLayoutConstraint *constraint, NSDictionary *bindings) {
        return constraint.constant >= before + 100;
    }];
    [self waitForExpectations:@[[self expectationForPredicate:grew evaluatedWithObject:height handler:nil]] timeout:5];
}

- (void)testMigratedImageFailureFallsBackToNativeText
{
    AffirmPromotionalButton *button = [self promoButton];
    XCTestExpectation *finished = [self expectRenderOf:button finishingIn:@"T3"
                                        decisionReason:AffirmPromoDecisionReasonFlagTrue
                                        fallbackReason:AffirmPromoRenderReasonImageFailed];
    [self configureNative:button];
    [self completePromoRequestAtIndex:0 json:[self promoJSONWithAla:@"Native"
                                                               html:@"<span>ok</span><img src='https://127.0.0.1:1/x.png'>"
                                                               flag:@"true"]];
    [self waitForExpectations:@[finished] timeout:10];
    XCTAssertEqualObjects([self nativeTitleOf:button], @"Native");
    XCTAssertTrue([[button valueForKey:@"webView"] isHidden]);
}

- (void)testMigratedProcessLossBeforeReadyFallsBackToNativeText
{
    AffirmPromotionalButton *button = [self promoButton];
    XCTestExpectation *finished = [self expectRenderOf:button finishingIn:@"T3"
                                        decisionReason:AffirmPromoDecisionReasonFlagTrue
                                        fallbackReason:AffirmPromoRenderReasonRenderProcessGone];
    [self configureNative:button];
    [self completePromoRequestAtIndex:0 json:[self promoJSONWithAla:@"Native" html:@"<span>HTML</span>" flag:@"true"]];
    WKWebView *webView = [button valueForKey:@"webView"];
    [(id<WKNavigationDelegate>)button webViewWebContentProcessDidTerminate:webView];
    [self waitForExpectations:@[finished] timeout:1];
    XCTAssertEqualObjects([self nativeTitleOf:button], @"Native");
}

- (void)configureNativeWithoutTextColor:(AffirmPromotionalButton *)button
{
    UIColor *missingColor = nil;
    [button configureWithAmount:[self amount]
                 affirmLogoType:AffirmLogoTypeText
                    affirmColor:AffirmColorTypeBlue
                           font:[UIFont systemFontOfSize:15]
                      textColor:missingColor];
}

- (void)testNativeTextErrorFinishesAsT8
{
    AffirmPromotionalButton *button = [self promoButton];
    XCTestExpectation *finished = [self expectRenderOf:button finishingIn:@"T8"
                                        decisionReason:AffirmPromoDecisionReasonFlagMissing fallbackReason:nil];
    [self configureNativeWithoutTextColor:button];
    [self completePromoRequestAtIndex:0 json:[self promoJSONWithAla:@"Native" html:nil flag:nil]];
    [self waitForExpectations:@[finished] timeout:1];
    XCTAssertTrue(button.hidden);
}

- (void)testMigratedFallbackErrorFinishesAsT8
{
    AffirmPromotionalButton *button = [self promoButton];
    XCTestExpectation *finished = [self expectRenderOf:button finishingIn:@"T8"
                                        decisionReason:AffirmPromoDecisionReasonFlagTrue
                                        fallbackReason:AffirmPromoRenderReasonHTMLEmpty];
    [self configureNativeWithoutTextColor:button];
    [self completePromoRequestAtIndex:0 json:[self promoJSONWithAla:@"Native" html:@"<script>x()</script>" flag:@"true"]];
    [self waitForExpectations:@[finished] timeout:10];
    XCTAssertTrue(button.hidden);
    XCTAssertTrue([[button valueForKey:@"webView"] isHidden]);
}

#pragma mark - Native style and accessibility

- (void)configureNative:(AffirmPromotionalButton *)button font:(UIFont *)font textColor:(UIColor *)textColor
{
    [button configureWithAmount:[self amount]
                 affirmLogoType:AffirmLogoTypeText
                    affirmColor:AffirmColorTypeBlue
                           font:font
                      textColor:textColor];
}

- (void)showMigratedHTML:(NSString *)html
                     ala:(NSString *)ala
                      in:(AffirmPromotionalButton *)button
                    font:(UIFont *)font
               textColor:(UIColor *)textColor
{
    XCTestExpectation *finished = [self expectRenderOf:button finishingIn:@"T2"
                                        decisionReason:AffirmPromoDecisionReasonFlagTrue fallbackReason:nil];
    [self configureNative:button font:font textColor:textColor];
    NSDictionary *json = @{@"promo": @{@"ala": ala, @"html_ala": html,
                                       @"config": @{@"ios_sdk_migrate_native_to_html_render": @YES}}};
    NSData *data = [NSJSONSerialization dataWithJSONObject:json options:0 error:nil];
    [self completePromoRequestAtIndex:self.promoHandlers.count - 1
                                 json:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
    [self waitForExpectations:@[finished] timeout:10];
}

- (NSDictionary *)rootStyleOf:(AffirmPromotionalButton *)button
{
    return [self evaluate:
        @"(function () {"
        @"  var root = document.getElementById('affirm-promo-root');"
        @"  var style = getComputedStyle(root);"
        @"  var rect = root.getBoundingClientRect();"
        @"  return {"
        @"    family: style.fontFamily, size: style.fontSize, weight: style.fontWeight,"
        @"    fontStyle: style.fontStyle, color: style.color, align: style.textAlign,"
        @"    margin: style.marginTop, bodyMargin: getComputedStyle(document.body).marginTop,"
        @"    left: rect.left, right: document.documentElement.clientWidth - rect.right,"
        @"    top: rect.top, bottom: document.documentElement.clientHeight - rect.bottom,"
        @"    overflow: document.documentElement.scrollWidth - document.documentElement.clientWidth"
        @"  };"
        @"})()" in:button];
}

- (void)testNativeStyleCSSCarriesFontSizeAndColor
{
    UIFont *serif = [UIFont fontWithDescriptor:[[UIFont systemFontOfSize:17].fontDescriptor
                                                   fontDescriptorWithDesign:UIFontDescriptorSystemDesignSerif]
                                          size:17];
    UIFont *boldItalicSerif = [self font:serif withTraits:UIFontDescriptorTraitBold | UIFontDescriptorTraitItalic];
    NSString *css = AffirmPromoNativeStyleCSS(AffirmPromoFontStyleForFont(boldItalicSerif), [UIColor redColor], nil);
    XCTAssertTrue([css containsString:@"font-family: ui-serif, serif"], @"%@", css);
    XCTAssertTrue([css containsString:@"font-size: 17px"], @"%@", css);
    XCTAssertTrue([css containsString:@"font-weight: 700"], @"%@", css);
    XCTAssertTrue([css containsString:@"font-style: italic"], @"%@", css);
    XCTAssertTrue([css containsString:@"color: rgba(255, 0, 0, 1)"], @"%@", css);

    NSString *regular = AffirmPromoNativeStyleCSS(AffirmPromoFontStyleForFont([UIFont monospacedSystemFontOfSize:12 weight:UIFontWeightRegular]), nil, nil);
    XCTAssertTrue([regular containsString:@"font-family: ui-monospace, monospace"], @"%@", regular);
    XCTAssertTrue([regular containsString:@"font-weight: 400"], @"%@", regular);
    XCTAssertTrue([regular containsString:@"font-style: normal"], @"%@", regular);
    XCTAssertFalse([regular containsString:@"color:"], @"%@", regular);
}

- (void)testZeroFontSizeFallsBackTo15
{
    NSString *css = AffirmPromoNativeStyleCSS(AffirmPromoFontStyleForFont([UIFont systemFontOfSize:0]), nil, nil);
    XCTAssertTrue([css containsString:@"font-size: 15px"], @"%@", css);
}

- (void)testTextColorIsResolvedAgainstTheGivenTraits
{
    UIColor *dynamic = [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *traits) {
        return traits.userInterfaceStyle == UIUserInterfaceStyleDark ? [UIColor whiteColor] : [UIColor blackColor];
    }];
    UITraitCollection *dark = [UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleDark];
    UITraitCollection *light = [UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleLight];
    XCTAssertEqualObjects(AffirmPromoCSSColor(dynamic, dark), @"rgba(255, 255, 255, 1)");
    XCTAssertEqualObjects(AffirmPromoCSSColor(dynamic, light), @"rgba(0, 0, 0, 1)");
    XCTAssertEqualObjects(AffirmPromoCSSColor([[UIColor blueColor] colorWithAlphaComponent:0.5], nil), @"rgba(0, 0, 255, 0.5)");
    XCTAssertEqualObjects(AffirmPromoCSSColor([UIColor colorWithWhite:0.2 alpha:1], nil), @"rgba(51, 51, 51, 1)");
    UIImage *pattern = [[[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(1, 1)] imageWithActions:^(UIGraphicsImageRendererContext *context) {}];
    XCTAssertNil(AffirmPromoCSSColor([UIColor colorWithPatternImage:pattern], nil));
}

- (void)testMigratedPageUsesTheNativeFontSizeColorAndLayout
{
    AffirmPromotionalButton *button = [self promoButton];
    UIFont *boldSerif = [self font:[UIFont fontWithDescriptor:[[UIFont systemFontOfSize:17].fontDescriptor
                                                                  fontDescriptorWithDesign:UIFontDescriptorSystemDesignSerif]
                                                         size:17]
                        withTraits:UIFontDescriptorTraitBold];
    [self showMigratedHTML:@"<span>HTML</span>" ala:@"Native" in:button font:boldSerif textColor:[UIColor redColor]];
    NSDictionary *style = [self rootStyleOf:button];
    XCTAssertTrue([style[@"family"] containsString:@"ui-serif"], @"%@", style);
    XCTAssertEqualObjects(style[@"size"], @"17px");
    XCTAssertEqualObjects(style[@"weight"], @"700");
    XCTAssertEqualObjects(style[@"fontStyle"], @"normal");
    XCTAssertEqualObjects(style[@"color"], @"rgb(255, 0, 0)");
    XCTAssertEqualObjects(style[@"align"], @"left");
    XCTAssertEqualObjects(style[@"margin"], @"0px");
    XCTAssertEqualObjects(style[@"bodyMargin"], @"0px");
    // Centered as a block, both ways, like the native button title.
    XCTAssertGreaterThan([style[@"left"] doubleValue], 50);
    XCTAssertEqualWithAccuracy([style[@"left"] doubleValue], [style[@"right"] doubleValue], 1);
    XCTAssertEqualWithAccuracy([style[@"top"] doubleValue], [style[@"bottom"] doubleValue], 1);
}

- (void)testMigratedLongTextWrapsInsideTheView
{
    AffirmPromotionalButton *button = [self promoButton];
    NSString *longText = [[@"" stringByPaddingToLength:400 withString:@"Paga en cuotas con Affirm " startingAtIndex:0]
                          stringByAppendingString:@"Supercalifragilisticexpialidocious"];
    [self showMigratedHTML:[NSString stringWithFormat:@"<span>%@</span>", longText]
                       ala:@"Native" in:button font:[UIFont systemFontOfSize:15] textColor:[UIColor blackColor]];
    NSDictionary *style = [self rootStyleOf:button];
    XCTAssertLessThanOrEqual([style[@"overflow"] doubleValue], 0, @"%@", style);
    XCTAssertEqualObjects(style[@"align"], @"left");
    XCTAssertGreaterThan([[button valueForKey:@"webViewHeightConstraint"] constant], 44);
}

- (void)testMigratedHeightFollowsContentChanges
{
    AffirmPromotionalButton *button = [self promoButton];
    [self showMigratedHTML:@"<span>HTML</span>" ala:@"Native" in:button
                      font:[UIFont systemFontOfSize:15] textColor:[UIColor blackColor]];
    NSLayoutConstraint *height = [button valueForKey:@"webViewHeightConstraint"];
    CGFloat before = height.constant;
    [self evaluate:@"document.getElementById('affirm-promo-root').style.paddingBottom = '120px'" in:button];
    NSPredicate *grew = [NSPredicate predicateWithBlock:^BOOL(NSLayoutConstraint *constraint, NSDictionary *bindings) {
        return constraint.constant >= before + 100;
    }];
    [self waitForExpectations:@[[self expectationForPredicate:grew evaluatedWithObject:height handler:nil]] timeout:5];
}

- (void)testExplicitHTMLKeepsTheBrowserTextDefaults
{
    AffirmPromotionalButton *button = [self promoButton];
    [self showHTML:@"<span>ok</span>" in:button remoteCssURL:nil];
    NSDictionary *style = [self rootStyleOf:button];
    XCTAssertEqualObjects(style[@"size"], @"16px");
    XCTAssertEqualObjects(style[@"margin"], @"16px");
    XCTAssertEqualObjects(style[@"color"], @"rgb(0, 0, 0)");
    XCTAssertEqualWithAccuracy([style[@"left"] doubleValue], 8, 0.5);
}

- (void)testNativeStyleChangeReloadsTheSameHTML
{
    AffirmPromotionalButton *button = [self promoButton];
    [self showMigratedHTML:@"<span>HTML</span>" ala:@"Native" in:button
                      font:[UIFont systemFontOfSize:15] textColor:[UIColor blackColor]];
    [self showMigratedHTML:@"<span>HTML</span>" ala:@"Native" in:button
                      font:[UIFont systemFontOfSize:15] textColor:[UIColor redColor]];
    XCTAssertEqualObjects([self rootStyleOf:button][@"color"], @"rgb(255, 0, 0)");
}

- (void)testMigratedViewIsOneButtonLabelledWithAla
{
    AffirmPromotionalButton *button = [self promoButton];
    [self showMigratedHTML:@"<span>HTML</span><a class='affirm-modal-trigger'>See if you qualify</a>"
                       ala:@"From $50/mo with {Affirm}" in:button
                      font:[UIFont systemFontOfSize:15] textColor:[UIColor blackColor]];
    XCTAssertTrue(button.isAccessibilityElement);
    XCTAssertTrue(button.accessibilityTraits & UIAccessibilityTraitButton);
    XCTAssertEqualObjects(button.accessibilityLabel, @"From $50/mo with Affirm");
}

- (void)testLabelFallsBackToPageTextWithoutAla
{
    AffirmPromotionalButton *button = [self promoButton];
    [self showMigratedHTML:@"<span>From  $50</span>/mo with <b>Affirm</b>" ala:@"" in:button
                      font:[UIFont systemFontOfSize:15] textColor:[UIColor blackColor]];
    XCTAssertEqualObjects(button.accessibilityLabel, @"From $50/mo with Affirm");
}

- (void)testNewRenderDoesNotKeepTheOldLabel
{
    AffirmPromotionalButton *button = [self promoButton];
    [self showMigratedHTML:@"<span>Old HTML</span>" ala:@"Old ala" in:button
                      font:[UIFont systemFontOfSize:15] textColor:[UIColor blackColor]];
    XCTAssertEqualObjects(button.accessibilityLabel, @"Old ala");

    [self showMigratedHTML:@"<span>New HTML</span>" ala:@"" in:button
                      font:[UIFont systemFontOfSize:15] textColor:[UIColor blackColor]];
    XCTAssertEqualObjects(button.accessibilityLabel, @"New HTML");

    [self showHTML:@"<span>Unmanaged</span>" in:button remoteCssURL:nil];
    XCTAssertEqualObjects(button.accessibilityLabel, @"Unmanaged");
}

- (void)testReusedPageStillGetsTheLabel
{
    AffirmPromotionalButton *button = [self promoButton];
    [self showMigratedHTML:@"<span>Same</span>" ala:@"" in:button
                      font:[UIFont systemFontOfSize:15] textColor:[UIColor blackColor]];
    [self showMigratedHTML:@"<span>Same</span>" ala:@"" in:button
                      font:[UIFont systemFontOfSize:15] textColor:[UIColor blackColor]];
    XCTAssertEqualObjects(button.accessibilityLabel, @"Same");
}

- (void)testNativeLabelUsesTheDefaultMessageWithoutAla
{
    AffirmPromotionalButton *button = [self promoButton];
    XCTestExpectation *finished = [self expectRenderOf:button finishingIn:@"T1"
                                        decisionReason:AffirmPromoDecisionReasonFlagFalse fallbackReason:nil];
    [self configureNative:button];
    [self completePromoRequestAtIndex:0 json:[self promoJSONWithAla:@"" html:nil flag:@"false"]];
    [self waitForExpectations:@[finished] timeout:1];
    XCTAssertEqualObjects(button.accessibilityLabel, @"Pay over time with Affirm");
}

- (void)testActivationOpensTheModalOnlyOnceReady
{
    AffirmPromotionalButton *button = [self promoButton];
    UIViewController *host = self.window.rootViewController;
    UIButton *overlay = [button valueForKey:@"button"];

    [self configureNative:button];
    XCTAssertFalse([button accessibilityActivate]);
    [overlay sendActionsForControlEvents:UIControlEventTouchUpInside];
    XCTAssertNil(host.presentedViewController);

    XCTestExpectation *finished = [self expectRenderOf:button finishingIn:@"T2"
                                        decisionReason:AffirmPromoDecisionReasonFlagTrue fallbackReason:nil];
    [self completePromoRequestAtIndex:0 json:[self promoJSONWithAla:@"Native" html:@"<span>HTML</span>" flag:@"true"]];
    [self waitForExpectations:@[finished] timeout:10];

    XCTAssertTrue([button accessibilityActivate]);
    UINavigationController *modal = (UINavigationController *)host.presentedViewController;
    XCTAssertTrue([modal.topViewController isKindOfClass:NSClassFromString(@"AffirmPromoModalViewController")], @"%@", modal);
    [overlay sendActionsForControlEvents:UIControlEventTouchUpInside];
    XCTAssertEqual(host.presentedViewController, modal, @"a second activation must not replace the modal");
    [host dismissViewControllerAnimated:NO completion:nil];
}

@end
