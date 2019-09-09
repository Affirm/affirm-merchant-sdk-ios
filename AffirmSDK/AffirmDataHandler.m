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

@implementation AffirmDataHandler

+ (void)getPromoMessageWithPromoID:(NSString *)promoID
                            amount:(NSDecimalNumber *)amount
                           showCTA:(BOOL)showCTA
                          pageType:(AffirmPageType)pageType
                          logoType:(AffirmLogoType)logoType
                         colorType:(AffirmColorType)colorType
                              font:(UIFont *)font
                         textColor:(UIColor *)textColor
                 completionHandler:(void (^)(NSAttributedString * _Nullable , NSError * _Nullable ))completionHandler
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
        }
        completionHandler(attributedString, error);
    }];
}

@end
