//
//  AffirmCardInfoViewController.h
//  AffirmSDK
//
//  Created by Victor Zhu on 2020/9/22.
//  Copyright © 2020 Affirm, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AffirmCreditCard;

NS_ASSUME_NONNULL_BEGIN

@interface AffirmCardInfoViewController : UIViewController

@property (nonatomic, strong) AffirmCreditCard *creditCard;
@property (nonatomic, strong) NSDecimalNumber *amount;

@end

NS_ASSUME_NONNULL_END
