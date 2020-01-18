//
//  AffirmCheckoutDataModel.m
//  AffirmSDK
//
//  Created by yijie on 2019/3/6.
//  Copyright © 2019 Affirm, Inc. All rights reserved.
//

#import "AffirmShippingDetail.h"
#import "AffirmUtils.h"
#import "AffirmConfiguration.h"

@implementation AffirmShippingDetail

+ (AffirmShippingDetail *)shippingDetailWithName:(NSString *)name
                                addressWithLine1:(NSString *)line1
                                           line2:(NSString *)line2
                                            city:(NSString *)city
                                           state:(NSString *)state
                                         zipCode:(NSString *)zipCode
                                     countryCode:(NSString *)countryCode
{
    return [[self alloc] initShippingDetailWithName:name
                                              email:nil
                                        phoneNumber:nil
                                   addressWithLine1:line1
                                              line2:line2
                                               city:city
                                              state:state
                                            zipCode:zipCode
                                        countryCode:countryCode];
}

+ (AffirmShippingDetail *)shippingDetailWithName:(NSString *)name
                                           email:(NSString *)email
                                     phoneNumber:(NSString *)phoneNumber
                                addressWithLine1:(NSString *)line1
                                           line2:(NSString *)line2
                                            city:(NSString *)city
                                           state:(NSString *)state
                                         zipCode:(NSString *)zipCode
                                     countryCode:(NSString *)countryCode
{
    return [[self alloc] initShippingDetailWithName:name
                                              email:email
                                        phoneNumber:phoneNumber
                                   addressWithLine1:line1
                                              line2:line2
                                               city:city
                                              state:state
                                            zipCode:zipCode
                                        countryCode:countryCode];
}

- (instancetype)initShippingDetailWithName:(NSString *)name
                                     email:(nullable NSString *)email
                               phoneNumber:(nullable NSString *)phoneNumber
                          addressWithLine1:(NSString *)line1
                                     line2:(NSString *)line2
                                      city:(NSString *)city
                                     state:(NSString *)state
                                   zipCode:(NSString *)zipCode
                               countryCode:(NSString *)countryCode
{
    [AffirmValidationUtils checkNotNil:name name:@"name"];
    [AffirmValidationUtils checkNotNil:line1 name:@"line1"];
    [AffirmValidationUtils checkNotNil:line2 name:@"line2"];
    [AffirmValidationUtils checkNotNil:city name:@"city"];
    [AffirmValidationUtils checkNotNil:state name:@"state"];
    [AffirmValidationUtils checkNotNil:zipCode name:@"zipCode"];
    [AffirmValidationUtils checkNotNil:countryCode name:@"countryCode"];
    
    if (self = [super init]) {
        _name = [name copy];
        _email = [email copy];
        _phoneNumber = [phoneNumber copy];
        _line1 = [line1 copy];
        _line2 = [line2 copy];
        _city = [city copy];
        _state = [state copy];
        _zipCode = [zipCode copy];
        _countryCode = [countryCode copy];
    }
    return self;
}

- (NSDictionary *)toJSONDictionary
{
    return @{
        @"shipping": [self getShippingJSONDictionary]
    };
}

- (NSDictionary *)getShippingJSONDictionary
{
    BOOL usingInternationalRule = [AffirmConfiguration sharedInstance].locale == AffirmLocaleCA;
    NSDictionary *address =  @{
        usingInternationalRule ? @"street1" : @"line1": self.line1,
        usingInternationalRule ? @"street2" : @"line2": self.line2,
        @"city": self.city,
        usingInternationalRule ? @"region1_code" : @"state": self.state,
        usingInternationalRule ? @"postal_code" : @"zipcode": self.zipCode,
        usingInternationalRule ? @"country_code" : @"country": self.countryCode
    };
    NSMutableDictionary *jsonDic = [@{
        @"address": address,
        @"name": @{@"full": self.name}
    } mutableCopy];

    if (self.email) {
        jsonDic[@"email"] = self.email;
    }
    if (self.phoneNumber) {
        jsonDic[@"phone_number"] = self.phoneNumber;
    }
    return jsonDic;
}

- (id)copyWithZone:(NSZone *)zone
{
    return [[self class] shippingDetailWithName:self.name
                                          email:self.email
                                    phoneNumber:self.phoneNumber
                               addressWithLine1:self.line1
                                          line2:self.line2
                                           city:self.city
                                          state:self.state
                                        zipCode:self.zipCode
                                    countryCode:self.countryCode];
}

@end
