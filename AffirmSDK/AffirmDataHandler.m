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
                 completionHandler:(AffirmDataHandlerCompletionHandler)completionHandler
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
                 completionHandler:(AffirmDataHandlerCompletionHandler)completionHandler
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
                 completionHandler:(AffirmDataHandlerCompletionWithHtmlHandler)completionHandler
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
                 completionHandler:(AffirmDataHandlerCompletionWithHtmlHandler)completionHandler
{
    [self getPromoMessageWithPromoID:promoID
                              amount:amount
                               items:items
                             showCTA:showCTA
                            pageType:pageType
                            logoType:logoType
                           colorType:colorType
                                font:font
                           textColor:textColor
            presentingViewController:delegate
                      withNavigation:withNavigation
                       withHtmlValue:withHtmlValue
                   withAccessibility:NO
                   completionHandler:^(NSAttributedString *attributedString, NSString *html, NSString *accessibilityLabel, UIViewController *viewController, NSError *error) {
        completionHandler(attributedString, html, viewController, error);
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
                 withAccessibility:(BOOL)withAccessibility
                 completionHandler:(AffirmDataHandlerCompletionWithAccessibilityHandler)completionHandler;
{
    [AffirmValidationUtils checkNotNil:amount name:@"amount"];
    
    AffirmColorType logoColor = colorType;
    // Using default type when logoColor == AffirmColorTypeBlueBlack
    if (logoColor == AffirmColorTypeBlueBlack) {
        logoColor = AffirmColorTypeDefault;
    }
    
    AffirmPromoRequest *request = [[AffirmPromoRequest alloc] initWithPublicKey:[AffirmConfiguration sharedInstance].publicKey
                                                                        promoId:promoID
                                                                         amount:amount
                                                                        showCTA:showCTA
                                                                       pageType:FormatAffirmPageTypeString(pageType)
                                                                       logoType:nil
                                                                      logoColor:FormatAffirmColorString(logoColor)
                                                                          items:items];
    [AffirmPromoClient send:request handler:^(AffirmResponse * _Nullable response, NSError * _Nullable error) {
        NSAttributedString *attributedString = nil;
        NSString *htmlValue = nil;
        NSString *accessibilityLabel = nil;
        UIViewController *viewController = nil;
        if (response && [response isKindOfClass:[AffirmPromoResponse class]]) {
            AffirmPromoResponse *promoResponse = (AffirmPromoResponse *)response;
            htmlValue = withHtmlValue ? promoResponse.htmlAla : nil;
            
            NSString *template = nil;
            if (promoResponse.ala != nil && promoResponse.ala.length > 0) {
                template = promoResponse.ala;
                accessibilityLabel = withAccessibility ? [promoResponse.ala stringByReplacingOccurrencesOfString:@"{Affirm}" withString:@"Affirm"] : nil;
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
                    @"unit_price": [amount toIntegerCents],
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
                                                                                  amount:amount
                                                                                pageType:pageType
                                                                                delegate:delegate];
            }
        }
        NSError *_error;
        if ([response isKindOfClass:[AffirmErrorResponse class]]) {
            AffirmErrorResponse *errorResponse = (AffirmErrorResponse *)response;
            _error = [errorResponse.dictionary convertToNSErrorWithCode:errorResponse.statusCode];
        }
        if (viewController && withNavigation) {
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
            completionHandler(attributedString, htmlValue, accessibilityLabel, navigationController, error ?: _error);
        } else {
            completionHandler(attributedString, htmlValue, accessibilityLabel, viewController, error ?: _error);
        }
    }];
}

@end
