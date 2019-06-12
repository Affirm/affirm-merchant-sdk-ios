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

@interface AffirmPromotionalButton() <WKNavigationDelegate>

@property (nonatomic, strong) NSDecimalNumber *amount;
@property (nonatomic) BOOL showPrequal;
@property (nonatomic) BOOL clickable;

@property (nonatomic, strong) UIButton *button;
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) NSLayoutConstraint *webViewHeightConstraint;

@end

static NSString *const AFFIRM_DEFAULT_ALA_TEMPLATE = @"Buy in monthly payments with Affirm";

static NSString * FormatAffirmPageTypeString(AffirmPageType type)
{
    switch (type) {
        case AffirmPageTypeNone:
            return nil;
        case AffirmPageTypeBanner:
            return @"banner";
        case AffirmPageTypeCart:
            return @"cart";
        case AffirmPageTypeCategory:
            return @"category";
        case AffirmPageTypeHomepage:
            return @"homepage";
        case AffirmPageTypeLanding:
            return @"landing";
        case AffirmPageTypePayment:
            return @"payment";
        case AffirmPageTypeProduct:
            return @"product";
        case AffirmPageTypeSearch:
            return @"search";
    }
}

static NSString * FormatLogoString(AffirmLogoType type)
{
    switch (type) {
        case AffirmLogoTypeName:
            return @"logo";
        case AffirmLogoTypeText:
            return @"text";
        case AffirmLogoTypeSymbol:
            return @"solid_circle";
        case AffirmLogoTypeSymbolHollow:
            return @"hollow_circle";
    }
}

static NSString * FormatAffirmColorString(AffirmColorType type)
{
    switch (type) {
        case AffirmColorTypeBlue:
            return @"blue";
        case AffirmColorTypeBlack:
            return @"black";
        case AffirmColorTypeWhite:
            return @"white";
        case AffirmColorTypeDefault:
            return @"blue";
    }
}

@implementation AffirmPromotionalButton (Helper)

+ (UIImage *)getAffirmDisplayForLogoType:(AffirmLogoType)logoType
                               colorType:(AffirmColorType)colorType
{
    NSString *file = [NSString stringWithFormat:@"%@_%@-transparent_bg", FormatAffirmColorString(colorType), FormatLogoString(logoType)];
    UIImage *image = [UIImage imageNamed:file inBundle:[NSBundle resourceBundle] compatibleWithTraitCollection:nil];
    return image;
}

- (CGSize)sizeForLogoType:(AffirmLogoType)logoType
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

- (NSAttributedString *)appendLogo:(UIImage *)logo
                            toText:(NSString *)text
                              font:(CGFloat)fontSize
                          logoType:(AffirmLogoType)logoType
{
    if (!logo) {
        return [[NSAttributedString alloc] initWithString:text];
    }
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:text];
    [attributedText addAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:fontSize],
                                    NSForegroundColorAttributeName: self.button.titleLabel.textColor}
                            range:NSMakeRange(0, attributedText.length)];
    while ([attributedText.mutableString containsString:@"Affirm"]) {
        NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
        attachment.image = logo;
        CGSize logoSize = [self sizeForLogoType:logoType logoSize:logo.size height:fontSize];
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
    [AffirmValidationUtils checkNotNil:amount name:@"amount"];
    self.amount = amount.toIntegerCents;

    AffirmPromoRequest *request = [[AffirmPromoRequest alloc] initWithPublicKey:[AffirmConfiguration sharedInstance].publicKey
                                                                        promoId:self.promoID
                                                                         amount:self.amount
                                                                        showCTA:self.showCTA
                                                                       pageType:FormatAffirmPageTypeString(self.pageType)];
    [AffirmCheckoutClient send:request handler:^(id<AffirmResponseProtocol> _Nullable response, NSError * _Nullable error) {
        if (response && [response isKindOfClass:[AffirmPromoResponse class]]) {
            AffirmPromoResponse *promoResponse = (AffirmPromoResponse *)response;
            self.showPrequal = promoResponse.showPrequal;
            if (promoResponse.htmlAla != nil && promoResponse.htmlAla.length > 0) {
                NSString *jsURL = [AffirmConfiguration sharedInstance].isProductionEnvironment ? AFFIRM_JS_URL : AFFIRM_SANDBOX_JS_URL;
                NSString *filePath = [[NSBundle resourceBundle] pathForResource:@"affirm_promo"
                                                                         ofType:@"html"];
                __block NSString *rawContent = [NSString stringWithContentsOfFile:filePath
                                                                         encoding:NSUTF8StringEncoding error:nil];
                [@{@"{{PUBLIC_KEY}}": [AffirmConfiguration sharedInstance].publicKey,
                   @"{{JS_URL}}": jsURL,
                   @"{{HTML_FRAGMENT}}": promoResponse.htmlAla}
                 enumerateKeysAndObjectsUsingBlock:^(NSString *  _Nonnull key, NSString *  _Nonnull obj, BOOL * _Nonnull stop) {
                     rawContent = [rawContent stringByReplacingOccurrencesOfString:key
                                                                        withString:obj
                                                                           options:NSLiteralSearch
                                                                             range:[rawContent rangeOfString:key]];
                 }];
                NSString *baseUrl = [NSString stringWithFormat:@"https://%@", [NSURL URLWithString:jsURL].host];
                [self.webView loadHTMLString:rawContent baseURL:[NSURL URLWithString:baseUrl]];
            }
        } else {
            [self configureWithAttributedText:nil response:response error:error];
        }
    }];
}

- (void)configureWithAmount:(NSDecimalNumber *)amount
             affirmLogoType:(AffirmLogoType)affirmLogoType
                affirmColor:(AffirmColorType)affirmColor
                maxFontSize:(CGFloat)maxFontSize
{
    [AffirmValidationUtils checkNotNil:amount name:@"amount"];
    self.amount = amount.toIntegerCents;
    
    AffirmPromoRequest *request = [[AffirmPromoRequest alloc] initWithPublicKey:[AffirmConfiguration sharedInstance].publicKey
                                                                        promoId:self.promoID
                                                                         amount:self.amount
                                                                        showCTA:self.showCTA
                                                                       pageType:FormatAffirmPageTypeString(self.pageType)];
    [AffirmCheckoutClient send:request handler:^(id<AffirmResponseProtocol> _Nullable response, NSError * _Nullable error) {
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
            attributedString = [self appendLogo:logo
                                         toText:template
                                           font:maxFontSize
                                       logoType:affirmLogoType];
        }
        [self configureWithAttributedText:attributedString response:response error:error];
    }];
}

- (void)configureWithAttributedText:(nullable NSAttributedString *)attributedText response:(nullable id<AffirmResponseProtocol>)response error:(nullable NSError *)error
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
        [[AffirmLogger sharedInstance] logEvent:@"Request Promotional Message Failed"
                                     parameters:@{@"message": error.localizedDescription}];
        if (self.presentingViewController && [self.presentingViewController respondsToSelector:@selector(webViewController:didFailWithError:)]) {
            [self.presentingViewController webViewController:nil
                                            didFailWithError:error];
        }
    }
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
                                         @"promo_external_id": self.promoID,
                                         @"isSDK": @"true",
                                         @"use_promo": @"true",
                                         @"referring_url": AFFIRM_PREQUAL_REFERRING_URL,
                                         } mutableCopy];
        if (self.pageType) {
            params[@"page_type"] = FormatAffirmPageTypeString(self.pageType);
        }

        NSString *url = [NSString stringWithFormat:@"%@/apps/prequal/", [AffirmCheckoutClient host]];
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
