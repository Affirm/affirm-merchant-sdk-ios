//
//  AffirmPromotionalButton.h
//  AffirmSDK
//
//  Created by yijie on 2019/3/11.
//  Copyright © 2019 Affirm, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AffirmPrequalDelegate.h"

typedef NS_ENUM(NSInteger, AffirmPageType) {
    AffirmPageTypeNone,
    AffirmPageTypeBanner,
    AffirmPageTypeCart,
    AffirmPageTypeCategory,
    AffirmPageTypeHomepage,
    AffirmPageTypeLanding,
    AffirmPageTypePayment,
    AffirmPageTypeProduct,
    AffirmPageTypeSearch,
};

typedef NS_ENUM(NSInteger, AffirmLogoType) {
    AffirmLogoTypeText,
    AffirmLogoTypeName,
    AffirmLogoTypeSymbol,
    AffirmLogoTypeSymbolHollow
};

typedef NS_ENUM(NSInteger, AffirmColorType) {
    AffirmColorTypeDefault,
    AffirmColorTypeBlue,
    AffirmColorTypeBlack,
    AffirmColorTypeWhite
};

NS_ASSUME_NONNULL_BEGIN

/**
 An AffirmPromotionalButton displays the contents of an Affirm as low as object which describes the merchant and the item.
 */
@interface AffirmPromotionalButton : UIView

/**
 The view controller which handles prequal events.
 */
@property (nonatomic, weak) IBOutlet UIViewController<AffirmPrequalDelegate> *presentingViewController;

/**
 Promo id. Optional
 */
@property (nonatomic, copy, nullable) IBInspectable NSString *promoID;

/**
 A boolean to use when getting terms.
 */
@property (nonatomic) IBInspectable BOOL showCTA;

/**
 Page type.
 */
@property (nonatomic) IBInspectable AffirmPageType pageType;

/**
 Constructor that creates an promotinoal button
 
 @param promoID Promo ID to use when getting terms (provided by Affirm)
 @param showCTA A boolean to use when getting terms
 @param presentingViewController view controller that button is displayed on, and the view controller must follow the AffirmPrequalDelegate
 @param frame frame to initialize the button
 @return an initialized AffirmPromotionalButton
 */
- (instancetype)initWithPromoID:(nullable NSString *)promoID
                        showCTA:(BOOL)showCTA
       presentingViewController:(UIViewController<AffirmPrequalDelegate> *)presentingViewController
                          frame:(CGRect)frame
NS_SWIFT_NAME(init(promoID:showCTA:presentingViewController:frame:));

/**
 Constructor that creates an promotinoal button

 @param showCTA A boolean to use when getting terms
 @param pageType type of Affirm page to display
 @param presentingViewController view controller that button is displayed on, and the view controller must follow the AffirmPrequalDelegate
 @param frame frame to initialize the button
 @return an initialized AffirmPromotionalButton
 */
- (instancetype)initWithShowCTA:(BOOL)showCTA
                       pageType:(AffirmPageType)pageType
       presentingViewController:(UIViewController<AffirmPrequalDelegate> *)presentingViewController
                          frame:(CGRect)frame
NS_SWIFT_NAME(init(showCTA:pageType:presentingViewController:frame:));

/**
 Constructor that creates an promotinoal button

 @param promoID Promo ID to use when getting terms (provided by Affirm)
 @param showCTA A boolean to use when getting terms
 @param pageType type of Affirm page to display
 @param presentingViewController view controller that button is displayed on, and the view controller must follow the AffirmPrequalDelegate
 @param frame frame to initialize the button
 @return an initialized AffirmPromotionalButton
 */
- (instancetype)initWithPromoID:(nullable NSString *)promoID
                        showCTA:(BOOL)showCTA
                       pageType:(AffirmPageType)pageType
       presentingViewController:(UIViewController<AffirmPrequalDelegate> *)presentingViewController
                          frame:(CGRect)frame
NS_SWIFT_NAME(init(promoID:showCTA:pageType:presentingViewController:frame:));

/**
 Configures an AffirmPromotionalButton based on the HTML tags

 @param amount Amount of the transaction
 */
- (void)configureByHtmlStylingWithAmount:(NSDecimalNumber *)amount
NS_SWIFT_NAME(configureByHtmlStyling(amount:));

/**
 Configures an AffirmPromotionalButton based on the HTML tags

 @param amount Amount of the transaction
 @param affirmLogoType type of Affirm logo to display (text, name, symbol)
 @param affirmColor color of Affirm to display (blue, black, white) - only applies to logo and symbol affirmType values
 */
- (void)configureByHtmlStylingWithAmount:(NSDecimalNumber *)amount
                          affirmLogoType:(AffirmLogoType)affirmLogoType
                             affirmColor:(AffirmColorType)affirmColor
NS_SWIFT_NAME(configureByHtmlStyling(amount:affirmLogoType:affirmColor:));

/**
 Configures an AffirmPromotionalButton based on the HTML tags

 @param amount Amount of the transaction
 @param affirmLogoType type of Affirm logo to display (text, name, symbol)
 @param affirmColor color of Affirm to display (blue, black, white) - only applies to logo and symbol affirmType values
 @param remoteCssURL Use a custom css file
 */
- (void)configureByHtmlStylingWithAmount:(NSDecimalNumber *)amount
                          affirmLogoType:(AffirmLogoType)affirmLogoType
                             affirmColor:(AffirmColorType)affirmColor
                            remoteCssURL:(nullable NSURL *)remoteCssURL
NS_SWIFT_NAME(configureByHtmlStyling(amount:affirmLogoType:affirmColor:remoteCssURL:));

/**
 Configures an AffirmPromotionalButton based on the HTML tags

 @param amount Amount of the transaction
 @param affirmLogoType type of Affirm logo to display (text, name, symbol)
 @param affirmColor color of Affirm to display (blue, black, white) - only applies to logo and symbol affirmType values
 @param remoteFontURL Use a custom font file
 @param remoteCssURL Use a custom css file
 */
- (void)configureByHtmlStylingWithAmount:(NSDecimalNumber *)amount
                          affirmLogoType:(AffirmLogoType)affirmLogoType
                             affirmColor:(AffirmColorType)affirmColor
                           remoteFontURL:(nullable NSURL *)remoteFontURL
                            remoteCssURL:(nullable NSURL *)remoteCssURL
NS_SWIFT_NAME(configureByHtmlStyling(amount:affirmLogoType:affirmColor:remoteFontURL:remoteCssURL:));

/**
 Configures an AffirmPromotionalButton with the appropriate details
 
 @param amount Amount of the transaction
 @param affirmLogoType type of Affirm logo to display (text, name, symbol)
 @param affirmColor color of Affirm to display (blue, black, white) - only applies to logo and symbol affirmType values
 @param maxFontSize max font size of the promotional text - the button autoshrinks text to fit its dimensions and the final font size will never exceed this max font size
 */
- (void)configureWithAmount:(NSDecimalNumber *)amount
             affirmLogoType:(AffirmLogoType)affirmLogoType
                affirmColor:(AffirmColorType)affirmColor
                maxFontSize:(CGFloat)maxFontSize
NS_SWIFT_NAME(configure(amount:affirmLogoType:affirmColor:maxFontSize:));

- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
