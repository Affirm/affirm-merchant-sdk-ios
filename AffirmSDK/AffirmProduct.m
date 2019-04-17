//
//  AffirmProduct.m
//  AffirmSDK
//
//  Created by Victor Zhu on 2019/4/2.
//  Copyright © 2019 Affirm, Inc. All rights reserved.
//

#import "AffirmProduct.h"
#import "AffirmUtils.h"

@implementation AffirmProduct

- (instancetype)initWithBrand:(nullable NSString *)brand
                     category:(nullable NSString *)category
                       coupon:(nullable NSString *)coupon
                         name:(nullable NSString *)name
                        price:(nullable NSDecimalNumber *)price
                    productId:(NSString *)productId
                     quantity:(NSInteger)quantity
                      variant:(nullable NSString *)variant
                     currency:(nullable NSString *)currency
{
    [AffirmValidationUtils checkNotNil:productId name:@"productId"];

    if (self = [super init]) {
        _brand = [brand copy];
        _category = [category copy];
        _coupon = [coupon copy];
        _name = [name copy];
        _price = [price copy];
        _productId = [productId copy];
        _quantity = quantity;
        _variant = [variant copy];
        _currency = [currency copy];
    }
    return self;
}

+ (AffirmProduct *)productWithBrand:(nullable NSString *)brand
                           category:(nullable NSString *)category
                             coupon:(nullable NSString *)coupon
                               name:(nullable NSString *)name
                              price:(nullable NSDecimalNumber *)price
                          productId:(NSString *)productId
                           quantity:(NSInteger)quantity
                            variant:(nullable NSString *)variant
                           currency:(nullable NSString *)currency
{
    return [[self alloc] initWithBrand:brand
                              category:category
                                coupon:coupon
                                  name:name
                                 price:price
                             productId:productId
                              quantity:quantity
                               variant:variant
                              currency:currency];
}

+ (AffirmProduct *)productWithProductId:(NSString *)productId
{
    return [[self alloc] initWithBrand:nil
                              category:nil
                                coupon:nil
                                  name:nil
                                 price:nil
                             productId:productId
                              quantity:0
                               variant:nil
                              currency:nil];
}

- (NSDictionary *)toJSONDictionary
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    if (self.brand) {
        dictionary[@"brand"] = self.brand;
    }
    if (self.category) {
        dictionary[@"category"] = self.category;
    }
    if (self.coupon) {
        dictionary[@"coupon"] = self.coupon;
    }
    if (self.name) {
        dictionary[@"name"] = self.name;
    }
    if (self.price) {
        dictionary[@"price"] = self.price;
    }
    dictionary[@"productId"] = self.productId;
    dictionary[@"quantity"] = @(self.quantity);
    if (self.variant) {
        dictionary[@"variant"] = self.variant;
    }
    if (self.currency) {
        dictionary[@"currency"] = self.currency;
    }
    return dictionary;
}

- (id)copyWithZone:(NSZone *)zone
{
    return [[self class] productWithBrand:self.brand
                                 category:self.category
                                   coupon:self.coupon
                                     name:self.name
                                    price:self.price
                                productId:self.productId
                                 quantity:self.quantity
                                  variant:self.variant
                                 currency:self.currency];
}

@end
