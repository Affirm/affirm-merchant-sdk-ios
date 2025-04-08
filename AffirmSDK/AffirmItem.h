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
 An AffirmCategory object represents the details of categories.
 */
@interface AffirmCategory : NSObject <NSCopying>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/**
 The name of the categories. Optional.
 */
@property (nonatomic, copy, readonly, nullable) NSString *name;

/**
 The sub categories. Required.
 */
@property (nonatomic, copy, readonly) NSArray<NSString *> *subCategories;

/**
 Initializer. See properties for more details.
 
 @param name Categories name.
 @param subCategories All of sub categories.
 @return The initialized category.
 */
- (instancetype)initWithName:(NSString *)name
               subCategories:(NSArray<NSString *> *)subCategories
NS_SWIFT_NAME(init(name:subCategories:));

/**
 Convenience constructor. See properties for more details.
 
 @param name Item name.
 @param subCategories All of sub categories.
 @return The newly created category.
 */
+ (AffirmCategory *)categoryWithName:(NSString *)name
                       subCategories:(NSArray<NSString *> *)subCategories;

@end

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
 The URL of the item page. Optional.
 */
@property(nonatomic, copy, readonly) NSURL *URL;

/**
 The URL of the item image. Optional.
 */
@property(nonatomic, copy, readonly, nullable) NSURL *imageURL;

/**
 An array of lists that indicate the various categories that apply to this product, and the hierarchy of those category definitions. Each list in the array contains one or more comma-separated strings, with the first string being the highest-level (widest) category. Optional.
 */
@property(nonatomic, copy, readonly, nullable) NSArray<AffirmCategory *> *categories;

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
                         URL:(nullable NSURL *)URL
NS_SWIFT_NAME(item(name:sku:unitPrice:quantity:url:));

/**
 Convenience constructor. See properties for more details.
 
 @param name Item name.
 @param SKU Item SKU.
 @param unitPrice Price per item.
 @param quantity Number of items purchased.
 @param URL URL of the item.
 @param categories An array of lists that indicate the various categories that apply to this product, and the hierarchy of those category definitions.
 @return The newly created item.
 */
+ (AffirmItem *)itemWithName:(NSString *)name
                         SKU:(NSString *)SKU
                   unitPrice:(NSDecimalNumber *)unitPrice
                    quantity:(NSInteger)quantity
                         URL:(nullable NSURL *)URL
                  categories:(nullable NSArray<AffirmCategory *> *)categories
NS_SWIFT_NAME(item(name:sku:unitPrice:quantity:url:categories:));

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
                         URL:(nullable NSURL *)URL
NS_SWIFT_NAME(init(name:sku:unitPrice:quantity:url:));

/**
 Initializer. See properties for more details.
 
 @param name Item name.
 @param SKU Item SKU.
 @param unitPrice Price per item.
 @param quantity Number of items purchased.
 @param URL URL of the item.
 @param categories An array of lists that indicate the various categories that apply to this product, and the hierarchy of those category definitions.
 @return The initialized item.
 */
- (instancetype)initWithName:(NSString *)name
                         SKU:(NSString *)SKU
                   unitPrice:(NSDecimalNumber *)unitPrice
                    quantity:(NSInteger)quantity
                         URL:(nullable NSURL *)URL
                  categories:(nullable NSArray<AffirmCategory *> *)categories
NS_SWIFT_NAME(init(name:sku:unitPrice:quantity:url:categories:));

@end

NS_ASSUME_NONNULL_END
