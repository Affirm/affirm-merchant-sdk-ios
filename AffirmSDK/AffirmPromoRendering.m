//
//  AffirmPromoRendering.m
//  AffirmSDK
//

#import "AffirmPromoRendering.h"
#import "AffirmUtils.h"

NSNotificationName const AffirmPromoHTMLRenderDidFinishNotification = @"AffirmPromoHTMLRenderDidFinish";
NSString *const AffirmPromoScriptMessageName = @"affirmPromo";
const NSTimeInterval AffirmPromoHTMLTimeoutSeconds = 5;

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

@implementation AffirmPromoRenderOperation

- (instancetype)initWithRequestedMode:(AffirmPromoRenderMode)requestedMode
{
    if (self = [super init]) {
        _renderID = [NSUUID UUID].UUIDString;
        _requestedMode = requestedMode;
        _selectedMode = AffirmPromoRenderModeNone;
        _actualRenderer = AffirmPromoRenderModeNone;
    }
    return self;
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
