//
//  AffirmCheckout.m
//  AffirmSDK
//
//  Created by Paul on 3/14/19.
//  Copyright © 2019 Affirm, Inc. All rights reserved.
//

#import "AffirmCheckout.h"
#import "AffirmUtils.h"
#import "AffirmItem.h"
#import "AffirmDiscount.h"
#import "AffirmShippingDetail.h"

@implementation AffirmCheckout

- (instancetype)initWithItems:(NSArray <AffirmItem *>*)items
                     shipping:(AffirmShippingDetail *)shipping
                    taxAmount:(NSDecimalNumber *)taxAmount
               shippingAmount:(NSDecimalNumber *)shippingAmount
                    discounts:(nullable NSArray <AffirmDiscount *>*)discounts
                     metadata:(nullable NSDictionary *)metadata
             financingProgram:(nullable NSString *)financingProgram
{
    [AffirmValidationUtils checkNotNil:items name:@"items"];
    [AffirmValidationUtils checkNotNil:shipping name:@"shipping"];
    [AffirmValidationUtils checkNotNil:shipping.name name:@"shipping.name"];
    [AffirmValidationUtils checkNotNil:taxAmount name:@"taxAmount"];
    [AffirmValidationUtils checkNotNegative:taxAmount name:@"taxAmount"];
    [AffirmValidationUtils checkNotNil:shippingAmount name:@"shippingAmount"];
    [AffirmValidationUtils checkNotNegative:shippingAmount name:@"shippingAmount"];
    
    if (self = [super init]) {
        _items = [[NSArray alloc] initWithArray:items copyItems:YES];
        _shipping = [shipping copy];
        _taxAmount = [taxAmount copy];
        _shippingAmount = [shippingAmount copy];
        _discounts = (discounts) ? [[NSArray alloc] initWithArray:discounts copyItems:YES] : nil;
        _metadata = (metadata) ? [[NSDictionary alloc] initWithDictionary:metadata copyItems:YES] : nil;
        _financingProgram = (financingProgram) ? [financingProgram copy] : nil;
        _orderId = nil;
    }
    return self;
}

- (instancetype)initWithItems:(NSArray <AffirmItem *>*)items
                     shipping:(AffirmShippingDetail *)shipping
                    taxAmount:(NSDecimalNumber *)taxAmount
               shippingAmount:(NSDecimalNumber *)shippingAmount
                    discounts:(nullable NSArray <AffirmDiscount *>*)discounts
                     metadata:(nullable NSDictionary *)metadata
             financingProgram:(nullable NSString *)financingProgram
                      orderId:(nullable NSString *)orderId
{
    [AffirmValidationUtils checkNotNil:items name:@"items"];
    [AffirmValidationUtils checkNotNil:shipping name:@"shipping"];
    [AffirmValidationUtils checkNotNil:shipping.name name:@"shipping.name"];
    [AffirmValidationUtils checkNotNil:taxAmount name:@"taxAmount"];
    [AffirmValidationUtils checkNotNegative:taxAmount name:@"taxAmount"];
    [AffirmValidationUtils checkNotNil:shippingAmount name:@"shippingAmount"];
    [AffirmValidationUtils checkNotNegative:shippingAmount name:@"shippingAmount"];

    if (self = [super init]) {
        _items = [[NSArray alloc] initWithArray:items copyItems:YES];
        _shipping = [shipping copy];
        _taxAmount = [taxAmount copy];
        _shippingAmount = [shippingAmount copy];
        _discounts = discounts ? [[NSArray alloc] initWithArray:discounts copyItems:YES] : nil;
        _metadata = metadata ? [[NSDictionary alloc] initWithDictionary:metadata copyItems:YES] : nil;
        _financingProgram = financingProgram ? [financingProgram copy] : nil;
        _orderId = orderId ? [orderId copy] : nil;
    }
    return self;
}

+ (AffirmCheckout *)checkoutWithItems:(NSArray <AffirmItem *>*)items
                             shipping:(AffirmShippingDetail *)shipping
                            taxAmount:(NSDecimalNumber *)taxAmount
                       shippingAmount:(NSDecimalNumber *)shippingAmount
{
    return [self checkoutWithItems:items
                          shipping:shipping
                         taxAmount:taxAmount
                    shippingAmount:shippingAmount
                         discounts:nil
                          metadata:nil
                  financingProgram:nil];
}

+ (AffirmCheckout *)checkoutWithItems:(NSArray <AffirmItem *>*)items
                             shipping:(AffirmShippingDetail *)shipping
                            taxAmount:(NSDecimalNumber *)taxAmount
                       shippingAmount:(NSDecimalNumber *)shippingAmount
                     financingProgram:(nullable NSString *)financingProgram
{
    return [self checkoutWithItems:items
                          shipping:shipping
                         taxAmount:taxAmount
                    shippingAmount:shippingAmount
                         discounts:nil
                          metadata:nil
                  financingProgram:financingProgram];
}

+ (AffirmCheckout *)checkoutWithItems:(NSArray <AffirmItem *>*)items
                             shipping:(AffirmShippingDetail *)shipping
                            taxAmount:(NSDecimalNumber *)taxAmount
                       shippingAmount:(NSDecimalNumber *)shippingAmount
                            discounts:(nullable NSArray <AffirmDiscount *>*)discounts
                             metadata:(nullable NSDictionary *)metadata
{
    return [self checkoutWithItems:items
                          shipping:shipping
                         taxAmount:taxAmount
                    shippingAmount:shippingAmount
                         discounts:discounts
                          metadata:metadata
                  financingProgram:nil];
}

+ (AffirmCheckout *)checkoutWithItems:(NSArray <AffirmItem *>*)items
                             shipping:(AffirmShippingDetail *)shipping
                            taxAmount:(NSDecimalNumber *)taxAmount
                       shippingAmount:(NSDecimalNumber *)shippingAmount
                            discounts:(nullable NSArray <AffirmDiscount *>*)discounts
                             metadata:(nullable NSDictionary *)metadata
                     financingProgram:(nullable NSString *)financingProgram
{
    return [[self alloc] initWithItems:items
                              shipping:shipping
                             taxAmount:taxAmount
                        shippingAmount:shippingAmount
                             discounts:discounts
                              metadata:metadata
                      financingProgram:financingProgram];
}

- (instancetype)initWithItems:(NSArray <AffirmItem *>*)items
                     shipping:(AffirmShippingDetail *)shipping
                    discounts:(nullable NSArray <AffirmDiscount *>*)discounts
                     metadata:(nullable NSDictionary *)metadata
             financingProgram:(nullable NSString *)financingProgram
                 payoutAmount:(NSDecimalNumber *)payoutAmount
{
    self = [self initWithItems:items
                      shipping:shipping
                     taxAmount:[NSDecimalNumber zero]
                shippingAmount:[NSDecimalNumber zero]
                     discounts:discounts
                      metadata:metadata
              financingProgram:financingProgram];
    if (self) {
        [AffirmValidationUtils checkNotNil:payoutAmount name:@"payoutAmount"];
        [AffirmValidationUtils checkNotNegative:payoutAmount name:@"payoutAmount"];
        self.payoutAmount = payoutAmount;
    }
    return self;
}

+ (AffirmCheckout *)checkoutWithItems:(NSArray <AffirmItem *>*)items
                             shipping:(AffirmShippingDetail *)shipping
                         payoutAmount:(NSDecimalNumber *)payoutAmount
{
    return [[self alloc] initWithItems:items
                              shipping:shipping
                             discounts:nil
                              metadata:nil
                      financingProgram:nil
                          payoutAmount:payoutAmount];
}

- (NSDecimalNumber *)totalAmount
{
    [AffirmValidationUtils checkNotNil:self.taxAmount name:@"taxAmount"];
    [AffirmValidationUtils checkNotNil:self.shippingAmount name:@"shippingAmount"];
    
    NSDecimalNumber *totalAmount = [self.taxAmount decimalNumberByAdding:self.shippingAmount];
    for (AffirmItem *item in self.items) {
        totalAmount = [totalAmount decimalNumberByAdding:[item.unitPrice decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithDecimal:[[NSNumber numberWithInteger:item.quantity] decimalValue]]]];
    }
    for (AffirmDiscount *discount in self.discounts) {
        totalAmount = [totalAmount decimalNumberBySubtracting:discount.amount];
    }
    return totalAmount;
}

- (NSDictionary *)toJSONDictionary
{
    NSMutableDictionary *items = [[NSMutableDictionary alloc] init];
    for (AffirmItem *item in self.items) {
        [items setObject:[item toJSONDictionary] forKey:item.SKU];
    }
    
    NSMutableDictionary *dict = [@{
                                   @"items": items,
                                   @"total": self.payoutAmount ? self.payoutAmount : [[self totalAmount] toIntegerCents],
                                   @"api_version" :@"v2"
                                   } mutableCopy];
    
    [dict addEntriesFromDictionary:[self.shipping toJSONDictionary]];
    
    if (self.shippingAmount != nil) {
        [dict setValue:self.shippingAmount.toIntegerCents forKey:@"shipping_amount"];
    }
    
    if (self.taxAmount != nil) {
        [dict setValue:self.taxAmount.toIntegerCents forKey:@"tax_amount"];
    }
    
    if (self.discounts != nil) {
        NSMutableDictionary *discounts = [[NSMutableDictionary alloc] init];
        for (AffirmDiscount *discount in self.discounts) {
            [discounts setObject:[discount toJSONDictionary] forKey:discount.name];
        }
        [dict setObject:discounts forKey:@"discounts"];
    }
    
    if (self.metadata != nil) {
        [dict setObject:self.metadata forKey:@"metadata"];
    }
    
    if (self.financingProgram != nil) {
        [dict setObject:self.financingProgram forKey:@"financing_program"];
    }

    if (self.orderId != nil) {
        [dict setObject:self.orderId forKey:@"order_id"];
    }
    
    return dict;
}

- (id)copyWithZone:(NSZone *)zone
{
    AffirmCheckout *copy = [[AffirmCheckout alloc] initWithItems:self.items shipping:self.shipping taxAmount:self.taxAmount shippingAmount:self.shippingAmount discounts:self.discounts metadata:self.metadata financingProgram:self.financingProgram orderId:self.orderId];
    if (self.payoutAmount) {
        copy.payoutAmount = self.payoutAmount;
    }
    return copy;
}

@end
