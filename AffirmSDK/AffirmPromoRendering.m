//
//  AffirmPromoRendering.m
//  AffirmSDK
//

#import <mach/mach_time.h>
#import "AffirmPromoRendering.h"
#import "AffirmConfiguration.h"
#import "AffirmLogger.h"
#import "AffirmUtils.h"

NSNotificationName const AffirmPromoHTMLRenderDidFinishNotification = @"AffirmPromoHTMLRenderDidFinish";
NSString *const AffirmPromoScriptMessageName = @"affirmPromo";
NSTimeInterval AffirmPromoHTMLTimeoutSeconds = 5;

NSString *const AffirmPromoRenderReasonLoadError = @"load_error";
NSString *const AffirmPromoRenderReasonRenderProcessGone = @"render_process_gone";
NSString *const AffirmPromoRenderReasonScriptError = @"script_error";
NSString *const AffirmPromoRenderReasonSanitizerUnavailable = @"sanitizer_unavailable";
NSString *const AffirmPromoRenderReasonHTMLEmpty = @"html_empty";
NSString *const AffirmPromoRenderReasonResourceFailed = @"resource_failed";
NSString *const AffirmPromoRenderReasonImageFailed = @"image_failed";
NSString *const AffirmPromoRenderReasonHTMLTimeout = @"html_timeout";
NSString *const AffirmPromoRenderReasonTemplateError = @"template_error";

static NSString * AffirmPromoResource(NSString *name, NSString *type) {
    NSString *path = [[NSBundle resourceBundle] pathForResource:name ofType:type];
    if (path.length == 0) {
        return @"";
    }
    return [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil] ?: @"";
}

static BOOL AffirmPromoPathIsInsideDirectory(NSString *path, NSString *directory) {
    if (path.length == 0 || directory.length == 0) {
        return NO;
    }
    NSString *standardizedPath = path.stringByStandardizingPath;
    NSString *standardizedDirectory = directory.stringByStandardizingPath;
    if ([standardizedPath isEqualToString:standardizedDirectory]) {
        return YES;
    }
    NSString *prefix = [standardizedDirectory hasSuffix:@"/"]
        ? standardizedDirectory
        : [standardizedDirectory stringByAppendingString:@"/"];
    return [standardizedPath hasPrefix:prefix];
}

NSString *AffirmPromoRenderReasonFromPage(NSString *reason) {
    static NSSet<NSString *> *pageReasons;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        pageReasons = [NSSet setWithObjects:
                       AffirmPromoRenderReasonSanitizerUnavailable,
                       AffirmPromoRenderReasonHTMLEmpty,
                       AffirmPromoRenderReasonResourceFailed,
                       AffirmPromoRenderReasonImageFailed,
                       AffirmPromoRenderReasonHTMLTimeout,
                       AffirmPromoRenderReasonTemplateError,
                       nil];
    });
    if (reason.length > 0 && [pageReasons containsObject:reason]) {
        return reason;
    }
    return AffirmPromoRenderReasonScriptError;
}

BOOL AffirmPromoPermittedStylesheetURL(NSURL *url) {
    if (url == nil || url.absoluteString.length == 0) {
        return YES;
    }
    NSString *scheme = url.scheme.lowercaseString;
    if ([scheme isEqualToString:@"https"]) {
        return YES;
    }
    if (![scheme isEqualToString:@"file"] || url.path.length == 0) {
        return NO;
    }
    NSString *resourcePath = [NSBundle resourceBundle].bundlePath;
    return AffirmPromoPathIsInsideDirectory(url.path, [NSBundle mainBundle].bundlePath)
        || AffirmPromoPathIsInsideDirectory(url.path, [NSBundle sdkBundle].bundlePath)
        || AffirmPromoPathIsInsideDirectory(url.path, resourcePath);
}

CGFloat AffirmPromoHeightForCSSPixels(double cssPixels) {
    if (cssPixels <= 0) {
        return 0;
    }
    return (CGFloat)ceil(cssPixels);
}

NSString *AffirmPromoEscapedJSONObject(id object) {
    if (object == nil || ![NSJSONSerialization isValidJSONObject:object]) {
        return nil;
    }
    NSData *data = [NSJSONSerialization dataWithJSONObject:object options:0 error:nil];
    if (data.length == 0) {
        return nil;
    }
    NSString *json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    // Keep "</script>" from closing the surrounding HTML script element.
    json = [json stringByReplacingOccurrencesOfString:@"<" withString:@"\\u003c"];
    json = [json stringByReplacingOccurrencesOfString:@">" withString:@"\\u003e"];
    return json;
}

NSString *AffirmPromoBundledCSS(void) {
    return AffirmPromoResource(@"badge_styles", @"css");
}

NSString *AffirmPromoSanitizerSource(void) {
    return AffirmPromoResource(@"purify.min", @"js");
}

NSString *AffirmPromoHTMLDocumentWithPayload(NSDictionary *payload) {
    NSString *json = AffirmPromoEscapedJSONObject(payload);
    NSString *template = AffirmPromoResource(@"affirm_promo", @"html");
    NSString *token = @"{{AFFIRM_PROMO_PAYLOAD}}";
    NSRange range = [template rangeOfString:token];
    if (json.length == 0 || range.location == NSNotFound) {
        return nil;
    }
    NSRange rest = NSMakeRange(NSMaxRange(range), template.length - NSMaxRange(range));
    if ([template rangeOfString:token options:0 range:rest].location != NSNotFound) {
        return nil;
    }
    return [template stringByReplacingCharactersInRange:range withString:json];
}

@implementation AffirmPromoScriptMessageProxy

- (void)userContentController:(WKUserContentController *)userContentController
      didReceiveScriptMessage:(WKScriptMessage *)message
{
    id<WKScriptMessageHandler> target = self.target;
    if (target) {
        [target userContentController:userContentController didReceiveScriptMessage:message];
    }
}

@end

NSNotificationName const AffirmPromoRenderDidFinishNotification = @"AffirmPromoRenderDidFinish";
NSString *const AffirmPromoRenderOperationKey = @"operation";

NSString *const AffirmPromoRenderReasonFetchError = @"fetch_error";
NSString *const AffirmPromoRenderReasonMissingHTML = @"missing_html";
NSString *const AffirmPromoRenderReasonNativeError = @"native_error";
NSString *const AffirmPromoRenderReasonSuperseded = @"superseded";
NSString *const AffirmPromoRenderReasonHostDestroyed = @"host_destroyed";

NSString *const AffirmPromoDecisionReasonExplicitHTML = @"explicit_html";
NSString *const AffirmPromoDecisionReasonOptOut = @"opt_out";
NSString *const AffirmPromoDecisionReasonUnsupportedFont = @"unsupported_font";
NSString *const AffirmPromoDecisionReasonFlagTrue = @"flag_true";
NSString *const AffirmPromoDecisionReasonFlagFalse = @"flag_false";
NSString *const AffirmPromoDecisionReasonFlagMissing = @"flag_missing";
NSString *const AffirmPromoDecisionReasonFlagNull = @"flag_null";
NSString *const AffirmPromoDecisionReasonFlagMalformed = @"flag_malformed";

NSString *const AffirmPromoRenderModeEventName = @"Promo_render_mode";
NSString *const AffirmPromoRenderResultEventName = @"Promo_render_result";

@implementation AffirmPromoFontStyle

- (instancetype)initWithCSSFamily:(NSString *)cssFamily bold:(BOOL)bold italic:(BOOL)italic pointSize:(CGFloat)pointSize
{
    if (self = [super init]) {
        _cssFamily = [cssFamily copy];
        _bold = bold;
        _italic = italic;
        _pointSize = pointSize;
    }
    return self;
}

@end

AffirmPromoFontStyle *AffirmPromoFontStyleForFont(UIFont *font)
{
    if (font == nil || font.fontName.length == 0) {
        return nil;
    }
    CGFloat size = font.pointSize;
    UIFontDescriptor *system = [UIFont systemFontOfSize:size].fontDescriptor;
    NSArray *designs = @[
        @[@"system-ui", system],
        @[@"ui-serif", [system fontDescriptorWithDesign:UIFontDescriptorSystemDesignSerif] ?: [NSNull null]],
        @[@"ui-monospace", [UIFont monospacedSystemFontOfSize:size weight:UIFontWeightRegular].fontDescriptor],
    ];
    // Regular first, so a design that cannot produce a variant keeps the regular mapping for that name.
    UIFontDescriptorSymbolicTraits variants[] = {
        0,
        UIFontDescriptorTraitBold,
        UIFontDescriptorTraitItalic,
        UIFontDescriptorTraitBold | UIFontDescriptorTraitItalic,
    };
    for (NSArray *design in designs) {
        if (design[1] == [NSNull null]) {
            continue;
        }
        UIFontDescriptor *base = design[1];
        for (size_t i = 0; i < sizeof(variants) / sizeof(variants[0]); i++) {
            UIFontDescriptor *descriptor = variants[i] == 0 ? base : [base fontDescriptorWithSymbolicTraits:variants[i]];
            if (descriptor == nil) {
                continue;
            }
            NSString *name = [UIFont fontWithDescriptor:descriptor size:size].fontName;
            if ([name isEqualToString:font.fontName]) {
                return [[AffirmPromoFontStyle alloc] initWithCSSFamily:design[0]
                                                                  bold:(variants[i] & UIFontDescriptorTraitBold) != 0
                                                                italic:(variants[i] & UIFontDescriptorTraitItalic) != 0
                                                             pointSize:size];
            }
        }
    }
    return nil;
}

static CGFloat AffirmPromoClamp(CGFloat value) {
    return MIN(MAX(value, 0), 1);
}

NSString *AffirmPromoCSSColor(UIColor *color, UITraitCollection *traits)
{
    UIColor *resolved = traits ? [color resolvedColorWithTraitCollection:traits] : color;
    CGFloat red, green, blue, alpha;
    if (resolved == nil || ![resolved getRed:&red green:&green blue:&blue alpha:&alpha]) {
        return nil;
    }
    return [NSString stringWithFormat:@"rgba(%d, %d, %d, %g)",
            (int)lround(AffirmPromoClamp(red) * 255),
            (int)lround(AffirmPromoClamp(green) * 255),
            (int)lround(AffirmPromoClamp(blue) * 255),
            round(AffirmPromoClamp(alpha) * 1000) / 1000];
}

NSString *AffirmPromoNativeStyleCSS(AffirmPromoFontStyle *fontStyle, UIColor *textColor, UITraitCollection *traits)
{
    NSDictionary<NSString *, NSString *> *fallbacks = @{
        @"system-ui": @"system-ui, -apple-system, sans-serif",
        @"ui-serif": @"ui-serif, serif",
        @"ui-monospace": @"ui-monospace, monospace",
    };
    NSMutableArray<NSString *> *root = [NSMutableArray arrayWithObjects:
                                        @"margin: 0",
                                        @"max-width: 100%",
                                        @"text-align: left",
                                        @"overflow-wrap: break-word",
                                        nil];
    if (fontStyle) {
        CGFloat size = fontStyle.pointSize > 0 ? fontStyle.pointSize : 15;
        [root addObject:[NSString stringWithFormat:@"font-family: %@", fallbacks[fontStyle.cssFamily] ?: fontStyle.cssFamily]];
        [root addObject:[NSString stringWithFormat:@"font-size: %gpx", size]];
        [root addObject:[NSString stringWithFormat:@"font-weight: %@", fontStyle.bold ? @"700" : @"400"]];
        [root addObject:[NSString stringWithFormat:@"font-style: %@", fontStyle.italic ? @"italic" : @"normal"]];
    }
    NSString *color = AffirmPromoCSSColor(textColor, traits);
    if (color) {
        [root addObject:[NSString stringWithFormat:@"color: %@", color]];
    }
    // The body fills the view, so the flex column centers the promo the way UIButton centers its title.
    return [NSString stringWithFormat:
            @"html, body { height: 100%%; }\n"
            @"body { margin: 0; display: flex; flex-direction: column; justify-content: center; align-items: center; }\n"
            @"#affirm-promo-root { %@; }\n",
            [root componentsJoinedByString:@"; "]];
}

@implementation AffirmPromoRenderPolicy

- (instancetype)initWithRequestedMode:(AffirmPromoRenderMode)requestedMode
                               optOut:(BOOL)optOut
                                 font:(nullable UIFont *)font
                            textColor:(nullable UIColor *)textColor
{
    if (self = [super init]) {
        _requestedMode = requestedMode;
        _optOut = optOut;
        BOOL native = requestedMode == AffirmPromoRenderModeNative;
        _fontStyle = native ? AffirmPromoFontStyleForFont(font) : nil;
        _textColor = native ? textColor : nil;
    }
    return self;
}

- (instancetype)initWithRequestedMode:(AffirmPromoRenderMode)requestedMode
                               optOut:(BOOL)optOut
                                 font:(nullable UIFont *)font
{
    return [self initWithRequestedMode:requestedMode optOut:optOut font:font textColor:nil];
}

- (AffirmPromoRenderMode)modeForFlagStatus:(AffirmPromoRenderFlagStatus)flagStatus
                                    reason:(NSString *_Nullable *_Nullable)reason
{
    NSString *decisionReason = nil;
    AffirmPromoRenderMode mode = AffirmPromoRenderModeNative;
    if (self.requestedMode == AffirmPromoRenderModeHTML) {
        mode = AffirmPromoRenderModeHTML;
        decisionReason = AffirmPromoDecisionReasonExplicitHTML;
    } else if (self.optOut) {
        decisionReason = AffirmPromoDecisionReasonOptOut;
    } else if (self.fontStyle == nil) {
        decisionReason = AffirmPromoDecisionReasonUnsupportedFont;
    } else {
        switch (flagStatus) {
            case AffirmPromoRenderFlagStatusTrue:
                mode = AffirmPromoRenderModeHTML;
                decisionReason = AffirmPromoDecisionReasonFlagTrue;
                break;
            case AffirmPromoRenderFlagStatusFalse:
                decisionReason = AffirmPromoDecisionReasonFlagFalse;
                break;
            case AffirmPromoRenderFlagStatusMissing:
                decisionReason = AffirmPromoDecisionReasonFlagMissing;
                break;
            case AffirmPromoRenderFlagStatusNull:
                decisionReason = AffirmPromoDecisionReasonFlagNull;
                break;
            case AffirmPromoRenderFlagStatusMalformed:
                decisionReason = AffirmPromoDecisionReasonFlagMalformed;
                break;
        }
    }
    if (reason) {
        *reason = decisionReason;
    }
    return mode;
}

@end

static NSString *AffirmPromoRenderModeName(AffirmPromoRenderMode mode)
{
    switch (mode) {
        case AffirmPromoRenderModeNative:
            return @"native";
        case AffirmPromoRenderModeHTML:
            return @"html";
        case AffirmPromoRenderModeNone:
            return @"none";
    }
}

static NSString *AffirmPromoRenderOutcomeName(AffirmPromoRenderOutcome outcome)
{
    switch (outcome) {
        case AffirmPromoRenderOutcomeSuccess:
            return @"success";
        case AffirmPromoRenderOutcomeFailure:
            return @"failure";
        case AffirmPromoRenderOutcomeEmptyContent:
            return @"empty_content";
        case AffirmPromoRenderOutcomeCancelled:
            return @"cancelled";
    }
}

static NSString *AffirmPromoRenderFlagStatusName(AffirmPromoRenderFlagStatus status)
{
    switch (status) {
        case AffirmPromoRenderFlagStatusTrue:
            return @"true";
        case AffirmPromoRenderFlagStatusFalse:
            return @"false";
        case AffirmPromoRenderFlagStatusMissing:
            return @"missing";
        case AffirmPromoRenderFlagStatusNull:
            return @"null";
        case AffirmPromoRenderFlagStatusMalformed:
            return @"malformed";
    }
}

static BOOL AffirmPromoIsBlank(NSString *_Nullable text)
{
    return [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length == 0;
}

static NSInteger AffirmPromoMilliseconds(uint64_t from, uint64_t to)
{
    static mach_timebase_info_data_t timebase;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mach_timebase_info(&timebase);
    });
    if (to <= from || timebase.denom == 0) {
        return 0;
    }
    return (NSInteger)((to - from) * timebase.numer / timebase.denom / NSEC_PER_MSEC);
}

@interface AffirmPromoRenderOperation ()
@property (nonatomic) uint64_t startTime;
@property (nonatomic) uint64_t responseTime;
@property (nonatomic) uint64_t endTime;
@property (nonatomic) BOOL responseRecorded;
@property (nonatomic, strong, nullable) AffirmPromoResponse *response;
@property (nonatomic) BOOL modeEventSent;
@end

@implementation AffirmPromoRenderOperation

- (instancetype)initWithPolicy:(AffirmPromoRenderPolicy *)policy
{
    if (self = [super init]) {
        _renderID = [NSUUID UUID].UUIDString;
        _requestAttemptID = [NSUUID UUID].UUIDString;
        AffirmConfiguration *configuration = [AffirmConfiguration sharedInstance];
        _merchantKey = [configuration.publicKey copy] ?: @"";
        _environment = [configuration.environmentDescription copy] ?: @"";
        _policy = policy;
        _requestedMode = policy.requestedMode;
        _selectedMode = AffirmPromoRenderModeNone;
        _actualRenderer = AffirmPromoRenderModeNone;
        _startTime = mach_absolute_time();
    }
    return self;
}

- (void)recordResponse:(nullable AffirmPromoResponse *)response
{
    if (self.responseRecorded || self.finished) {
        return;
    }
    self.responseRecorded = YES;
    self.responseTime = mach_absolute_time();
    self.response = response;
}

#pragma mark - Telemetry

- (NSMutableDictionary<NSString *, id> *)commonEventParameters
{
    return [@{
        @"render_id": self.renderID,
        @"request_attempt_id": self.requestAttemptID,
        @"merchant_key": self.merchantKey,
        @"environment": self.environment,
        @"platform": @"ios",
        @"release": [AffirmConfiguration affirmSDKVersion] ?: @"",
        @"selected_mode": AffirmPromoRenderModeName(self.selectedMode),
    } mutableCopy];
}

- (void)sendModeEventWithDecisionReason:(nullable NSString *)decisionReason
{
    if (self.modeEventSent) {
        return;
    }
    self.modeEventSent = YES;
    AffirmPromoResponse *response = self.response;
    NSMutableDictionary *parameters = [self commonEventParameters];
    [parameters addEntriesFromDictionary:@{
        @"requested_mode": AffirmPromoRenderModeName(self.requestedMode),
        @"flag_value": @(response.renderFlagEnabled),
        @"flag_status": response ? AffirmPromoRenderFlagStatusName(response.renderFlagStatus) : @"not_received",
        @"opt_out": @(self.policy.optOut),
        @"decision_reason": decisionReason ?: [NSNull null],
    }];
    [self track:AffirmPromoRenderModeEventName parameters:parameters];
}

- (void)sendResultEvent
{
    AffirmPromoResponse *response = self.response;
    NSString *fetchOutcome;
    if (response) {
        fetchOutcome = AffirmPromoIsBlank(response.ala) && AffirmPromoIsBlank(response.htmlAla) ? @"empty" : @"usable";
    } else if (self.responseRecorded) {
        fetchOutcome = @"error";
    } else {
        fetchOutcome = @"cancelled";
    }
    BOOL fallbackSucceeded = self.outcome == AffirmPromoRenderOutcomeSuccess
        && self.selectedMode == AffirmPromoRenderModeHTML
        && self.actualRenderer == AffirmPromoRenderModeNative;
    BOOL nativeContentUsable = response != nil && !AffirmPromoIsBlank(response.ala);
    BOOL htmlContentPresent = response != nil && !AffirmPromoIsBlank(response.htmlAla);
    uint64_t fetchEnd = self.responseRecorded ? self.responseTime : self.endTime;
    NSMutableDictionary *parameters = [self commonEventParameters];
    [parameters addEntriesFromDictionary:@{
        @"actual_renderer": AffirmPromoRenderModeName(self.actualRenderer),
        @"outcome": AffirmPromoRenderOutcomeName(self.outcome),
        @"reason": self.reason ?: [NSNull null],
        @"fallback_reason": self.fallbackReason ?: [NSNull null],
        @"fallback_succeeded": @(fallbackSucceeded),
        @"fetch_outcome": fetchOutcome,
        @"native_content_usable": @(nativeContentUsable),
        @"html_content_present": @(htmlContentPresent),
        @"html_content_usable": self.htmlContentUsable ?: [NSNull null],
        @"fetch_duration_ms": @(AffirmPromoMilliseconds(self.startTime, fetchEnd)),
        @"render_duration_ms": @(response ? AffirmPromoMilliseconds(self.responseTime, self.endTime) : 0),
        @"total_duration_ms": @(AffirmPromoMilliseconds(self.startTime, self.endTime)),
        @"server_request_id_status": @"unverified",
    }];
    [self track:AffirmPromoRenderResultEventName parameters:parameters];
}

- (void)track:(NSString *)name parameters:(NSDictionary *)parameters
{
    // Tracking must never affect rendering.
    @try {
        [[AffirmLogger sharedInstance] trackEvent:name parameters:parameters];
    } @catch (NSException *exception) {
    }
}

- (instancetype)initWithRequestedMode:(AffirmPromoRenderMode)requestedMode
{
    return [self initWithPolicy:[[AffirmPromoRenderPolicy alloc] initWithRequestedMode:requestedMode optOut:NO font:nil]];
}

- (AffirmPromoRenderMode)decideWithFlagStatus:(AffirmPromoRenderFlagStatus)flagStatus
{
    if (self.selectedMode != AffirmPromoRenderModeNone || self.finished) {
        return self.selectedMode;
    }
    NSString *reason = nil;
    AffirmPromoRenderMode mode = [self.policy modeForFlagStatus:flagStatus reason:&reason];
    if ([self selectMode:mode]) {
        _decisionReason = [reason copy];
        [self sendModeEventWithDecisionReason:self.decisionReason];
    }
    return self.selectedMode;
}

- (BOOL)selectMode:(AffirmPromoRenderMode)mode
{
    if (self.finished || self.selectedMode != AffirmPromoRenderModeNone || mode == AffirmPromoRenderModeNone) {
        return NO;
    }
    _selectedMode = mode;
    return YES;
}

- (BOOL)finishWithOutcome:(AffirmPromoRenderOutcome)outcome
           actualRenderer:(AffirmPromoRenderMode)actualRenderer
                   reason:(nullable NSString *)reason
{
    if (self.finished) {
        return NO;
    }
    _finished = YES;
    _outcome = outcome;
    _actualRenderer = actualRenderer;
    _reason = [reason copy];
    self.endTime = mach_absolute_time();
    // Ended before a choice (failed fetch or cancellation): the reason stands in for the rule.
    [self sendModeEventWithDecisionReason:self.decisionReason ?: self.reason];
    [self sendResultEvent];
    return YES;
}

- (nullable NSString *)terminalState
{
    if (!self.finished) {
        return nil;
    }
    switch (self.outcome) {
        case AffirmPromoRenderOutcomeCancelled:
            return @"T9";
        case AffirmPromoRenderOutcomeEmptyContent:
            return @"T7";
        case AffirmPromoRenderOutcomeSuccess:
            if (self.selectedMode == AffirmPromoRenderModeNative && self.actualRenderer == AffirmPromoRenderModeNative) {
                return @"T1";
            }
            if (self.selectedMode == AffirmPromoRenderModeHTML && self.actualRenderer == AffirmPromoRenderModeHTML) {
                return @"T2";
            }
            if (self.selectedMode == AffirmPromoRenderModeHTML && self.actualRenderer == AffirmPromoRenderModeNative) {
                return @"T3";
            }
            return nil;
        case AffirmPromoRenderOutcomeFailure:
            if ([self.reason isEqualToString:AffirmPromoRenderReasonNativeError]) {
                return @"T8";
            }
            if (self.selectedMode == AffirmPromoRenderModeNone) {
                return @"T4";
            }
            if (self.selectedMode == AffirmPromoRenderModeHTML) {
                return self.requestedMode == AffirmPromoRenderModeHTML ? @"T5" : @"T6";
            }
            return nil;
    }
}

@end
