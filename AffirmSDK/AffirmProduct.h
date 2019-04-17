//
//  AffirmProduct.h
//  AffirmSDK
//
//  Created by Victor Zhu on 2019/4/2.
//  Copyright © 2019 Affirm, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AffirmJSONifiable.h"

NS_ASSUME_NONNULL_BEGIN

/**
 An AffirmProduct includes the list of products.
 */
@interface AffirmProduct : NSObject <AffirmJSONifiable, NSCopying>

/**
 Brand name.
 */
@property (nonatomic, copy, nullable) NSString *brand;

/**
 Category name.
 */
@property (nonatomic, copy, nullable) NSString *category;

/**
 Coupon code.
 */
@property (nonatomic, copy, nullable) NSString *coupon;

/**
 Product name.
 */
@property (nonatomic, copy, nullable) NSString *name;

/**
 Product price.
 */
@property (nonatomic, copy, nullable) NSDecimalNumber *price;

/**
 Product id.
 */
@property (nonatomic, copy) NSString *productId;

/**
 Product quantity.
 */
@property (nonatomic) NSInteger quantity;

/**
 Variant.
 */
@property (nonatomic, copy, nullable) NSString *variant;

/**
 Currency type.
 */
@property (nonatomic, copy, nullable) NSString *currency;

/**
 Initializer. See properties for more details.

 @param brand Brand name.
 @param category Category name.
 @param coupon Coupon code.
 @param name Product name.
 @param price Product price.
 @param productId Product id.
 @param quantity Quantity.
 @param variant Variant.
 @param currency Currency type.
 @return The initialized product.
 */
- (instancetype)initWithBrand:(nullable NSString *)brand
                     category:(nullable NSString *)category
                       coupon:(nullable NSString *)coupon
                         name:(nullable NSString *)name
                        price:(nullable NSDecimalNumber *)price
                    productId:(NSString *)productId
                     quantity:(NSInteger)quantity
                      variant:(nullable NSString *)variant
                     currency:(nullable NSString *)currency
NS_SWIFT_NAME(init(brand:category:coupon:name:price:productId:quantity:variant:currency:));

/**
 Convenience constructor for product

 @param brand Brand name.
 @param category Category name.
 @param coupon Coupon code.
 @param name Product name.
 @param price Product price.
 @param productId Product id.
 @param quantity Quantity.
 @param variant Variant.
 @param currency Currency type.
 @return The newly created product.
 */
+ (AffirmProduct *)productWithBrand:(nullable NSString *)brand
                           category:(nullable NSString *)category
                             coupon:(nullable NSString *)coupon
                               name:(nullable NSString *)name
                              price:(nullable NSDecimalNumber *)price
                          productId:(NSString *)productId
                           quantity:(NSInteger)quantity
                            variant:(nullable NSString *)variant
                           currency:(nullable NSString *)currency
NS_SWIFT_NAME(product(brand:category:coupon:name:price:productId:quantity:variant:currency:));

/**
 Convenience constructor for product

 @param productId Product id.
 @return The newly created product.
 */
+ (AffirmProduct *)productWithProductId:(NSString *)productId
NS_SWIFT_NAME(product(productId:));

@end

NS_ASSUME_NONNULL_END
