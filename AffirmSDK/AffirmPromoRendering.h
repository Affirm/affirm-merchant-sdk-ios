//
//  AffirmPromoRendering.h
//  AffirmSDK
//
//  HTML promo sandbox: sanitizer, page document, and failure reasons.
//  Internal. Not part of the public merchant API.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSNotificationName const AffirmPromoHTMLRenderDidFinishNotification;
FOUNDATION_EXPORT NSString *const AffirmPromoScriptMessageName;
FOUNDATION_EXPORT const NSTimeInterval AffirmPromoHTMLTimeoutSeconds;

FOUNDATION_EXPORT NSString *const AffirmPromoRenderReasonLoadError;
FOUNDATION_EXPORT NSString *const AffirmPromoRenderReasonRenderProcessGone;
FOUNDATION_EXPORT NSString *const AffirmPromoRenderReasonScriptError;
FOUNDATION_EXPORT NSString *const AffirmPromoRenderReasonSanitizerUnavailable;
FOUNDATION_EXPORT NSString *const AffirmPromoRenderReasonHTMLEmpty;
FOUNDATION_EXPORT NSString *const AffirmPromoRenderReasonResourceFailed;
FOUNDATION_EXPORT NSString *const AffirmPromoRenderReasonImageFailed;
FOUNDATION_EXPORT NSString *const AffirmPromoRenderReasonHTMLTimeout;
FOUNDATION_EXPORT NSString *const AffirmPromoRenderReasonTemplateError;

/// Page-supplied codes stay as-is. Anything else, including native-only codes, becomes script_error.
FOUNDATION_EXPORT NSString *AffirmPromoRenderReasonFromPage(NSString *_Nullable reason);

/// https, or a file URL inside the app bundle or the SDK resource bundle. nil is allowed.
FOUNDATION_EXPORT BOOL AffirmPromoPermittedStylesheetURL(NSURL *_Nullable url);

/// CSS px from the page. WKWebView at initial-scale 1 maps them 1:1 onto points.
FOUNDATION_EXPORT CGFloat AffirmPromoHeightForCSSPixels(double cssPixels);

/// JSON object text safe to place in an HTML script element. nil if it cannot be serialized.
FOUNDATION_EXPORT NSString *_Nullable AffirmPromoEscapedJSONObject(id object);

FOUNDATION_EXPORT NSString *AffirmPromoBundledCSS(void);
FOUNDATION_EXPORT NSString *AffirmPromoSanitizerSource(void);

/// Reads affirm_promo.html and inserts the payload as escaped JSON. nil if the template is missing.
FOUNDATION_EXPORT NSString *_Nullable AffirmPromoHTMLDocumentWithPayload(NSDictionary *payload);

/// Weak script-message handler so the user content controller does not retain the promo view.
@interface AffirmPromoScriptMessageProxy : NSObject <WKScriptMessageHandler>
@property (nonatomic, weak, nullable) id<WKScriptMessageHandler> target;
@end

typedef NS_ENUM(NSInteger, AffirmPromoRenderMode) {
    AffirmPromoRenderModeNone,
    AffirmPromoRenderModeNative,
    AffirmPromoRenderModeHTML
};

typedef NS_ENUM(NSInteger, AffirmPromoRenderOutcome) {
    AffirmPromoRenderOutcomeSuccess,
    AffirmPromoRenderOutcomeFailure,
    AffirmPromoRenderOutcomeEmptyContent,
    AffirmPromoRenderOutcomeCancelled
};

/// Posted once per managed render when it reaches its terminal state. The object is the promo
/// view, or nil when the view was deallocated; `AffirmPromoRenderOperationKey` holds the render.
FOUNDATION_EXPORT NSNotificationName const AffirmPromoRenderDidFinishNotification;
FOUNDATION_EXPORT NSString *const AffirmPromoRenderOperationKey;

FOUNDATION_EXPORT NSString *const AffirmPromoRenderReasonFetchError;
FOUNDATION_EXPORT NSString *const AffirmPromoRenderReasonMissingHTML;
FOUNDATION_EXPORT NSString *const AffirmPromoRenderReasonNativeError;
FOUNDATION_EXPORT NSString *const AffirmPromoRenderReasonSuperseded;
FOUNDATION_EXPORT NSString *const AffirmPromoRenderReasonHostDestroyed;

/// State for one managed render, from a configure… call to exactly one terminal state (T1–T9).
/// Main thread only.
@interface AffirmPromoRenderOperation : NSObject

@property (nonatomic, copy, readonly) NSString *renderID;
@property (nonatomic, readonly) AffirmPromoRenderMode requestedMode;
@property (nonatomic, readonly) AffirmPromoRenderMode selectedMode;
/// The page load this render owns, so page results from other loads are not attributed to it.
@property (nonatomic, copy, nullable) NSString *htmlRenderID;

@property (nonatomic, readonly, getter=isFinished) BOOL finished;
@property (nonatomic, readonly) AffirmPromoRenderOutcome outcome;
@property (nonatomic, readonly) AffirmPromoRenderMode actualRenderer;
@property (nonatomic, copy, readonly, nullable) NSString *reason;

- (instancetype)initWithRequestedMode:(AffirmPromoRenderMode)requestedMode NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

/// The renderer is chosen once. Returns NO, and changes nothing, if it was already chosen or the render finished.
- (BOOL)selectMode:(AffirmPromoRenderMode)mode;

/// Returns NO, and changes nothing, if the render already finished.
- (BOOL)finishWithOutcome:(AffirmPromoRenderOutcome)outcome
           actualRenderer:(AffirmPromoRenderMode)actualRenderer
                   reason:(nullable NSString *)reason;

/// "T1" … "T9" for a finished render, nil before that.
- (nullable NSString *)terminalState;

@end

NS_ASSUME_NONNULL_END
