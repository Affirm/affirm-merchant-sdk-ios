//
//  AffirmOrder.m
//  AffirmSDK
//
//  Created by Victor Zhu on 2019/4/2.
//  Copyright © 2019 Affirm, Inc. All rights reserved.
//

#import "AffirmOrder.h"
#import "AffirmUtils.h"

@implementation AffirmOrder

- (instancetype)initWithStoreName:(NSString *)storeName
                       checkoutId:(nullable NSString *)checkoutId
                           coupon:(nullable NSString *)coupon
                         currency:(nullable NSString *)currency
                         discount:(nullable NSDecimalNumber *)discount
                          orderId:(NSString *)orderId
                    paymentMethod:(nullable NSString *)paymentMethod
                          revenue:(nullable NSDecimalNumber *)revenue
                         shipping:(nullable NSDecimalNumber *)shipping
                   shippingMethod:(nullable NSString *)shippingMethod
                              tax:(nullable NSDecimalNumber *)tax
                            total:(nullable NSDecimalNumber *)total
{
    [AffirmValidationUtils checkNotNil:storeName name:@"storeName"];
    [AffirmValidationUtils checkNotNil:orderId name:@"orderId"];

    if (self = [super init]) {
        _storeName = [storeName copy];
        _checkoutId = [checkoutId copy];
        _coupon = [coupon copy];
        _currency = [currency copy];
        _discount = [discount copy];
        _orderId = [orderId copy];
        _paymentMethod = [paymentMethod copy];
        _revenue = [revenue copy];
        _shipping = [shipping copy];
        _shippingMethod = [shippingMethod copy];
        _tax = [tax copy];
        _total = [total copy];
    }
    return self;
}

+ (AffirmOrder *)orderWithStoreName:(NSString *)storeName
                         checkoutId:(nullable NSString *)checkoutId
                             coupon:(nullable NSString *)coupon
                           currency:(nullable NSString *)currency
                           discount:(nullable NSDecimalNumber *)discount
                            orderId:(NSString *)orderId
                      paymentMethod:(nullable NSString *)paymentMethod
                            revenue:(nullable NSDecimalNumber *)revenue
                           shipping:(nullable NSDecimalNumber *)shipping
                     shippingMethod:(nullable NSString *)shippingMethod
                                tax:(nullable NSDecimalNumber *)tax
                              total:(nullable NSDecimalNumber *)total
{
    return [[self alloc] initWithStoreName:storeName
                                checkoutId:checkoutId
                                    coupon:coupon
                                  currency:currency
                                  discount:discount
                                   orderId:orderId
                             paymentMethod:paymentMethod
                                   revenue:revenue
                                  shipping:shipping
                            shippingMethod:shippingMethod
                                       tax:tax
                                     total:total];
}

+ (AffirmOrder *)orderWithStoreName:(NSString *)storeName
                            orderId:(NSString *)orderId
{
    return [[self alloc] initWithStoreName:storeName
                                checkoutId:nil
                                    coupon:nil
                                  currency:nil
                                  discount:nil
                                   orderId:orderId
                             paymentMethod:nil
                                   revenue:nil
                                  shipping:nil
                            shippingMethod:nil
                                       tax:nil
                                     total:nil];
}

- (NSDictionary *)toJSONDictionary
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    dictionary[@"storeName"] = self.storeName;
    if (self.checkoutId) {
        dictionary[@"checkoutId"] = self.checkoutId;
    }
    if (self.coupon) {
        dictionary[@"coupon"] = self.coupon;
    }
    if (self.currency) {
        dictionary[@"currency"] = self.currency;
    }
    if (self.discount) {
        dictionary[@"discount"] = self.discount;
    }
    dictionary[@"orderId"] = self.orderId;
    if (self.paymentMethod) {
        dictionary[@"paymentMethod"] = self.paymentMethod;
    }
    if (self.revenue) {
        dictionary[@"revenue"] = self.revenue;
    }
    if (self.shipping) {
        dictionary[@"shipping"] = self.shipping;
    }
    if (self.shippingMethod) {
        dictionary[@"shippingMethod"] = self.shippingMethod;
    }
    if (self.tax) {
        dictionary[@"tax"] = self.tax;
    }
    if (self.total) {
        dictionary[@"total"] = self.total;
    }
    return dictionary;
}

- (id)copyWithZone:(NSZone *)zone
{
    return [[self class] orderWithStoreName:self.storeName
                                 checkoutId:self.checkoutId
                                     coupon:self.coupon
                                   currency:self.currency
                                   discount:self.discount
                                    orderId:self.orderId
                              paymentMethod:self.paymentMethod
                                    revenue:self.revenue
                                   shipping:self.shipping
                             shippingMethod:self.shippingMethod
                                        tax:self.tax
                                      total:self.total];
}

@end
