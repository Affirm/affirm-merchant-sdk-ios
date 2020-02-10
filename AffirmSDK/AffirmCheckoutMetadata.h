//
//  AffirmCheckoutMetadata.h
//  AffirmSDK
//
//  Created by Victor Zhu on 2020/1/22.
//  Copyright © 2020 Affirm, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AffirmJSONifiable.h"

NS_ASSUME_NONNULL_BEGIN

@interface AffirmCheckoutMetadata : NSObject <AffirmJSONifiable, NSCopying>

/**
 Shipping type.
 */
@property (nonatomic, copy, nullable) NSString *shippingType;

/**
 Entity name.
 */
@property (nonatomic, copy, nullable) NSString *entityName;

/**
 Webhook session id.
 */
@property (nonatomic, copy, nullable) NSString *webhookSessionId;

/**
Initializer. See properties for more details.

@param shippingType Shipping type.
@param entityName Entity name.
@param webhookSessionId Webhook session id.
@return The initialized metadata.
*/
- (instancetype)initWithShippingType:(nullable NSString *)shippingType
                          entityName:(nullable NSString *)entityName
                    webhookSessionId:(nullable NSString *)webhookSessionId
NS_SWIFT_NAME(init(shippingType:entityName:webhookSessionId:));

/**
Convenience constructor for metadata

@param shippingType Shipping type.
@param entityName Entity name.
@param webhookSessionId Webhook session id.
@return The newly created metadata.
*/
+ (AffirmCheckoutMetadata *)checkoutMetadataWithShippingType:(nullable NSString *)shippingType
                                                  entityName:(nullable NSString *)entityName
                                            webhookSessionId:(nullable NSString *)webhookSessionId
NS_SWIFT_NAME(checkoutMetadata(shippingType:entityName:webhookSessionId:));

@end

NS_ASSUME_NONNULL_END
