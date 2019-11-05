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
          presentingViewController:(id<AffirmPrequalDelegate>)presentingViewController
                 completionHandler:(void (^)(NSAttributedString * _Nullable , UIViewController * _Nullable, NSError * _Nullable))completionHandler
{
    [AffirmValidationUtils checkNotNil:amount name:@"amount"];
    NSDecimalNumber *decimal = amount.toIntegerCents;

    AffirmPromoRequest *request = [[AffirmPromoRequest alloc] initWithPublicKey:[AffirmConfiguration sharedInstance].publicKey
                                                                        promoId:promoID
                                                                         amount:decimal
                                                                        showCTA:showCTA
                                                                       pageType:FormatAffirmPageTypeString(pageType)
                                                                       logoType:nil
                                                                      logoColor:FormatAffirmColorString(colorType)];
    [AffirmCheckoutClient send:request handler:^(id<AffirmResponseProtocol> _Nullable response, NSError * _Nullable error) {
        NSAttributedString *attributedString = nil;
        UIViewController *viewController = nil;
        if (response && [response isKindOfClass:[AffirmPromoResponse class]]) {
            NSString *template = nil;
            AffirmPromoResponse *promoResponse = (AffirmPromoResponse *)response;
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
                                                 @"unit_price": decimal,
                                                 @"promo_external_id": promoID,
                                                 @"isSDK": @"true",
                                                 @"use_promo": @"true",
                                                 @"referring_url": AFFIRM_PREQUAL_REFERRING_URL,
                                                 } mutableCopy];
                if (pageType) {
                    params[@"page_type"] = FormatAffirmPageTypeString(pageType);
                }

                NSString *url = [NSString stringWithFormat:@"%@/apps/prequal/", [AffirmCheckoutClient host]];
                NSURL *requestURL = [NSURL URLWithString:[NSString stringWithFormat:@"?%@", [params queryURLEncoding]]
                                           relativeToURL:[NSURL URLWithString:url]];
                viewController = [[AffirmPrequalModalViewController alloc] initWithURL:requestURL delegate:presentingViewController];
            } else {
                viewController = [[AffirmPromoModalViewController alloc] initWithPromoId:promoID
                                                                                  amount:decimal
                                                                                delegate:presentingViewController];
            }
        }
        completionHandler(attributedString, viewController, error);
    }];
}

@end
