//
//  AffirmDiscount.h
//  AffirmSDK
//
//  Created by Paul on 3/14/19.
//  Copyright © 2019 Affirm, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AffirmJSONifiable.h"

NS_ASSUME_NONNULL_BEGIN

/**
 An AffirmDiscount object represents a discount applied to the Affirm purchase.
 */
@interface AffirmDiscount : NSObject <AffirmJSONifiable, NSCopying>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/**
 The name of the discount. Required.
 */
@property(nonatomic, copy, readonly) NSString *name;

/**
 The discount amount in USD. Cannot be negative. Required.
 */
@property(nonatomic, copy, readonly) NSDecimalNumber *amount;

/**
 Convenience constructor. See properties for more details.

 @param name Discount name.
 @param amount Discount amount.
 @return The newly created discount.
 */
+ (AffirmDiscount *)discountWithName:(NSString *)name
                              amount:(NSDecimalNumber *)amount
NS_SWIFT_NAME(discount(name:amount:));

/**
 Initializer. See properties for more details.

 @param name Discount name.
 @param amount Discount amount.
 @return The initialized discount.
 */
- (instancetype)initWithName:(NSString *)name
                      amount:(NSDecimalNumber *)amount
NS_SWIFT_NAME(init(name:amount:));

@end

NS_ASSUME_NONNULL_END
