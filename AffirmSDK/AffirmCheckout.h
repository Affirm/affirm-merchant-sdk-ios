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
@class AffirmBillingDetail;

NS_ASSUME_NONNULL_BEGIN

/**
 An AffirmCheckout is complete Affirm checkout object describing the customer and the purchase.
 */
@interface AffirmCheckout : NSObject <AffirmJSONifiable, NSCopying>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/**
 A flag whether to send addresses to Affirm server, default is YES.
 */
@property (nonatomic) BOOL sendShippingAddress;

/**
 A list of purchased items. Required.
 */
@property (nonatomic, copy, readonly) NSArray <AffirmItem *>*items;

/**
 Shipping contact information. Depending on sendShippingAddress, if sendShippingAddress is true, it's required.
 */
@property (nonatomic, copy, readonly, nullable) AffirmShippingDetail *shipping;

/**
 Shipping contact information. Optional.
 */
@property (nonatomic, copy, nullable) AffirmBillingDetail *billing;

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
 The total amount. Dynamically computed from the other properties of the checkout if not available
 */
@property (nonatomic, copy) NSDecimalNumber *totalAmount;

/**
 The final payout amount, in cents. Can be passed in directly, instead of passing in shipping/tax/discount data.
 */
@property (nonatomic, copy, nullable) NSDecimalNumber *payoutAmount API_DEPRECATED("Use totalAmount instead.", ios(2.0, 13.0));

/**
 Any financing program that should be applied (see https://docs.affirm.com/Integrate_Affirm/Multiple_Financing_Programs)
 */
@property (nonatomic, copy, readonly, nullable) NSString *financingProgram;

/**
 Your internal order id. This is stored for your own future reference.
 */
@property (nonatomic, copy, readonly, nullable) NSString *orderId;

/**
 Credit as a service
 */
@property (nonatomic, copy, nullable) NSString *caas;

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
                     shipping:(nullable AffirmShippingDetail *)shipping
                    taxAmount:(NSDecimalNumber *)taxAmount
               shippingAmount:(NSDecimalNumber *)shippingAmount
                    discounts:(nullable NSArray <AffirmDiscount *>*)discounts
                     metadata:(nullable NSDictionary *)metadata
             financingProgram:(nullable NSString *)financingProgram
NS_SWIFT_NAME(init(items:shipping:taxAmount:shippingAmount:discounts:metadata:financingProgram:));

/**
 Initializer. See properties for more details.

 @param items List of purchased items.
 @param shipping Shipping contact.
 @param taxAmount Tax amount.
 @param shippingAmount Shipping amount.
 @param discounts List of discounts.
 @param metadata Additional metadata.
 @param financingProgram Financing Program to be applied.
 @param orderId Your internal order id.
 @return The initialized checkout.
 */
- (instancetype)initWithItems:(NSArray <AffirmItem *>*)items
                     shipping:(nullable AffirmShippingDetail *)shipping
                    taxAmount:(NSDecimalNumber *)taxAmount
               shippingAmount:(NSDecimalNumber *)shippingAmount
                    discounts:(nullable NSArray <AffirmDiscount *>*)discounts
                     metadata:(nullable NSDictionary *)metadata
             financingProgram:(nullable NSString *)financingProgram
                      orderId:(nullable NSString *)orderId
NS_SWIFT_NAME(init(items:shipping:taxAmount:shippingAmount:discounts:metadata:financingProgram:orderId:));

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
                             shipping:(nullable AffirmShippingDetail *)shipping
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
                             shipping:(nullable AffirmShippingDetail *)shipping
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
                             shipping:(nullable AffirmShippingDetail *)shipping
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
                             shipping:(nullable AffirmShippingDetail *)shipping
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
                     shipping:(nullable AffirmShippingDetail *)shipping
                    discounts:(nullable NSArray <AffirmDiscount *>*)discounts
                     metadata:(nullable NSDictionary *)metadata
             financingProgram:(nullable NSString *)financingProgram
                 payoutAmount:(NSDecimalNumber *)payoutAmount API_DEPRECATED("Use initWithItems:shipping:discounts:metadata:financingProgram:totalAmount: instead.", ios(2.0, 13.0))
NS_SWIFT_NAME(init(items:shipping:discounts:metadata:financingProgram:payoutAmount:));

/**
 Initializer. See properties for more details.

 @param items List of purchased items.
 @param shipping Shipping contact.
 @param discounts List of discounts.
 @param metadata Additional metadata.
 @param financingProgram Financing Program to be applied.
 @param totalAmount Total amount of the checkout.
 @return The initialized checkout.
 */
- (instancetype)initWithItems:(NSArray <AffirmItem *>*)items
                     shipping:(nullable AffirmShippingDetail *)shipping
                    discounts:(nullable NSArray <AffirmDiscount *>*)discounts
                     metadata:(nullable NSDictionary *)metadata
             financingProgram:(nullable NSString *)financingProgram
                  totalAmount:(NSDecimalNumber *)totalAmount
NS_SWIFT_NAME(init(items:shipping:discounts:metadata:financingProgram:totalAmount:));

/**
 Convenience constructor. See properties for more details.

 @param items List of purchased items.
 @param shipping Shipping contact.
 @param payoutAmount Final payout amount, in cents, of the transaction.
 @return The newly created checkout.
 */
+ (AffirmCheckout *)checkoutWithItems:(NSArray <AffirmItem *>*)items
                             shipping:(nullable AffirmShippingDetail *)shipping
                         payoutAmount:(NSDecimalNumber *)payoutAmount API_DEPRECATED("Use checkoutWithItems:shipping:totalAmount: instead.", ios(2.0, 13.0))
NS_SWIFT_NAME(checkout(items:shipping:payoutAmount:));

/**
 Convenience constructor. See properties for more details.

 @param items List of purchased items.
 @param shipping Shipping contact.
 @param totalAmount Total amount, in cents, of the transaction.
 @return The newly created checkout.
 */
+ (AffirmCheckout *)checkoutWithItems:(NSArray <AffirmItem *>*)items
                             shipping:(nullable AffirmShippingDetail *)shipping
                          totalAmount:(NSDecimalNumber *)totalAmount
NS_SWIFT_NAME(checkout(items:shipping:totalAmount:));

/**
 Convenience constructor. See properties for more details.

 @param items List of purchased items.
 @param shipping Shipping contact.
 @param totalAmount Total amount, in cents, of the transaction.
 @param metadata Additional metadata.
 @return The newly created checkout.
 */
+ (AffirmCheckout *)checkoutWithItems:(NSArray <AffirmItem *>*)items
                             shipping:(nullable AffirmShippingDetail *)shipping
                          totalAmount:(NSDecimalNumber *)totalAmount
                             metadata:(nullable NSDictionary *)metadata
NS_SWIFT_NAME(checkout(items:shipping:totalAmount:metadata:));

@end

NS_ASSUME_NONNULL_END
