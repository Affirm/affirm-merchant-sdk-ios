//
//  AffirmDataHandler.h
//  AffirmSDK
//
//  Created by Victor Zhu on 2019/9/9.
//  Copyright © 2019 Affirm, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AffirmPromotionalButton.h"

@class AffirmItem;

NS_ASSUME_NONNULL_BEGIN

@interface AffirmDataHandler : NSObject

/**
 Get the contents of an Affirm as low as object which describes the merchant and the item.
 
 @param promoID Promo ID to use when getting terms (provided by Affirm)
 @param amount Amount of the transaction
 @param showCTA A boolean to use when getting terms
 @param pageType type of Affirm page to display
 @param logoType type of Affirm logo to display (text, name, symbol)
 @param colorType color of Affirm to display (blue, black, white) - only applies to logo and symbol affirmType values
 @param font the font of button title, maxFontSize will be set as same value
 @param textColor the color of button title
 @param delegate custom implementation of AffirmPrequalDelegate
 @param completionHandler the completion handler
 */
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
NS_SWIFT_NAME(getPromoMessage(promoID:amount:showCTA:pageType:logoType:colorType:font:textColor:presentingViewController:completionHandler:));

/**
 Get the contents of an Affirm as low as object which describes the merchant and the item.
 
 @param promoID Promo ID to use when getting terms (provided by Affirm)
 @param amount Amount of the transaction
 @param showCTA A boolean to use when getting terms
 @param pageType type of Affirm page to display
 @param logoType type of Affirm logo to display (text, name, symbol)
 @param colorType color of Affirm to display (blue, black, white) - only applies to logo and symbol affirmType values
 @param font the font of button title, maxFontSize will be set as same value
 @param textColor the color of button title
 @param delegate custom implementation of AffirmPrequalDelegate
 @param withNavigation whether to return UINavigationController including promo modal
 @param completionHandler the completion handler
 */
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
NS_SWIFT_NAME(getPromoMessage(promoID:amount:showCTA:pageType:logoType:colorType:font:textColor:presentingViewController:withNavigation:completionHandler:));

/**
 Get the contents of an Affirm as low as object which describes the merchant and the item.
 
 @param promoID Promo ID to use when getting terms (provided by Affirm)
 @param amount Amount of the transaction
 @param showCTA A boolean to use when getting terms
 @param pageType type of Affirm page to display
 @param logoType type of Affirm logo to display (text, name, symbol)
 @param colorType color of Affirm to display (blue, black, white) - only applies to logo and symbol affirmType values
 @param font the font of button title, maxFontSize will be set as same value
 @param textColor the color of button title
 @param delegate custom implementation of AffirmPrequalDelegate
 @param withNavigation whether to return UINavigationController including promo modal
 @param withHtmlValue whether to return html raw string
 @param completionHandler the completion handler
 */
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
NS_SWIFT_NAME(getPromoMessage(promoID:amount:showCTA:pageType:logoType:colorType:font:textColor:presentingViewController:withNavigation:withHtmlValue:completionHandler:));

/**
 Get the contents of an Affirm as low as object which describes the merchant and the item.

 @param promoID Promo ID to use when getting terms (provided by Affirm)
 @param amount Amount of the transaction
 @param items Items data
 @param showCTA A boolean to use when getting terms
 @param pageType type of Affirm page to display
 @param logoType type of Affirm logo to display (text, name, symbol)
 @param colorType color of Affirm to display (blue, black, white) - only applies to logo and symbol affirmType values
 @param font the font of button title, maxFontSize will be set as same value
 @param textColor the color of button title
 @param delegate custom implementation of AffirmPrequalDelegate
 @param withNavigation whether to return UINavigationController including promo modal
 @param withHtmlValue whether to return html raw string
 @param completionHandler the completion handler
 */
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
NS_SWIFT_NAME(getPromoMessage(promoID:amount:items:showCTA:pageType:logoType:colorType:font:textColor:presentingViewController:withNavigation:withHtmlValue:completionHandler:));

@end

NS_ASSUME_NONNULL_END
