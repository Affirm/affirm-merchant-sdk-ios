//
//  AffirmPromotionalButton.h
//  AffirmSDK
//
//  Created by yijie on 2019/3/11.
//  Copyright © 2019 Affirm, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AffirmPrequalDelegate.h"

typedef NS_ENUM(NSInteger, AffirmLogoType) {
    AffirmLogoTypeText = 1,
    AffirmLogoTypeName = 2,
    AffirmLogoTypeSymbol = 3,
    AffirmLogoTypeSymbolHollow = 4
};

typedef NS_ENUM(NSInteger, AffirmColorType) {
    AffirmColorTypeDefault = 1,
    AffirmColorTypeBlue = 2,
    AffirmColorTypeBlack = 3,
    AffirmColorTypeWhite = 4
};

NS_ASSUME_NONNULL_BEGIN

/**
 An AffirmPromotionalButton displays the contents of an Affirm as low as object which describes the merchant and the item.
 */
@interface AffirmPromotionalButton : UIButton

@property (nonatomic, weak) IBOutlet UIViewController<AffirmPrequalDelegate> *presentingViewController;

@property (nonatomic, copy) IBInspectable NSString *promoID;

@property (nonatomic) IBInspectable BOOL showCTA;

/**
 Constructor that creates an promotinoal button
 
 @param promoID Promo ID to use when getting terms (provided by Affirm)
 @param showCTA A boolean to use when getting terms
 @param presentingViewController view controller that button is displayed on, and the view controller must follow the AffirmPrequalDelegate
 @param frame frame to initialize the button
 @return an initialized AffirmPromotionalButton
 */
- (instancetype)initWithPromoID:(NSString *)promoID
                        showCTA:(BOOL)showCTA
       presentingViewController:(UIViewController<AffirmPrequalDelegate> *)presentingViewController
                          frame:(CGRect)frame
NS_SWIFT_NAME(init(promoID:showCTA:presentingViewController:frame:)) NS_DESIGNATED_INITIALIZER;

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
