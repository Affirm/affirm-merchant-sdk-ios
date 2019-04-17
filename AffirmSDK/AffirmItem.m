//
//  AffirmItem.m
//  AffirmSDK
//
//  Created by Paul on 3/14/19.
//  Copyright © 2019 Affirm, Inc. All rights reserved.
//

#import "AffirmItem.h"
#import "AffirmUtils.h"

@implementation AffirmItem

- (instancetype)initWithName:(NSString *)name
                         SKU:(NSString *)SKU
                   unitPrice:(NSDecimalNumber *)unitPrice
                    quantity:(NSInteger)quantity
                         URL:(NSURL *)URL
{
    [AffirmValidationUtils checkNotNil:name name:@"name"];
    [AffirmValidationUtils checkNotNil:SKU name:@"SKU"];
    [AffirmValidationUtils checkNotNil:unitPrice name:@"unitPrice"];
    [AffirmValidationUtils checkNotNegative:unitPrice name:@"unitPrice"];
    [AffirmValidationUtils checkNotNegative:[NSDecimalNumber decimalNumberWithDecimal:[[NSNumber numberWithInteger:quantity] decimalValue]] name:@"quantity"];
    [AffirmValidationUtils checkNotNil:URL name:@"URL"];
    
    if (self = [super init]) {
        _name = [name copy];
        _SKU = [SKU copy];
        _unitPrice = [unitPrice copy];
        _quantity = quantity;
        _URL = [URL copy];
    }
    return self;
}

+ (AffirmItem *)itemWithName:(NSString *)name
                         SKU:(NSString *)SKU
                   unitPrice:(NSDecimalNumber *)unitPrice
                    quantity:(NSInteger)quantity
                         URL:(NSURL *)URL
{
    return [[self alloc] initWithName:name
                                  SKU:SKU
                            unitPrice:unitPrice
                             quantity:quantity
                                  URL:URL];
}

- (NSDictionary *)toJSONDictionary
{
    return @{
             @"display_name": self.name,
             @"sku": self.SKU,
             @"unit_price": self.unitPrice.toIntegerCents,
             @"qty": @(self.quantity),
             @"item_url": [self.URL absoluteString],
             };
}

- (id)copyWithZone:(NSZone *)zone
{
    return [[self class] itemWithName:self.name
                                  SKU:self.SKU
                            unitPrice:self.unitPrice
                             quantity:self.quantity
                                  URL:self.URL];
}

@end
