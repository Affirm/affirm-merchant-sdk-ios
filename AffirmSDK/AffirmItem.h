//
//  AffirmItem.h
//  AffirmSDK
//
//  Created by Paul on 3/14/19.
//  Copyright © 2019 Affirm, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AffirmJSONifiable.h"

NS_ASSUME_NONNULL_BEGIN

/**
 An AffirmItem object represents an item that is purchased.
 */
@interface AffirmItem : NSObject <AffirmJSONifiable, NSCopying>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/**
 The name of the item. Required.
 */
@property(nonatomic, copy, readonly) NSString *name;

/**
 The SKU (stock keeping unit) of the item. Required.
 */
@property(nonatomic, copy, readonly) NSString *SKU;

/**
 The price in USD per item. Cannot be negative. Required.
 */
@property(nonatomic, copy, readonly) NSDecimalNumber *unitPrice;

/**
 The quantity of items purchased. Cannot be negative. Required.
 */
@property(nonatomic, readonly) NSInteger quantity;

/**
 The URL of the item page. Required.
 */
@property(nonatomic, copy, readonly) NSURL *URL;

/**
 The URL of the item image. Required.
 */
@property(nonatomic, copy, readonly) NSURL *imageURL;

/**
 Convenience constructor. See properties for more details.

 @param name Item name.
 @param SKU Item SKU.
 @param unitPrice Price per item.
 @param quantity Number of items purchased.
 @param URL URL of the item.
 @return The newly created item.
 */
+ (AffirmItem *)itemWithName:(NSString *)name
                         SKU:(NSString *)SKU
                   unitPrice:(NSDecimalNumber *)unitPrice
                    quantity:(NSInteger)quantity
                         URL:(NSURL *)URL
NS_SWIFT_NAME(item(name:sku:unitPrice:quantity:url:));

/**
 Initializer. See properties for more details.

 @param name Item name.
 @param SKU Item SKU.
 @param unitPrice Price per item.
 @param quantity Number of items purchased.
 @param URL URL of the item.
 @return The initialized item.
 */
- (instancetype)initWithName:(NSString *)name
                         SKU:(NSString *)SKU
                   unitPrice:(NSDecimalNumber *)unitPrice
                    quantity:(NSInteger)quantity
                         URL:(NSURL *)URL
NS_SWIFT_NAME(init(name:sku:unitPrice:quantity:url:));

@end

NS_ASSUME_NONNULL_END
