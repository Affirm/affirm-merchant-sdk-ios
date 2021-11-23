//
//  AffirmDataHandler.m
//  AffirmSDK
//
//  Created by Victor Zhu on 2019/9/9.
//  Copyright © 2019 Affirm, Inc. All rights reserved.
//

#import "AffirmDataHandler.h"
#import "AffirmUtils.h"
#import "AffirmRequest.h"
#import "AffirmConfiguration.h"
#import "AffirmPrequalModalViewController.h"
#import "AffirmPromoModalViewController.h"

@implementation AffirmDataHandler

+ (void)getPromoMessageWithPromoID:(nullable NSString *)promoID
                            amount:(NSDecimalNumber *)amount
                           showCTA:(BOOL)showCTA
                          pageType:(AffirmPageType)pageType
                          logoType:(AffirmLogoType)logoType
                         colorType:(AffirmColorType)colorType
                              font:(UIFont *)font
                         textColor:(UIColor *)textColor
                          delegate:(id<AffirmPrequalDelegate>)delegate
                 completionHandler:(void (^)(NSAttributedString * _Nullable , UIViewController * _Nullable, NSError * _Nullable))completionHandler
{
    [self getPromoMessageWithPromoID:promoID
                              amount:amount
                             showCTA:showCTA
                            pageType:pageType
                            logoType:logoType
                           colorType:colorType
                                font:font
                           textColor:textColor
            presentingViewController:delegate
                      withNavigation:NO
                   completionHandler:completionHandler];
}

+ (void)getPromoMessageWithPromoID:(nullable NSString *)promoID
                            amount:(NSDecimalNumber *)amount
                           showCTA:(BOOL)showCTA
                          pageType:(AffirmPageType)pageType
                          logoType:(AffirmLogoType)logoType
                         colorType:(AffirmColorType)colorType
                              font:(UIFont *)font
                         textColor:(UIColor *)textColor
          presentingViewController:(id<AffirmPrequalDelegate>)delegate
                    withNavigation:(BOOL)withNavigation
                 completionHandler:(void (^)(NSAttributedString * _Nullable , UIViewController * _Nullable, NSError * _Nullable))completionHandler
{
    [self getPromoMessageWithPromoID:promoID
                              amount:amount
                             showCTA:showCTA
                            pageType:pageType
                            logoType:logoType
                           colorType:colorType
                                font:font
                           textColor:textColor
            presentingViewController:delegate
                      withNavigation:withNavigation
                       withHtmlValue:NO
                   completionHandler:^(NSAttributedString *attributedString, NSString *htmlValue, UIViewController *viewController, NSError *error) {
        completionHandler(attributedString, viewController, error);
    }];
}

+ (void)getPromoMessageWithPromoID:(nullable NSString *)promoID
                            amount:(NSDecimalNumber *)amount
                           showCTA:(BOOL)showCTA
                          pageType:(AffirmPageType)pageType
                          logoType:(AffirmLogoType)logoType
                         colorType:(AffirmColorType)colorType
                              font:(UIFont *)font
                         textColor:(UIColor *)textColor
          presentingViewController:(id<AffirmPrequalDelegate>)delegate
                    withNavigation:(BOOL)withNavigation
                     withHtmlValue:(BOOL)withHtmlValue
                 completionHandler:(void (^)(NSAttributedString * _Nullable, NSString * _Nullable, UIViewController * _Nullable, NSError * _Nullable))completionHandler
{
    [self getPromoMessageWithPromoID:promoID
                              amount:amount
                               items:nil
                             showCTA:showCTA
                            pageType:pageType
                            logoType:logoType
                           colorType:colorType
                                font:font
                           textColor:textColor
            presentingViewController:delegate
                      withNavigation:withNavigation
                       withHtmlValue:NO
                   completionHandler:^(NSAttributedString *attributedString, NSString *htmlValue, UIViewController *viewController, NSError *error) {
        completionHandler(attributedString, htmlValue, viewController, error);
    }];
}

+ (void)getPromoMessageWithPromoID:(nullable NSString *)promoID
                            amount:(NSDecimalNumber *)amount
                             items:(nullable NSArray <AffirmItem *>*)items
                           showCTA:(BOOL)showCTA
                          pageType:(AffirmPageType)pageType
                          logoType:(AffirmLogoType)logoType
                         colorType:(AffirmColorType)colorType
                              font:(UIFont *)font
                         textColor:(UIColor *)textColor
          presentingViewController:(id<AffirmPrequalDelegate>)delegate
                    withNavigation:(BOOL)withNavigation
                     withHtmlValue:(BOOL)withHtmlValue
                 completionHandler:(void (^)(NSAttributedString * _Nullable, NSString * _Nullable, UIViewController * _Nullable, NSError * _Nullable))completionHandler
{
    [AffirmValidationUtils checkNotNil:amount name:@"amount"];
    NSDecimalNumber *decimal = amount.toIntegerCents;
    
    if (amount.doubleValue > [NSDecimalNumber decimalNumberWithString:AFFIRM_MAX_PROMO_AMOUNT].doubleValue) {
        completionHandler(nil, nil, nil, nil);
        return;
    }

    AffirmColorType logoColor = colorType;
    // Using default type when logoColor == AffirmColorTypeBlueBlack
    if (logoColor == AffirmColorTypeBlueBlack) {
        logoColor = AffirmColorTypeDefault;
    }

    AffirmPromoRequest *request = [[AffirmPromoRequest alloc] initWithPublicKey:[AffirmConfiguration sharedInstance].publicKey
                                                                        promoId:promoID
                                                                         amount:decimal
                                                                        showCTA:showCTA
                                                                       pageType:FormatAffirmPageTypeString(pageType)
                                                                       logoType:nil
                                                                      logoColor:FormatAffirmColorString(logoColor)
                                                                          items:items];
    [AffirmPromoClient send:request handler:^(AffirmResponse * _Nullable response, NSError * _Nullable error) {
        NSAttributedString *attributedString = nil;
        NSString *htmlValue = nil;
        UIViewController *viewController = nil;
        if (response && [response isKindOfClass:[AffirmPromoResponse class]]) {
            AffirmPromoResponse *promoResponse = (AffirmPromoResponse *)response;
            htmlValue = withHtmlValue ? promoResponse.htmlAla : nil;

            NSString *template = nil;
            if (promoResponse.ala != nil && promoResponse.ala.length > 0) {
                template = promoResponse.ala;
            }
            if (template) {
                UIImage *logo = nil;
                if (logoType != AffirmLogoTypeText) {
                    logo = [AffirmPromotionalButton getAffirmDisplayForLogoType:logoType colorType:colorType];
                }
                attributedString = [AffirmPromotionalButton appendLogo:logo toText:template font:font textColor:textColor logoType:logoType];
            }

            if (promoResponse.showPrequal) {
                NSMutableDictionary *params = [@{
                    @"public_api_key": [AffirmConfiguration sharedInstance].publicKey,
                    @"unit_price": [decimal stringValue],
                    @"use_promo": @"true",
                    @"referring_url": AFFIRM_PREQUAL_REFERRING_URL,
                } mutableCopy];
                if (promoID) {
                    params[@"promo_external_id"] = promoID;
                }
                if (pageType) {
                    params[@"page_type"] = FormatAffirmPageTypeString(pageType);
                }

                NSString *url = [NSString stringWithFormat:@"%@/apps/prequal/", [AffirmPromoClient host]];
                NSURL *requestURL = [NSURL URLWithString:[NSString stringWithFormat:@"?%@", [params queryURLEncoding]]
                                           relativeToURL:[NSURL URLWithString:url]];
                viewController = [[AffirmPrequalModalViewController alloc] initWithURL:requestURL delegate:delegate];
            } else {
                viewController = [[AffirmPromoModalViewController alloc] initWithPromoId:promoID
                                                                                  amount:decimal
                                                                                pageType:pageType
                                                                                delegate:delegate];
            }
        }
        if (viewController && withNavigation) {
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
            completionHandler(attributedString, htmlValue, navigationController, error);
        } else {
            completionHandler(attributedString, htmlValue, viewController, error);
        }
    }];
}

@end
