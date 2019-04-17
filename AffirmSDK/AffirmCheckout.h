//
//  AffirmCheckout.h
//  AffirmSDK
//
//  Created by Paul on 3/14/19.
//  Copyright © 2019 Affirm, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AffirmJSONifiable.h"

@class AffirmItem;
@class AffirmDiscount;
@class AffirmShippingDetail;

NS_ASSUME_NONNULL_BEGIN

/**
 An AffirmCheckout is complete Affirm checkout object describing the customer and the purchase.
 */
@interface AffirmCheckout : NSObject <AffirmJSONifiable, NSCopying>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/**
 A list of purchased items. Required.
 */
@property (nonatomic, copy, readonly) NSArray <AffirmItem *>*items;

/**
 Shipping contact information. Required.
 The shipping contact object must contain a non-nil name and address.
 */
@property (nonatomic, copy, readonly) AffirmShippingDetail *shipping;

/**
 Tax amount in USD. Cannot be negative. Required if total amount isn't passed.
 */
@property (nonatomic, copy, readonly) NSDecimalNumber *taxAmount;

/**
 Shipping amount in USD. Cannot be negative. Required if total amount isn't passed.
 */
@property (nonatomic, copy, readonly) NSDecimalNumber *shippingAmount;

/**
 A list of discounts. Optional.
 */
@property (nonatomic, copy, readonly, nullable) NSArray <AffirmDiscount *>*discounts;

/**
 Additional metadata for the checkout. Optional.
 */
@property (nonatomic, copy, readonly, nullable) NSDictionary *metadata;

/**
 The total purchase amount. Dynamically computed from the other properties of the checkout.
 */
@property (nonatomic, copy, readonly) NSDecimalNumber *totalAmount;

/**
 The final payout amount, in cents. Can be passed in directly, instead of passing in shipping/tax/discount data.
 */
@property (nonatomic, copy, nullable) NSDecimalNumber *payoutAmount;

/**
 Any financing program that should be applied (see https://docs.affirm.com/Integrate_Affirm/Multiple_Financing_Programs)
 */
@property (nonatomic, copy, readonly, nullable) NSString *financingProgram;

/**
 Initializer. See properties for more details.

 @param items List of purchased items.
 @param shipping Shipping contact.
 @param taxAmount Tax amount.
 @param shippingAmount Shipping amount.
 @param discounts List of discounts.
 @param metadata Additional metadata.
 @param financingProgram Financing Program to be applied.
 @return The initialized checkout.
 */
- (instancetype)initWithItems:(NSArray <AffirmItem *>*)items
                     shipping:(AffirmShippingDetail *)shipping
                    taxAmount:(NSDecimalNumber *)taxAmount
               shippingAmount:(NSDecimalNumber *)shippingAmount
                    discounts:(nullable NSArray <AffirmDiscount *>*)discounts
                     metadata:(nullable NSDictionary *)metadata
             financingProgram:(nullable NSString *)financingProgram
NS_SWIFT_NAME(init(items:shipping:taxAmount:shippingAmount:discounts:metadata:financingProgram:));

/**
 Convenience constructor. See properties for more details.

 @param items List of purchased items.
 @param shipping Shipping contact.
 @param taxAmount Tax amount.
 @param shippingAmount Shipping amount.
 @param financingProgram Financing program to be applied.
 @return The newly created checkout.
 */
+ (AffirmCheckout *)checkoutWithItems:(NSArray <AffirmItem *>*)items
                             shipping:(AffirmShippingDetail *)shipping
                            taxAmount:(NSDecimalNumber *)taxAmount
                       shippingAmount:(NSDecimalNumber *)shippingAmount
                     financingProgram:(nullable NSString *)financingProgram
NS_SWIFT_NAME(checkout(items:shipping:taxAmount:shippingAmount:financingProgram:));

/**
 Convenience constructor. See properties for more details.

 @param items List of purchased items.
 @param shipping Shipping contact.
 @param taxAmount Tax amount.
 @param shippingAmount Shipping amount.
 @param discounts List of discounts.
 @param metadata Additional metadata.
 @param financingProgram Financing program to be applied.
 @return The newly created checkout.
 */
+ (AffirmCheckout *)checkoutWithItems:(NSArray <AffirmItem *>*)items
                             shipping:(AffirmShippingDetail *)shipping
                            taxAmount:(NSDecimalNumber *)taxAmount
                       shippingAmount:(NSDecimalNumber *)shippingAmount
                            discounts:(nullable NSArray <AffirmDiscount *>*)discounts
                             metadata:(nullable NSDictionary *)metadata
                     financingProgram:(nullable NSString *)financingProgram
NS_SWIFT_NAME(checkout(items:shipping:taxAmount:shippingAmount:discounts:metadata:financingProgram:));

/**
 Convenience constructor. See properties for more details.

 @param items List of purchased items.
 @param shipping Shipping contact.
 @param taxAmount Tax amount.
 @param shippingAmount Shipping amount.
 @return The newly created checkout.
 */
+ (AffirmCheckout *)checkoutWithItems:(NSArray <AffirmItem *>*)items
                             shipping:(AffirmShippingDetail *)shipping
                            taxAmount:(NSDecimalNumber *)taxAmount
                       shippingAmount:(NSDecimalNumber *)shippingAmount
NS_SWIFT_NAME(checkout(items:shipping:taxAmount:shippingAmount:));

/**
 Convenience constructor. See properties for more details.

 @param items List of purchased items.
 @param shipping Shipping contact.
 @param taxAmount Tax amount.
 @param shippingAmount Shipping amount.
 @param discounts List of discounts.
 @param metadata Additional metadata.
 @return The newly created checkout.
 */
+ (AffirmCheckout *)checkoutWithItems:(NSArray <AffirmItem *>*)items
                             shipping:(AffirmShippingDetail *)shipping
                            taxAmount:(NSDecimalNumber *)taxAmount
                       shippingAmount:(NSDecimalNumber *)shippingAmount
                            discounts:(nullable NSArray <AffirmDiscount *>*)discounts
                             metadata:(nullable NSDictionary *)metadata
NS_SWIFT_NAME(checkout(items:shipping:taxAmount:shippingAmount:discounts:metadata:));

/**
 Initializer. See properties for more details.

 @param items List of purchased items.
 @param shipping Shipping contact.
 @param discounts List of discounts.
 @param metadata Additional metadata.
 @param financingProgram Financing Program to be applied.
 @param payoutAmount Final payout amount of the checkout.
 @return The initialized checkout.
 */
- (instancetype)initWithItems:(NSArray <AffirmItem *>*)items
                     shipping:(AffirmShippingDetail *)shipping
                    discounts:(nullable NSArray <AffirmDiscount *>*)discounts
                     metadata:(nullable NSDictionary *)metadata
             financingProgram:(nullable NSString *)financingProgram
                 payoutAmount:(NSDecimalNumber *)payoutAmount
NS_SWIFT_NAME(init(items:shipping:discounts:metadata:financingProgram:payoutAmount:));

/**
 Convenience constructor. See properties for more details.

 @param items List of purchased items.
 @param shipping Shipping contact.
 @param payoutAmount Final payout amount, in cents, of the transaction.
 @return The newly created checkout.
 */
+ (AffirmCheckout *)checkoutWithItems:(NSArray <AffirmItem *>*)items
                             shipping:(AffirmShippingDetail *)shipping
                         payoutAmount:(NSDecimalNumber *)payoutAmount
NS_SWIFT_NAME(checkout(items:shipping:payoutAmount:));

@end

NS_ASSUME_NONNULL_END
