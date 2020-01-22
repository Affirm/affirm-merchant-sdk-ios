//
//  AffirmCheckoutMetadata.m
//  AffirmSDK
//
//  Created by Victor Zhu on 2020/1/22.
//  Copyright © 2020 Affirm, Inc. All rights reserved.
//

#import "AffirmCheckoutMetadata.h"
#import "AffirmUtils.h"

@implementation AffirmCheckoutMetadata

- (instancetype)initWithShippingType:(nullable NSString *)shippingType
                          entityName:(nullable NSString *)entityName
                    webhookSessionId:(nullable NSString *)webhookSessionId
{
    if (self = [super init]) {
        _shippingType = shippingType;
        _entityName = entityName;
        _webhookSessionId = webhookSessionId;
    }
    return self;
}

+ (AffirmCheckoutMetadata *)checkoutMetadataWithShippingType:(nullable NSString *)shippingType
                                                  entityName:(nullable NSString *)entityName
                                            webhookSessionId:(nullable NSString *)webhookSessionId
{
    return [[self alloc] initWithShippingType:shippingType
                                   entityName:entityName
                             webhookSessionId:webhookSessionId];
}

- (NSMutableDictionary *)toJSONDictionary
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    if (self.shippingType) {
        dictionary[@"shipping_type"] = self.shippingType;
    }
    if (self.entityName) {
        dictionary[@"entity_name"] = self.entityName;
    }
    if (self.webhookSessionId) {
        dictionary[@"webhook_session_id"] = self.webhookSessionId;
    }
    return dictionary;
}

- (id)copyWithZone:(NSZone *)zone
{
    return [[self class] checkoutMetadataWithShippingType:self.shippingType
                                               entityName:self.entityName
                                         webhookSessionId:self.webhookSessionId];
}

@end
