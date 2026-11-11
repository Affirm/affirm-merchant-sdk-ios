//
//  AffirmPromotionalButton.m
//  AffirmSDK
//
//  Created by yijie on 2019/3/11.
//  Copyright © 2019 Affirm, Inc. All rights reserved.
//

#import "AffirmPromotionalButton.h"
#import "AffirmConfiguration.h"
#import "AffirmUtils.h"
#import "AffirmPrequalModalViewController.h"
#import "AffirmPromoModalViewController.h"
#import "AffirmClient.h"
#import "AffirmRequest.h"
#import "AffirmLogger.h"
#import "AffirmPromoRendering.h"

static NSString *const AFFIRM_DEFAULT_ALA_TEMPLATE = @"Pay over time with Affirm";

static NSString * FormatAffirmLogoString(AffirmLogoType type)
{
    switch (type) {
        case AffirmLogoTypeName:
            return @"logo";
        case AffirmLogoTypeText:
            return @"text";
        case AffirmLogoTypeSymbol:
        case AffirmLogoTypeSymbolHollow:
            return @"hollow_circle";
    }
}

static NSString * FormatAffirmDataTypeString(AffirmLogoType type)
{
    switch (type) {
        case AffirmLogoTypeName:
            return @"logo";
        case AffirmLogoTypeText:
            return @"text";
        case AffirmLogoTypeSymbol:
            return @"symbol";
        case AffirmLogoTypeSymbolHollow:
            return @"symbol";
    }
}

@interface AffirmPromotionalButton() <WKNavigationDelegate, WKScriptMessageHandler>

@property (nonatomic, strong) NSDecimalNumber *amount;
@property (nonatomic) BOOL showPrequal;
@property (nonatomic) BOOL clickable;

@property (nonatomic, strong) UIButton *button;
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) NSLayoutConstraint *webViewHeightConstraint;
@property (nonatomic, strong) AffirmPromoScriptMessageProxy *scriptMessageProxy;
@property (nonatomic) BOOL sanitizerAvailable;
@property (nonatomic) BOOL htmlReady;
@property (nonatomic, copy, nullable) NSURL *htmlBaseURL;
@property (nonatomic, copy, nullable) NSString *htmlRenderID;
@property (nonatomic, strong, nullable) WKNavigation *htmlNavigation;
@property (nonatomic, strong, nullable) NSTimer *htmlTimeoutTimer;
@property (nonatomic, copy, nullable) NSString *loadedHTML;
@property (nonatomic, copy, nullable) NSString *loadedCSS;
@property (nonatomic, copy, nullable) NSString *loadedFont;
@property (nonatomic) BOOL loadedMigrated;
@property (nonatomic, strong, nullable) AffirmPromoRenderOperation *currentOperation;
@property (nonatomic, strong, nullable) UIColor *defaultWebViewBackgroundColor;
@property (nonatomic, strong, nullable) UIColor *defaultWebViewScrollBackgroundColor;

@end

@implementation AffirmPromotionalButton (Helper)

+ (UIImage *)getAffirmDisplayForLogoType:(AffirmLogoType)logoType
                               colorType:(AffirmColorType)colorType
{
    NSString *file = [NSString stringWithFormat:@"%@_%@-transparent_bg", FormatAffirmColorString(colorType), FormatAffirmLogoString(logoType)];
    UIImage *image = [UIImage imageNamed:file inBundle:[NSBundle resourceBundle] compatibleWithTraitCollection:nil];
    return image;
}

+ (CGSize)sizeForLogoType:(AffirmLogoType)logoType
                 logoSize:(CGSize)logoSize
                   height:(CGFloat)height
{
    switch(logoType) {
        case AffirmLogoTypeName:
            return CGSizeMake((logoSize.width * height) / logoSize.height, height);
        case AffirmLogoTypeText:
            return CGSizeZero;
        case AffirmLogoTypeSymbol:
            return CGSizeMake(1.25 * height, 1.25 * height);
        case AffirmLogoTypeSymbolHollow:
            return CGSizeMake(1.25 * height, 1.25 * height);
        default:
            return CGSizeMake((logoSize.width * height) / logoSize.height, height);
    }
}

+ (NSAttributedString *)appendLogo:(UIImage *)logo
                            toText:(NSString *)text
                              font:(UIFont *)font
                         textColor:(UIColor *)textColor
                          logoType:(AffirmLogoType)logoType
{
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:text];
    if (font.pointSize == 0) {
        font = [UIFont systemFontOfSize:15];
    }
    [attributedText addAttributes:@{NSFontAttributeName: font,
                                    NSForegroundColorAttributeName: textColor}
                            range:NSMakeRange(0, attributedText.length)];
    
    if (!logo) {
        return attributedText;
    }
    
    while ([attributedText.mutableString containsString:@"Affirm"]) {
        NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
        attachment.image = logo;
        CGSize logoSize = [self sizeForLogoType:logoType logoSize:logo.size height:font.pointSize];
        attachment.bounds = CGRectMake(0, 0, logoSize.width, logoSize.height);
        NSAttributedString *attributedLogo = [NSAttributedString attributedStringWithAttachment:attachment];
        [attributedText replaceCharactersInRange:[attributedText.mutableString rangeOfString:@"Affirm"] withAttributedString:attributedLogo];
    }
    return attributedText;
}

@end

@implementation AffirmPromotionalButton

#pragma mark - Initialize Method

- (instancetype)initWithPromoID:(nullable NSString *)promoID
                        showCTA:(BOOL)showCTA
       presentingViewController:(UIViewController<AffirmPrequalDelegate> *)presentingViewController
                          frame:(CGRect)frame
{
    [AffirmValidationUtils checkNotNil:presentingViewController name:@"presentingViewController"];
    
    if (self = [super initWithFrame:frame]) {
        _promoID = promoID;
        _pageType = AffirmPageTypeNone;
        _presentingViewController = presentingViewController;
        _showCTA = showCTA;
        [self setup];
    }
    return self;
}

- (instancetype)initWithShowCTA:(BOOL)showCTA
                       pageType:(AffirmPageType)pageType
       presentingViewController:(UIViewController<AffirmPrequalDelegate> *)presentingViewController
                          frame:(CGRect)frame
{
    [AffirmValidationUtils checkNotNil:presentingViewController name:@"presentingViewController"];
    
    if (self = [super initWithFrame:frame]) {
        _promoID = nil;
        _pageType = pageType;
        _presentingViewController = presentingViewController;
        _showCTA = showCTA;
        [self setup];
    }
    return self;
}

- (instancetype)initWithPromoID:(nullable NSString *)promoID
                        showCTA:(BOOL)showCTA
                       pageType:(AffirmPageType)pageType
       presentingViewController:(UIViewController<AffirmPrequalDelegate> *)presentingViewController
                          frame:(CGRect)frame
{
    [AffirmValidationUtils checkNotNil:presentingViewController name:@"presentingViewController"];
    
    if (self = [super initWithFrame:frame]) {
        _promoID = promoID;
        _pageType = pageType;
        _presentingViewController = presentingViewController;
        _showCTA = showCTA;
        [self setup];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setup];
}

- (void)setup
{
    self.isAccessibilityElement = YES;
    self.accessibilityTraits = UIAccessibilityTraitButton;
    self.showPrequal = YES;
    self.clickable = NO;
    [self configureWebView];
    [self configureButton];
}

- (void)dealloc
{
    AffirmPromoRenderOperation *operation = self.currentOperation;
    if ([operation finishWithOutcome:AffirmPromoRenderOutcomeCancelled
                      actualRenderer:AffirmPromoRenderModeNone
                              reason:AffirmPromoRenderReasonHostDestroyed]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:AffirmPromoRenderDidFinishNotification
                                                            object:nil
                                                          userInfo:@{AffirmPromoRenderOperationKey: operation}];
    }
    [self.htmlTimeoutTimer invalidate];
    self.scriptMessageProxy.target = nil;
    [self.webView.configuration.userContentController removeScriptMessageHandlerForName:AffirmPromoScriptMessageName];
}

- (BOOL)accessibilityActivate
{
    [self showALAModal:nil];
    return YES;
}

- (void)setClickable:(BOOL)clickable
{
    _clickable = clickable;
    self.hidden = !clickable;
}

- (void)configureWebView
{
    WKWebViewConfiguration *configuration = [WKWebViewConfiguration new];
    NSString *sanitizer = AffirmPromoSanitizerSource();
    self.sanitizerAvailable = sanitizer.length > 0;
    if (self.sanitizerAvailable) {
        WKUserScript *userScript = [[WKUserScript alloc] initWithSource:sanitizer
                                                          injectionTime:WKUserScriptInjectionTimeAtDocumentStart
                                                       forMainFrameOnly:YES];
        [configuration.userContentController addUserScript:userScript];
    }
    self.scriptMessageProxy = [AffirmPromoScriptMessageProxy new];
    self.scriptMessageProxy.target = self;
    [configuration.userContentController addScriptMessageHandler:self.scriptMessageProxy
                                                            name:AffirmPromoScriptMessageName];

    WKWebView *webView = [[WKWebView alloc] initWithFrame:self.bounds configuration:configuration];
    webView.translatesAutoresizingMaskIntoConstraints = NO;
    webView.navigationDelegate = self;
    webView.hidden = YES;
    webView.allowsLinkPreview = NO;
    self.defaultWebViewBackgroundColor = webView.backgroundColor;
    self.defaultWebViewScrollBackgroundColor = webView.scrollView.backgroundColor;
    [self addSubview:self.webView = webView];
    NSDictionary *views = NSDictionaryOfVariableBindings(webView);
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[webView]|" options:0 metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[webView]|" options:0 metrics:nil views:views]];
    self.webViewHeightConstraint = [NSLayoutConstraint constraintWithItem:webView
                                                                attribute:NSLayoutAttributeHeight
                                                                relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                   toItem:nil
                                                                attribute:NSLayoutAttributeNotAnAttribute
                                                               multiplier:0
                                                                 constant:CGRectGetHeight(self.bounds)];
    [self addConstraint:self.webViewHeightConstraint];
}

- (void)configureButton
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.titleLabel.numberOfLines = 0;
    button.titleLabel.adjustsFontSizeToFitWidth = YES;
    [button addTarget:self action:@selector(showALAModal:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.button = button];
    NSDictionary *views = NSDictionaryOfVariableBindings(button);
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[button]|" options:0 metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[button]|" options:0 metrics:nil views:views]];
}

- (void)configureByHtmlStylingWithAmount:(NSDecimalNumber *)amount
{
    [self configureByHtmlStylingWithAmount:amount
                            affirmLogoType:AffirmLogoTypeName
                               affirmColor:AffirmColorTypeBlue];
}

- (void)configureByHtmlStylingWithAmount:(NSDecimalNumber *)amount
                          affirmLogoType:(AffirmLogoType)affirmLogoType
                             affirmColor:(AffirmColorType)affirmColor
{
    [self configureByHtmlStylingWithAmount:amount
                            affirmLogoType:affirmLogoType
                               affirmColor:affirmColor
                             remoteFontURL:nil
                              remoteCssURL:nil];
}

- (void)configureByHtmlStylingWithAmount:(NSDecimalNumber *)amount
                          affirmLogoType:(AffirmLogoType)affirmLogoType
                             affirmColor:(AffirmColorType)affirmColor
                            remoteCssURL:(nullable NSURL *)remoteCssURL
{
    [self configureByHtmlStylingWithAmount:amount
                            affirmLogoType:affirmLogoType
                               affirmColor:affirmColor
                             remoteFontURL:nil
                              remoteCssURL:remoteCssURL];
}

- (void)configureByHtmlStylingWithAmount:(NSDecimalNumber *)amount
                          affirmLogoType:(AffirmLogoType)affirmLogoType
                             affirmColor:(AffirmColorType)affirmColor
                           remoteFontURL:(nullable NSURL *)remoteFontURL
                            remoteCssURL:(nullable NSURL *)remoteCssURL
{
    [self configureByHtmlStylingWithAmount:amount
                                     items:nil
                            affirmLogoType:affirmLogoType
                               affirmColor:affirmColor
                             remoteFontURL:remoteFontURL
                              remoteCssURL:remoteCssURL];
}

- (void)configureByHtmlStylingWithAmount:(NSDecimalNumber *)amount
                                   items:(nullable NSArray <AffirmItem *>*)items
                          affirmLogoType:(AffirmLogoType)affirmLogoType
                             affirmColor:(AffirmColorType)affirmColor
                           remoteFontURL:(nullable NSURL *)remoteFontURL
                            remoteCssURL:(nullable NSURL *)remoteCssURL
{
    [AffirmValidationUtils checkNotNil:amount name:@"amount"];
    self.amount = amount;
    
    AffirmColorType logoColor = affirmColor;
    // Using default type when logoColor == AffirmColorTypeBlueBlack
    if (logoColor == AffirmColorTypeBlueBlack) {
        logoColor = AffirmColorTypeDefault;
    }
    
    AffirmPromoRequest *request = [[AffirmPromoRequest alloc] initWithPublicKey:[AffirmConfiguration sharedInstance].publicKey
                                                                        promoId:self.promoID
                                                                         amount:self.amount
                                                                        showCTA:self.showCTA
                                                                       pageType:FormatAffirmPageTypeString(self.pageType)
                                                                       logoType:FormatAffirmDataTypeString(affirmLogoType)
                                                                      logoColor:FormatAffirmColorString(logoColor)
                                                                          items:items];
    AffirmPromoRenderPolicy *policy = [[AffirmPromoRenderPolicy alloc] initWithRequestedMode:AffirmPromoRenderModeHTML
                                                                                      optOut:[AffirmConfiguration sharedInstance].useLegacyNativeRendering
                                                                                        font:nil];
    AffirmPromoRenderOperation *operation = [self beginOperationWithPolicy:policy];
    __weak typeof(self) weakSelf = self;
    [AffirmPromoClient send:request handler:^(AffirmResponse * _Nullable response, NSError * _Nullable error) {
        AffirmPromotionalButton *strongSelf = weakSelf;
        if (strongSelf == nil || strongSelf.currentOperation != operation || operation.finished) {
            return;
        }
        if (![response isKindOfClass:[AffirmPromoResponse class]]) {
            [strongSelf configureWithAttributedText:nil response:response error:error];
            [strongSelf finishOperation:operation
                            withOutcome:AffirmPromoRenderOutcomeFailure
                         actualRenderer:AffirmPromoRenderModeNone
                                 reason:AffirmPromoRenderReasonFetchError];
            return;
        }
        AffirmPromoResponse *promoResponse = (AffirmPromoResponse *)response;
        strongSelf.showPrequal = promoResponse.showPrequal;
        if (promoResponse.ala.length > 0) {
            strongSelf.accessibilityLabel = [promoResponse.ala stringByReplacingOccurrencesOfString:@"{Affirm}" withString:@"Affirm"];
        }
        [operation decideWithFlagStatus:promoResponse.renderFlagStatus];
        if (promoResponse.htmlAla.length == 0) {
            [strongSelf configureWithAttributedText:nil response:response error:error];
            [strongSelf finishOperation:operation
                            withOutcome:AffirmPromoRenderOutcomeEmptyContent
                         actualRenderer:AffirmPromoRenderModeNone
                                 reason:AffirmPromoRenderReasonMissingHTML];
            return;
        }
        [strongSelf renderHTMLString:promoResponse.htmlAla
                       remoteFontURL:remoteFontURL
                        remoteCssURL:remoteCssURL
                           operation:operation];
    }];
}

- (void)configureWithAmount:(NSDecimalNumber *)amount
             affirmLogoType:(AffirmLogoType)affirmLogoType
                affirmColor:(AffirmColorType)affirmColor
                maxFontSize:(CGFloat)maxFontSize
{
    [self configureWithAmount:amount
               affirmLogoType:affirmLogoType
                  affirmColor:affirmColor
                         font:[UIFont systemFontOfSize:maxFontSize]
                    textColor:[UIColor darkTextColor]];
}

- (void)configureWithAmount:(NSDecimalNumber *)amount
             affirmLogoType:(AffirmLogoType)affirmLogoType
                affirmColor:(AffirmColorType)affirmColor
                       font:(UIFont *)font
                  textColor:(UIColor *)textColor
{
    [self configureWithAmount:amount
                        items:nil
               affirmLogoType:affirmLogoType
                  affirmColor:affirmColor
                         font:font
                    textColor:textColor];
}

- (void)configureWithAmount:(NSDecimalNumber *)amount
                      items:(nullable NSArray <AffirmItem *>*)items
             affirmLogoType:(AffirmLogoType)affirmLogoType
                affirmColor:(AffirmColorType)affirmColor
                       font:(UIFont *)font
                  textColor:(UIColor *)textColor
{
    [AffirmValidationUtils checkNotNil:amount name:@"amount"];
    self.amount = amount;
    
    AffirmColorType logoColor = affirmColor;
    // Using default type when logoColor == AffirmColorTypeBlueBlack
    if (logoColor == AffirmColorTypeBlueBlack) {
        logoColor = AffirmColorTypeDefault;
    }
    
    AffirmPromoRequest *request = [[AffirmPromoRequest alloc] initWithPublicKey:[AffirmConfiguration sharedInstance].publicKey
                                                                        promoId:self.promoID
                                                                         amount:self.amount
                                                                        showCTA:self.showCTA
                                                                       pageType:FormatAffirmPageTypeString(self.pageType)
                                                                       logoType:affirmLogoType == AffirmLogoTypeName ? nil : FormatAffirmDataTypeString(affirmLogoType)
                                                                      logoColor:FormatAffirmColorString(logoColor)
                                                                          items:items];
    AffirmPromoRenderPolicy *policy = [[AffirmPromoRenderPolicy alloc] initWithRequestedMode:AffirmPromoRenderModeNative
                                                                                      optOut:[AffirmConfiguration sharedInstance].useLegacyNativeRendering
                                                                                        font:font];
    AffirmPromoRenderOperation *operation = [self beginOperationWithPolicy:policy];
    __weak typeof(self) weakSelf = self;
    [AffirmPromoClient send:request handler:^(AffirmResponse * _Nullable response, NSError * _Nullable error) {
        AffirmPromotionalButton *strongSelf = weakSelf;
        if (strongSelf == nil || strongSelf.currentOperation != operation || operation.finished) {
            return;
        }
        if (![response isKindOfClass:[AffirmPromoResponse class]]) {
            [strongSelf configureWithAttributedText:nil response:response error:error];
            [strongSelf finishOperation:operation
                            withOutcome:AffirmPromoRenderOutcomeFailure
                         actualRenderer:AffirmPromoRenderModeNone
                                 reason:AffirmPromoRenderReasonFetchError];
            return;
        }
        AffirmPromoResponse *promoResponse = (AffirmPromoResponse *)response;
        NSString *template = AFFIRM_DEFAULT_ALA_TEMPLATE;
        if (promoResponse.ala.length > 0) {
            template = promoResponse.ala;
            strongSelf.accessibilityLabel = [promoResponse.ala stringByReplacingOccurrencesOfString:@"{Affirm}" withString:@"Affirm"];
        }
        strongSelf.showPrequal = promoResponse.showPrequal;
        NSAttributedString *(^nativeText)(void) = ^NSAttributedString *{
            UIImage *logo = nil;
            if (affirmLogoType != AffirmLogoTypeText) {
                logo = [AffirmPromotionalButton getAffirmDisplayForLogoType:affirmLogoType colorType:affirmColor];
            }
            return [AffirmPromotionalButton appendLogo:logo toText:template font:font textColor:textColor logoType:affirmLogoType];
        };
        if ([operation decideWithFlagStatus:promoResponse.renderFlagStatus] == AffirmPromoRenderModeHTML) {
            operation.nativeFallback = promoResponse.ala.length > 0 ? nativeText : nil;
            [strongSelf renderMigratedHTMLString:promoResponse.htmlAla operation:operation];
            return;
        }
        @try {
            [strongSelf configureWithAttributedText:nativeText() response:response error:error];
        } @catch (NSException *exception) {
            [strongSelf hidePromo];
            [strongSelf finishOperation:operation
                            withOutcome:AffirmPromoRenderOutcomeFailure
                         actualRenderer:AffirmPromoRenderModeNone
                                 reason:AffirmPromoRenderReasonNativeError];
            return;
        }
        [strongSelf finishOperation:operation
                        withOutcome:AffirmPromoRenderOutcomeSuccess
                     actualRenderer:AffirmPromoRenderModeNative
                             reason:nil];
    }];
}

- (void)configureWithAttributedText:(nullable NSAttributedString *)attributedText
                           response:(nullable AffirmResponse *)response
                              error:(nullable NSError *)error
{
    [self supersedeHTMLRender];
    self.webView.hidden = YES;
    self.clickable = NO;
    if (attributedText) {
        [self.button setAttributedTitle:attributedText forState:UIControlStateNormal];
        self.clickable = YES;
    } else if (response && [response isKindOfClass:[AffirmErrorResponse class]]) {
        [self.button setAttributedTitle:nil forState:UIControlStateNormal];
        AffirmErrorResponse *errorResponse = (AffirmErrorResponse *)response;
        [[AffirmLogger sharedInstance] logEvent:@"Request Promotional Message Failed"
                                     parameters:@{@"message": errorResponse.message, @"statusCode": errorResponse.statusCode}];
        if (self.presentingViewController && [self.presentingViewController respondsToSelector:@selector(webViewController:didFailWithError:)]) {
            [self.presentingViewController webViewController:nil
                                            didFailWithError:[errorResponse.dictionary convertToNSErrorWithCode:errorResponse.statusCode]];
        }
    } else {
        [self.button setAttributedTitle:nil forState:UIControlStateNormal];
        NSString *event = @"Request Promotional Message Failed";
        [[AffirmLogger sharedInstance] logEvent:event
                                     parameters:@{@"message": error != nil ? error.localizedDescription : event}];
        if (self.presentingViewController && [self.presentingViewController respondsToSelector:@selector(webViewController:didFailWithError:)]) {
            [self.presentingViewController webViewController:nil
                                            didFailWithError:error];
        }
    }
}

- (void)configureWithHtmlString:(NSString *)htmlString
                         amount:(NSDecimalNumber *)amount
                  remoteFontURL:(nullable NSURL *)remoteFontURL
                   remoteCssURL:(nullable NSURL *)remoteCssURL
{
    [AffirmValidationUtils checkNotNil:amount name:@"amount"];
    self.amount = amount;
    // Unmanaged: no request and no render report, but it still replaces any managed render.
    [self supersedeCurrentOperation];
    [self renderHTMLString:htmlString remoteFontURL:remoteFontURL remoteCssURL:remoteCssURL operation:nil];
}

- (void)renderMigratedHTMLString:(NSString *)htmlString operation:(AffirmPromoRenderOperation *)operation
{
    if (htmlString.length == 0) {
        [self fallBackToNativeForOperation:operation reason:AffirmPromoRenderReasonMissingHTML];
        return;
    }
    // remoteFontURL and remoteCssURL belong to explicit HTML styling; a migrated call has neither.
    [self renderHTMLString:htmlString remoteFontURL:nil remoteCssURL:nil operation:operation];
}

- (void)fallBackToNativeForOperation:(AffirmPromoRenderOperation *)operation reason:(NSString *)reason
{
    operation.fallbackReason = reason;
    if (operation.nativeFallback == nil) {
        [self hidePromo];
        BOOL nothingToTry = [reason isEqualToString:AffirmPromoRenderReasonMissingHTML];
        [self finishOperation:operation
                  withOutcome:nothingToTry ? AffirmPromoRenderOutcomeEmptyContent : AffirmPromoRenderOutcomeFailure
               actualRenderer:AffirmPromoRenderModeNone
                       reason:reason];
        return;
    }
    @try {
        [self configureWithAttributedText:operation.nativeFallback() response:nil error:nil];
    } @catch (NSException *exception) {
        [self hidePromo];
        [self finishOperation:operation
                  withOutcome:AffirmPromoRenderOutcomeFailure
               actualRenderer:AffirmPromoRenderModeNone
                       reason:AffirmPromoRenderReasonNativeError];
        return;
    }
    [self finishOperation:operation
              withOutcome:AffirmPromoRenderOutcomeSuccess
           actualRenderer:AffirmPromoRenderModeNative
                   reason:nil];
}

- (void)applyWebViewBackgroundForOperation:(nullable AffirmPromoRenderOperation *)operation
{
    // Migrated calls let the container show through; explicit HTML keeps the web view defaults.
    BOOL transparent = operation.requestedMode == AffirmPromoRenderModeNative;
    self.webView.opaque = !transparent;
    self.webView.backgroundColor = transparent ? [UIColor clearColor] : self.defaultWebViewBackgroundColor;
    self.webView.scrollView.backgroundColor = transparent ? [UIColor clearColor] : self.defaultWebViewScrollBackgroundColor;
}

- (void)renderHTMLString:(NSString *)htmlString
           remoteFontURL:(nullable NSURL *)remoteFontURL
            remoteCssURL:(nullable NSURL *)remoteCssURL
               operation:(nullable AffirmPromoRenderOperation *)operation
{
    [self applyWebViewBackgroundForOperation:operation];
    NSString *css = remoteCssURL.absoluteString ?: @"";
    NSString *font = remoteFontURL.absoluteString ?: @"";
    BOOL migrated = operation.requestedMode == AffirmPromoRenderModeNative;
    if (!self.hidden && !self.webView.hidden && self.htmlReady
        && [self.loadedHTML isEqualToString:htmlString ?: @""]
        && [self.loadedCSS isEqualToString:css]
        && [self.loadedFont isEqualToString:font]
        && self.loadedMigrated == migrated) {
        operation.htmlRenderID = self.htmlRenderID;
        [self finishOperation:operation
                  withOutcome:AffirmPromoRenderOutcomeSuccess
               actualRenderer:AffirmPromoRenderModeHTML
                       reason:nil];
        return;
    }

    [self supersedeHTMLRender];
    self.loadedHTML = htmlString ?: @"";
    self.loadedCSS = css;
    self.loadedFont = font;
    self.loadedMigrated = migrated;
    self.webView.hidden = YES;
    self.htmlReady = NO;
    self.clickable = NO;

    NSString *renderID = [NSUUID UUID].UUIDString;
    self.htmlRenderID = renderID;
    operation.htmlRenderID = renderID;
    if (!self.sanitizerAvailable) {
        [self failHTMLRenderWithReason:AffirmPromoRenderReasonSanitizerUnavailable renderID:renderID];
        return;
    }
    if (!AffirmPromoPermittedStylesheetURL(remoteCssURL) || !AffirmPromoPermittedStylesheetURL(remoteFontURL)) {
        [self failHTMLRenderWithReason:AffirmPromoRenderReasonResourceFailed renderID:renderID];
        return;
    }

    AffirmConfiguration *configuration = [AffirmConfiguration sharedInstance];
    NSDictionary *payload = @{
        @"renderId": renderID,
        @"html": htmlString ?: @"",
        @"remoteCssURL": css,
        @"remoteFontURL": font,
        @"publicKey": configuration.publicKey ?: @"",
        @"jsURL": configuration.jsURL ?: @"",
        @"locale": configuration.locale ?: @"",
        @"countryCode": configuration.countryCode ?: @"",
        @"bundledCSS": AffirmPromoBundledCSS(),
        // Migrated calls match the native button's zero inset; explicit HTML keeps the browser margin.
        @"zeroMargin": @(migrated),
        @"timeoutMs": @((NSInteger)(AffirmPromoHTMLTimeoutSeconds * 1000))
    };
    NSString *page = AffirmPromoHTMLDocumentWithPayload(payload);
    if (page.length == 0) {
        [self failHTMLRenderWithReason:AffirmPromoRenderReasonTemplateError renderID:renderID];
        return;
    }

    NSURL *baseURL = nil;
    if (remoteCssURL.isFileURL) {
        baseURL = remoteCssURL.URLByDeletingLastPathComponent;
    } else if (remoteFontURL.isFileURL) {
        baseURL = remoteFontURL.URLByDeletingLastPathComponent;
    }
    self.htmlBaseURL = baseURL;
    self.htmlNavigation = [self.webView loadHTMLString:page baseURL:baseURL];
    [self scheduleHTMLTimeoutForRenderID:renderID];
}

#pragma mark - Render ownership

- (AffirmPromoRenderOperation *)beginOperationWithPolicy:(AffirmPromoRenderPolicy *)policy
{
    [self supersedeCurrentOperation];
    AffirmPromoRenderOperation *operation = [[AffirmPromoRenderOperation alloc] initWithPolicy:policy];
    self.currentOperation = operation;
    return operation;
}

- (void)supersedeCurrentOperation
{
    // Content already on screen stays until the next render replaces it; only an in-flight
    // page load is stopped.
    if (self.htmlRenderID != nil && !self.htmlReady) {
        [self supersedeHTMLRender];
    }
    AffirmPromoRenderOperation *operation = self.currentOperation;
    self.currentOperation = nil;
    if (operation == nil) {
        return;
    }
    if ([operation finishWithOutcome:AffirmPromoRenderOutcomeCancelled
                      actualRenderer:AffirmPromoRenderModeNone
                              reason:AffirmPromoRenderReasonSuperseded]) {
        [self postFinishedOperation:operation];
    }
}

- (void)finishOperation:(nullable AffirmPromoRenderOperation *)operation
            withOutcome:(AffirmPromoRenderOutcome)outcome
         actualRenderer:(AffirmPromoRenderMode)actualRenderer
                 reason:(nullable NSString *)reason
{
    if (operation == nil || operation != self.currentOperation) {
        return;
    }
    if ([operation finishWithOutcome:outcome actualRenderer:actualRenderer reason:reason]) {
        [self postFinishedOperation:operation];
    }
}

- (void)postFinishedOperation:(AffirmPromoRenderOperation *)operation
{
    [[NSNotificationCenter defaultCenter] postNotificationName:AffirmPromoRenderDidFinishNotification
                                                        object:self
                                                      userInfo:@{AffirmPromoRenderOperationKey: operation}];
}

- (void)htmlRenderID:(NSString *)renderID didFinishWithFailureReason:(nullable NSString *)reason
{
    AffirmPromoRenderOperation *operation = self.currentOperation;
    if (operation.finished || ![operation.htmlRenderID isEqualToString:renderID]) {
        return;
    }
    if (reason == nil) {
        [self finishOperation:operation
                  withOutcome:AffirmPromoRenderOutcomeSuccess
               actualRenderer:AffirmPromoRenderModeHTML
                       reason:nil];
    } else if (operation.requestedMode == AffirmPromoRenderModeNative) {
        [self fallBackToNativeForOperation:operation reason:reason];
    } else {
        [self finishOperation:operation
                  withOutcome:AffirmPromoRenderOutcomeFailure
               actualRenderer:AffirmPromoRenderModeNone
                       reason:reason];
    }
}

- (void)hidePromo
{
    [self supersedeHTMLRender];
    self.loadedHTML = nil;
    self.loadedCSS = nil;
    self.loadedFont = nil;
    self.webView.hidden = YES;
    [self.button setAttributedTitle:nil forState:UIControlStateNormal];
    self.clickable = NO;
}

- (void)supersedeHTMLRender
{
    [self.htmlTimeoutTimer invalidate];
    self.htmlTimeoutTimer = nil;
    self.htmlRenderID = nil;
    self.htmlNavigation = nil;
    self.htmlReady = NO;
    self.htmlBaseURL = nil;
    [self.webView stopLoading];
}

- (BOOL)isExpectedHTMLLoadURL:(nullable NSURL *)url
{
    if (self.htmlRenderID.length == 0 || url == nil) {
        return NO;
    }
    NSURL *expected = self.htmlBaseURL ?: [NSURL URLWithString:@"about:blank"];
    return [url.absoluteString isEqualToString:expected.absoluteString];
}

- (void)scheduleHTMLTimeoutForRenderID:(NSString *)renderID
{
    [self.htmlTimeoutTimer invalidate];
    __weak typeof(self) weakSelf = self;
    self.htmlTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:AffirmPromoHTMLTimeoutSeconds
                                                             repeats:NO
                                                               block:^(NSTimer *timer) {
        [weakSelf failHTMLRenderWithReason:AffirmPromoRenderReasonHTMLTimeout renderID:renderID];
    }];
}

- (void)failHTMLRenderWithReason:(NSString *)reason renderID:(nullable NSString *)renderID
{
    if (renderID.length == 0 || ![renderID isEqualToString:self.htmlRenderID]) {
        return;
    }
    [self.htmlTimeoutTimer invalidate];
    self.htmlTimeoutTimer = nil;
    self.htmlRenderID = nil;
    self.htmlNavigation = nil;
    self.htmlReady = NO;
    self.htmlBaseURL = nil;
    self.loadedHTML = nil;
    self.loadedCSS = nil;
    self.loadedFont = nil;
    self.webView.hidden = YES;
    self.clickable = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:AffirmPromoHTMLRenderDidFinishNotification
                                                        object:self
                                                      userInfo:@{@"outcome": @"failure", @"reason": reason ?: @""}];
    [self htmlRenderID:renderID didFinishWithFailureReason:reason ?: AffirmPromoRenderReasonScriptError];
}

- (void)applyContentHeight:(double)cssHeight
{
    CGFloat height = AffirmPromoHeightForCSSPixels(cssHeight);
    if (height <= 0 || self.webViewHeightConstraint.constant == height) {
        return;
    }
    self.webViewHeightConstraint.constant = height;
    [self layoutIfNeeded];
}

- (BOOL)isCurrentHTMLNavigation:(WKNavigation *)navigation
{
    return navigation != nil && navigation == self.htmlNavigation;
}

#pragma mark - WKWebView navigation delegate

- (void)webView:(WKWebView *)webView
decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    // loadHTMLString is the only main-frame load we start, and its request URL is the base URL
    // (or about:blank). Matching on that, rather than a one-shot flag, stays correct when a
    // second render starts before the first render's policy callback has run.
    BOOL isMainFrameLoad = navigationAction.navigationType == WKNavigationTypeOther
        && navigationAction.targetFrame.mainFrame;
    if (isMainFrameLoad && [self isExpectedHTMLLoadURL:navigationAction.request.URL]) {
        decisionHandler(WKNavigationActionPolicyAllow);
        return;
    }
    if (navigationAction.navigationType == WKNavigationTypeLinkActivated && self.clickable) {
        [self showALAModal:nil];
    }
    decisionHandler(WKNavigationActionPolicyCancel);
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    // Readiness comes from the page, after sanitizing and loading stylesheets, images and fonts.
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    if (![self isCurrentHTMLNavigation:navigation] || error.code == NSURLErrorCancelled) {
        return;
    }
    [self failHTMLRenderWithReason:AffirmPromoRenderReasonLoadError renderID:self.htmlRenderID];
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    if (![self isCurrentHTMLNavigation:navigation] || error.code == NSURLErrorCancelled) {
        return;
    }
    [self failHTMLRenderWithReason:AffirmPromoRenderReasonLoadError renderID:self.htmlRenderID];
}

- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView
{
    if (self.htmlRenderID != nil && self.htmlReady) {
        // The render already finished when the page became ready, so there is nothing to report.
        [self hidePromo];
        return;
    }
    [self failHTMLRenderWithReason:AffirmPromoRenderReasonRenderProcessGone renderID:self.htmlRenderID];
}

- (void)userContentController:(WKUserContentController *)userContentController
      didReceiveScriptMessage:(WKScriptMessage *)message
{
    if (![message.name isEqualToString:AffirmPromoScriptMessageName] || ![message.body isKindOfClass:[NSDictionary class]]) {
        return;
    }
    NSDictionary *body = message.body;
    NSString *renderID = [body[@"renderId"] isKindOfClass:[NSString class]] ? body[@"renderId"] : nil;
    if (renderID.length == 0 || ![renderID isEqualToString:self.htmlRenderID]) {
        return;
    }
    NSString *event = [body[@"event"] isKindOfClass:[NSString class]] ? body[@"event"] : nil;
    if ([event isEqualToString:@"ready"]) {
        if (self.htmlReady) {
            return;
        }
        [self.htmlTimeoutTimer invalidate];
        self.htmlTimeoutTimer = nil;
        self.htmlReady = YES;
        [self applyContentHeight:[body[@"height"] doubleValue]];
        self.webView.hidden = NO;
        [self.button setAttributedTitle:nil forState:UIControlStateNormal];
        self.clickable = YES;
        [[NSNotificationCenter defaultCenter] postNotificationName:AffirmPromoHTMLRenderDidFinishNotification
                                                            object:self
                                                          userInfo:@{@"outcome": @"ready"}];
        [self htmlRenderID:renderID didFinishWithFailureReason:nil];
    } else if ([event isEqualToString:@"height"]) {
        if (self.htmlReady) {
            [self applyContentHeight:[body[@"height"] doubleValue]];
        }
    } else if ([event isEqualToString:@"failure"]) {
        NSString *reason = [body[@"reason"] isKindOfClass:[NSString class]] ? body[@"reason"] : nil;
        [self failHTMLRenderWithReason:AffirmPromoRenderReasonFromPage(reason) renderID:renderID];
    }
}

#pragma mark - Event Response

- (void)showALAModal:(UIButton *)sender
{
    NSParameterAssert(self.amount != nil);
    if (!self.clickable) {
        return;
    }
    
    if (self.showPrequal) {
        NSMutableDictionary *params = [@{
            @"public_api_key": [AffirmConfiguration sharedInstance].publicKey,
            @"unit_price": [self.amount toIntegerCents],
            @"use_promo": @"true",
            @"referring_url": AFFIRM_PREQUAL_REFERRING_URL,
        } mutableCopy];
        if (self.promoID) {
            params[@"promo_external_id"] = self.promoID;
        }
        if (self.pageType) {
            params[@"page_type"] = FormatAffirmPageTypeString(self.pageType);
        }
        params[@"locale"] = [AffirmConfiguration sharedInstance].locale;
        
        NSString *url = [NSString stringWithFormat:@"%@/apps/prequal/", [AffirmPromoClient host]];
        NSURL *requestURL = [NSURL URLWithString:[NSString stringWithFormat:@"?%@", [params queryURLEncoding]]
                                   relativeToURL:[NSURL URLWithString:url]];
        AffirmPrequalModalViewController *viewController = [[AffirmPrequalModalViewController alloc] initWithURL:requestURL
                                                                                                        delegate:self.presentingViewController];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:viewController];
        [self.presentingViewController presentViewController:nav
                                                    animated:YES
                                                  completion:nil];
    } else {
        AffirmPromoModalViewController *viewController = [[AffirmPromoModalViewController alloc] initWithPromoId:self.promoID
                                                                                                          amount:self.amount
                                                                                                        delegate:self.presentingViewController];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:viewController];
        [self.presentingViewController presentViewController:nav
                                                    animated:YES
                                                  completion:nil];
    }
}

@end
