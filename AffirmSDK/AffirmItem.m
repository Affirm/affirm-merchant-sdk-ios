//
//  AffirmItem.m
//  AffirmSDK
//
//  Created by Paul on 3/14/19.
//  Copyright © 2019 Affirm, Inc. All rights reserved.
//

#import "AffirmItem.h"
#import "AffirmUtils.h"

@implementation AffirmCategory

- (instancetype)initWithName:(NSString *)name
               subCategories:(NSArray<NSString *> *)subCategories
{
    [AffirmValidationUtils checkNotNil:subCategories name:@"subCategories"];
    
    if (self = [super init]) {
        _name = [name copy];
        _subCategories = [subCategories copy];
    }
    return self;
}

+ (AffirmCategory *)categoryWithName:(NSString *)name
                       subCategories:(NSArray<NSString *> *)subCategories
{
    return [[self alloc] initWithName:name subCategories:subCategories];
}

- (id)copyWithZone:(NSZone *)zone
{
    return [[self class] categoryWithName:self.name
                            subCategories:self.subCategories];
}

@end

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

- (instancetype)initWithName:(NSString *)name
                         SKU:(NSString *)SKU
                   unitPrice:(NSDecimalNumber *)unitPrice
                    quantity:(NSInteger)quantity
                         URL:(NSURL *)URL
                  categories:(nullable NSArray<AffirmCategory *> *)categories
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
        _categories = [categories copy];
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

+ (AffirmItem *)itemWithName:(NSString *)name
                         SKU:(NSString *)SKU
                   unitPrice:(NSDecimalNumber *)unitPrice
                    quantity:(NSInteger)quantity
                         URL:(NSURL *)URL
                  categories:(nullable NSArray<AffirmCategory *> *)categories
{
    return [[self alloc] initWithName:name
                                  SKU:SKU
                            unitPrice:unitPrice
                             quantity:quantity
                                  URL:URL
                           categories:categories];
}

- (NSDictionary *)toJSONDictionary
{
    NSMutableDictionary *json = [@{
        @"display_name": self.name,
        @"sku": self.SKU,
        @"unit_price": self.unitPrice.toIntegerCents,
        @"qty": @(self.quantity)
    } mutableCopy];
    if (![self.URL isFileURL] && ([self.URL.scheme isEqualToString:@"http"] || [self.URL.scheme isEqualToString:@"https"] || [self.URL.scheme length] == 0)) {
        json[@"item_url"] = [self.URL absoluteString];
    }
    if (self.categories) {
        NSMutableArray *allSubcategories = [NSMutableArray array];
        for (AffirmCategory *category in self.categories) {
            [allSubcategories addObject:category.subCategories];
        }
        json[@"categories"] = allSubcategories;
    }
    return json;
}

- (id)copyWithZone:(NSZone *)zone
{
    return [[self class] itemWithName:self.name
                                  SKU:self.SKU
                            unitPrice:self.unitPrice
                             quantity:self.quantity
                                  URL:self.URL
                           categories:self.categories];
}

@end
