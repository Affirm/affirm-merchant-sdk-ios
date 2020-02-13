//
//  AffirmCreditCard.m
//  AffirmSDK
//
//  Created by Paul on 3/18/19.
//  Copyright © 2019 Affirm, Inc. All rights reserved.
//

#import "AffirmCreditCard.h"
#import "AffirmUtils.h"

@implementation AffirmCreditCardBillAddress

- (instancetype)initWithDict:(NSDictionary *)dict
{
    if (self = [super init]) {
        _city = dict[@"city"];
        _state = dict[@"state"];
        _zipCode = dict[@"zipcode"];
        _line1 = dict[@"line1"];
        _line2 = dict[@"line2"];
    }
    return self;
}

@end

@implementation AffirmCreditCard

+ (AffirmCreditCard *)creditCardWithDict:(NSDictionary *)dict
{
    return [[self alloc] initWithDict:dict];
}

- (instancetype)initWithDict:(NSDictionary *)dict
{
    [AffirmValidationUtils checkNotNil:dict[@"checkout_token"] name:@"checkout_token"];
    [AffirmValidationUtils checkNotNil:dict[@"callback_id"] name:@"callback_id"];
    [AffirmValidationUtils checkNotNil:dict[@"id"] name:@"creditCard_id"];
    
    if (self = [super init]) {
        if (dict[@"billing_address"] != nil && [dict[@"billing_address"] isKindOfClass:[NSDictionary class]]) {
            _billingAddress = [[AffirmCreditCardBillAddress alloc] initWithDict:dict[@"billing_address"]];
        }
        _checkoutToken = dict[@"checkout_token"];
        _created = dict[@"created"];
        _creditCardId = dict[@"id"];
        _callbackId = dict[@"callback_id"];
        _cvv = dict[@"cvv"];
        _number = dict[@"number"];
        _cardholderName = dict[@"cardholder_name"];
        _expiration = dict[@"expiration"];
    }
    return self;
}

@end
