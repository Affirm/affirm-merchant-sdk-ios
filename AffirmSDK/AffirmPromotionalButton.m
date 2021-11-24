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

@interface AffirmPromotionalButton() <WKNavigationDelegate>

@property (nonatomic, strong) NSDecimalNumber *amount;
@property (nonatomic) BOOL showPrequal;
@property (nonatomic) BOOL clickable;

@property (nonatomic, strong) UIButton *button;
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) NSLayoutConstraint *webViewHeightConstraint;

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
        attachment.bounds = CGRectMake(0, -logoSize.height/5, logoSize.width, logoSize.height);
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
    self.showPrequal = YES;
    self.clickable = NO;
    [self configureWebView];
    [self configureButton];
}

- (void)setClickable:(BOOL)clickable
{
    _clickable = clickable;
    self.hidden = !clickable;
}

- (void)configureWebView
{
    WKWebViewConfiguration *configuration = [WKWebViewConfiguration new];
    WKWebView *webView = [[WKWebView alloc] initWithFrame:self.bounds configuration:configuration];
    webView.translatesAutoresizingMaskIntoConstraints = NO;
    webView.navigationDelegate = self;
    webView.hidden = YES;
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
    self.amount = amount.toIntegerCents;
    
    if (amount.doubleValue > [NSDecimalNumber decimalNumberWithString:AFFIRM_MAX_PROMO_AMOUNT].doubleValue) {
        [self configureWithAttributedText:nil response:nil error:nil];
        return;
    }

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
    [AffirmPromoClient send:request handler:^(AffirmResponse * _Nullable response, NSError * _Nullable error) {
        if (response && [response isKindOfClass:[AffirmPromoResponse class]]) {
            AffirmPromoResponse *promoResponse = (AffirmPromoResponse *)response;
            self.showPrequal = promoResponse.showPrequal;
            if (promoResponse.htmlAla != nil && promoResponse.htmlAla.length > 0) {
                [self configureWithHtmlString:promoResponse.htmlAla amount:amount remoteFontURL:remoteFontURL remoteCssURL:remoteCssURL];
                return;
            }
        }
        [self configureWithAttributedText:nil response:response error:error];
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
    self.amount = amount.toIntegerCents;
    
    if (amount.doubleValue > [NSDecimalNumber decimalNumberWithString:AFFIRM_MAX_PROMO_AMOUNT].doubleValue) {
        [self configureWithAttributedText:nil response:nil error:nil];
        return;
    }

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
                                                                       logoType:nil
                                                                      logoColor:FormatAffirmColorString(logoColor)
                                                                          items:items];
    [AffirmPromoClient send:request handler:^(AffirmResponse * _Nullable response, NSError * _Nullable error) {
        NSAttributedString *attributedString = nil;
        if (response && [response isKindOfClass:[AffirmPromoResponse class]]) {
            NSString *template = AFFIRM_DEFAULT_ALA_TEMPLATE;
            AffirmPromoResponse *promoResponse = (AffirmPromoResponse *)response;
            if (promoResponse.ala != nil && promoResponse.ala.length > 0) {
                template = promoResponse.ala;
            }
            self.showPrequal = promoResponse.showPrequal;
            UIImage *logo = nil;
            if (affirmLogoType != AffirmLogoTypeText) {
                logo = [AffirmPromotionalButton getAffirmDisplayForLogoType:affirmLogoType colorType:affirmColor];
            }
            attributedString = [AffirmPromotionalButton appendLogo:logo toText:template font:font textColor:textColor logoType:affirmLogoType];
        }
        [self configureWithAttributedText:attributedString response:response error:error];
    }];
}

- (void)configureWithAttributedText:(nullable NSAttributedString *)attributedText
                           response:(nullable AffirmResponse *)response
                              error:(nullable NSError *)error
{
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
    self.amount = amount.toIntegerCents;

    BOOL hasRemoteCss = remoteCssURL != nil;
    NSString *jsURL = [AffirmConfiguration sharedInstance].jsURL;
    NSURL *baseURL = [NSURL URLWithString:jsURL].baseURL;
    NSMutableDictionary *matchedKeys = [@{@"{{HTML_FRAGMENT}}": htmlString} mutableCopy];

    if (hasRemoteCss) {
        baseURL = remoteCssURL.isFileURL ? [NSBundle mainBundle].bundleURL : remoteCssURL.baseURL;
    }
    matchedKeys[@"{{REMOTE_FONT_URL}}"] = remoteFontURL.absoluteString ?: @"";
    matchedKeys[@"{{REMOTE_CSS_URL}}"] = remoteCssURL.absoluteString ?: @"";
    matchedKeys[@"{{PUBLIC_KEY}}"] = [AffirmConfiguration sharedInstance].publicKey;
    matchedKeys[@"{{JS_URL}}"] = jsURL;

    NSString *filePath = [[NSBundle resourceBundle] pathForResource:@"affirm_promo"
                                                             ofType:@"html"];
    __block NSString *rawContent = [NSString stringWithContentsOfFile:filePath
                                                             encoding:NSUTF8StringEncoding error:nil];
    [matchedKeys enumerateKeysAndObjectsUsingBlock:^(NSString *  _Nonnull key, NSString *  _Nonnull obj, BOOL * _Nonnull stop) {
        rawContent = [rawContent stringByReplacingOccurrencesOfString:key
                                                           withString:obj
                                                              options:NSLiteralSearch
                                                                range:[rawContent rangeOfString:key]];
    }];
    [self.webView loadHTMLString:rawContent baseURL:baseURL];
}

#pragma mark - WKWebView navigation delegate

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    [webView evaluateJavaScript:@"Math.max(document.body.scrollHeight, document.body.offsetHeight, document.documentElement.clientHeight, document.documentElement.scrollHeight, document.documentElement.offsetHeight)"
              completionHandler:^(id _Nullable result, NSError * _Nullable error) {
        if (!error && [result isKindOfClass:[NSNumber class]]) {
            NSNumber *height = result;
            self.webViewHeightConstraint.constant = height.floatValue;
            [self layoutIfNeeded];
        }
    }];
    webView.hidden = NO;
    [self.button setAttributedTitle:nil forState:UIControlStateNormal];
    self.clickable = YES;
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    webView.hidden = YES;
    self.clickable = NO;
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    webView.hidden = YES;
    self.clickable = NO;
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
            @"unit_price": self.amount,
            @"use_promo": @"true",
            @"referring_url": AFFIRM_PREQUAL_REFERRING_URL,
        } mutableCopy];
        if (self.promoID) {
            params[@"promo_external_id"] = self.promoID;
        }
        if (self.pageType) {
            params[@"page_type"] = FormatAffirmPageTypeString(self.pageType);
        }

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
