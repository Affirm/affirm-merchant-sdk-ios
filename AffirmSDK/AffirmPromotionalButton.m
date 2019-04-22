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

NSString *const AFFIRM_DEFAULT_ALA_TEMPLATE = @"Buy in monthly payments with Affirm";

NSString * FormatLogoString(AffirmLogoType type)
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

NSString * FormatAffirmColorString(AffirmColorType type)
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
                                    NSForegroundColorAttributeName: self.titleLabel.textColor}
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

@interface AffirmPromotionalButton()

@property (nonatomic, strong) NSDecimalNumber *amount;
@property (nonatomic) BOOL showPrequal;
@property (nonatomic) BOOL clickable;

@end

@implementation AffirmPromotionalButton

#pragma mark - Initialize Method

- (instancetype)initWithPromoID:(NSString *)promoID
                        showCTA:(BOOL)showCTA
       presentingViewController:(UIViewController<AffirmPrequalDelegate> *)presentingViewController
                          frame:(CGRect)frame
{
    [AffirmValidationUtils checkNotNil:promoID name:@"promoID"];
    [AffirmValidationUtils checkNotNil:presentingViewController name:@"presentingViewController"];

    if (self = [super initWithFrame:frame]) {
        _promoID = promoID;
        _presentingViewController = presentingViewController;
        _showCTA = showCTA;
        [self configureButton];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self configureButton];
}

- (void)configureButton
{
    self.clickable = NO;
    self.titleLabel.numberOfLines = 0;
    self.titleLabel.adjustsFontSizeToFitWidth = YES;
    [self addTarget:self action:@selector(showALAModal:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)configureWithAmount:(NSDecimalNumber *)amount
             affirmLogoType:(AffirmLogoType)affirmLogoType
                affirmColor:(AffirmColorType)affirmColor
                maxFontSize:(CGFloat)maxFontSize
{
    [AffirmValidationUtils checkNotNil:amount name:@"amount"];
    self.amount = amount.toIntegerCents;
    
    AffirmPromoRequest *request = [[AffirmPromoRequest alloc] initWithPublicKey:[AffirmConfiguration sharedInstance].publicKey promoId:self.promoID amount:self.amount showCTA:self.showCTA];
    [AffirmCheckoutClient send:request handler:^(id<AffirmResponseProtocol>  _Nullable response, NSError * _Nonnull error) {
        BOOL success = NO;
        if (response && [response isKindOfClass:[AffirmPromoResponse class]]) {
            success = YES;
            NSString *template = AFFIRM_DEFAULT_ALA_TEMPLATE;
            AffirmPromoResponse *promoResponse = (AffirmPromoResponse *)response;
            if (promoResponse.ala != nil) {
                template = promoResponse.ala;
            }
            self.showPrequal = promoResponse.showPrequal;
            UIImage *logo = nil;
            if (affirmLogoType != AffirmLogoTypeText) {
                logo = [AffirmPromotionalButton getAffirmDisplayForLogoType:affirmLogoType colorType:affirmColor];
            }
            [self setAttributedTitle:[self appendLogo:logo
                                               toText:template
                                                 font:maxFontSize
                                             logoType:affirmLogoType]
                            forState:UIControlStateNormal];
        } else if (response && [response isKindOfClass:[AffirmErrorResponse class]]) {
            [self setAttributedTitle:nil
                            forState:UIControlStateNormal];
            AffirmErrorResponse *errorResponse = (AffirmErrorResponse *)response;
            [[AffirmLogger sharedInstance] logEvent:@"Request Promotional Message Failed"
                                         parameters:@{@"message": errorResponse.message, @"statusCode": errorResponse.statusCode}];
            if (self.presentingViewController && [self.presentingViewController respondsToSelector:@selector(webViewController:didFailWithError:)]) {
                [self.presentingViewController webViewController:nil
                                                didFailWithError:[errorResponse.dictionary convertToNSErrorWithCode:errorResponse.statusCode]];
            }
        } else {
            [self setAttributedTitle:nil
                            forState:UIControlStateNormal];
            [[AffirmLogger sharedInstance] logEvent:@"Request Promotional Message Failed"
                                         parameters:@{@"message": error.localizedDescription}];
            if (self.presentingViewController && [self.presentingViewController respondsToSelector:@selector(webViewController:didFailWithError:)]) {
                [self.presentingViewController webViewController:nil
                                                didFailWithError:error];
            }
        }
        self.clickable = success;
    }];
}

#pragma mark - Event Response

- (void)showALAModal:(UIButton *)sender
{
    NSParameterAssert(self.amount != nil);
    if (!self.clickable) {
        return;
    }
    
    if (self.showPrequal) {
        NSDictionary *params = @{
                                 @"public_api_key": [AffirmConfiguration sharedInstance].publicKey,
                                 @"unit_price": self.amount,
                                 @"promo_external_id": self.promoID,
                                 @"isSDK": @"true",
                                 @"use_promo": @"true",
                                 @"referring_url": AFFIRM_PREQUAL_REFERRING_URL
                                 };

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
