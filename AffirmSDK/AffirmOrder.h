//
//  AffirmOrder.h
//  AffirmSDK
//
//  Created by Victor Zhu on 2019/4/2.
//  Copyright © 2019 Affirm, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AffirmJSONifiable.h"

NS_ASSUME_NONNULL_BEGIN

/**
 An AffirmOrder includes the information of an order.
 */
@interface AffirmOrder : NSObject <AffirmJSONifiable, NSCopying>

/**
 Store name.
 */
@property (nonatomic, copy) NSString *storeName;

/**
 Checkout id.
 */
@property (nonatomic, copy, nullable) NSString *checkoutId;

/**
 Coupon code.
 */
@property (nonatomic, copy, nullable) NSString *coupon;

/**
 Currency type.
 */
@property (nonatomic, copy, nullable) NSString *currency;

/**
 Discount.
 */
@property (nonatomic, copy, nullable) NSDecimalNumber *discount;

/**
 Order id.
 */
@property (nonatomic, copy) NSString *orderId;

/**
 Payment method.
 */
@property (nonatomic, copy, nullable) NSString *paymentMethod;

/**
 Revenue.
 */
@property (nonatomic, copy, nullable) NSDecimalNumber *revenue;

/**
 Shipping cost.
 */
@property (nonatomic, copy, nullable) NSDecimalNumber *shipping;

/**
 Shipping method.
 */
@property (nonatomic, copy, nullable) NSString *shippingMethod;

/**
 Tax fee.
 */
@property (nonatomic, copy, nullable) NSDecimalNumber *tax;

/**
 Total cost.
 */
@property (nonatomic, copy, nullable) NSDecimalNumber *total;

/**
 Initializer. See properties for more details.

 @param storeName Store name.
 @param checkoutId Checout id.
 @param coupon Coupon code.
 @param currency Currency type.
 @param discount Discount.
 @param orderId Order id.
 @param paymentMethod Payment method.
 @param revenue Revenue.
 @param shipping Shipping cost.
 @param shippingMethod Shipping method.
 @param tax Tax fee.
 @param total Total cost.
 @return The initialized order.
 */
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
NS_SWIFT_NAME(init(storeName:checkoutId:coupon:currency:discount:orderId:paymentMethod:revenue:shipping:shippingMethod:tax:total:));

/**
 Convenience constructor for order

 @param storeName Store name.
 @param checkoutId Checout id.
 @param coupon Coupon code.
 @param currency Currency type.
 @param discount Discount.
 @param orderId Order id.
 @param paymentMethod Payment method.
 @param revenue Revenue.
 @param shipping Shipping cost.
 @param shippingMethod Shipping method.
 @param tax Tax fee.
 @param total Total cost.
 @return The newly created order.
 */
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
NS_SWIFT_NAME(order(storeName:checkoutId:coupon:currency:discount:orderId:paymentMethod:revenue:shipping:shippingMethod:tax:total:));

/**
 Convenience constructor for order

 @param storeName Store name.
 @param orderId Order id.
 @return The newly created order.
 */
+ (AffirmOrder *)orderWithStoreName:(NSString *)storeName
                            orderId:(NSString *)orderId
NS_SWIFT_NAME(order(storeName:orderId:));

@end

NS_ASSUME_NONNULL_END
