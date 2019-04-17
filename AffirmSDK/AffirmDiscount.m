//
//  AffirmDiscount.m
//  AffirmSDK
//
//  Created by Paul on 3/14/19.
//  Copyright © 2019 Affirm, Inc. All rights reserved.
//

#import "AffirmDiscount.h"
#import "AffirmUtils.h"
#import "AffirmJSONifiable.h"

@implementation AffirmDiscount

+ (AffirmDiscount *)discountWithName:(NSString *)name
                              amount:(NSDecimalNumber *)amount
{
    return [[self alloc] initWithName:name amount:amount];
}

- (instancetype)initWithName:(NSString *)name
                      amount:(NSDecimalNumber *)amount
{
    [AffirmValidationUtils checkNotNil:name name:@"name"];
    [AffirmValidationUtils checkNotNil:amount name:@"amount"];
    [AffirmValidationUtils checkNotNegative:amount name:@"amount"];
    
    if (self = [super init]) {
        _name = [name copy];
        _amount = [amount copy];
    }
    return self;
}

- (NSDictionary *)toJSONDictionary
{
    return @{
             @"discount_display_name": self.name,
             @"discount_amount": self.amount.toIntegerCents
             };
}

- (id)copyWithZone:(NSZone *)zone
{
    return [[self class] discountWithName:self.name amount:self.amount];
}

@end
