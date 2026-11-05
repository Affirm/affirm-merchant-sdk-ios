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

NS_ASSUME_NONNULL_END
