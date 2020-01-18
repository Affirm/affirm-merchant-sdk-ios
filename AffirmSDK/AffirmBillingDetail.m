//
//  AffirmBillingDetail.m
//  AffirmSDK
//
//  Created by Victor Zhu on 2019/9/27.
//  Copyright © 2019 Affirm, Inc. All rights reserved.
//

#import "AffirmBillingDetail.h"
#import "AffirmConfiguration.h"

@implementation AffirmBillingDetail

+ (AffirmBillingDetail *)billingDetailWithName:(nullable NSString *)name
                                         email:(nullable NSString *)email
                                   phoneNumber:(nullable NSString *)phoneNumber
                              addressWithLine1:(nullable NSString *)line1
                                         line2:(nullable NSString *)line2
                                          city:(nullable NSString *)city
                                         state:(nullable NSString *)state
                                       zipCode:(nullable NSString *)zipCode
                                   countryCode:(nullable NSString *)countryCode
{
    return [[self alloc] initBillingDetailWithName:name
                                             email:email
                                       phoneNumber:phoneNumber
                                  addressWithLine1:line1
                                             line2:line2
                                              city:city
                                             state:state
                                           zipCode:zipCode
                                       countryCode:countryCode];
}

- (instancetype)initBillingDetailWithName:(nullable NSString *)name
                                    email:(nullable NSString *)email
                              phoneNumber:(nullable NSString *)phoneNumber
                         addressWithLine1:(nullable NSString *)line1
                                    line2:(nullable NSString *)line2
                                     city:(nullable NSString *)city
                                    state:(nullable NSString *)state
                                  zipCode:(nullable NSString *)zipCode
                              countryCode:(nullable NSString *)countryCode
{
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
    if (!self.name && !self.email && !self.phoneNumber && (!self.line1 || !self.line2 || !self.city || !self.state || !self.zipCode || !self.countryCode)) {
        return @{};
    }

    return @{
        @"billing": [self getBillingJSONDictionary]
    };
}

- (NSDictionary *)getBillingJSONDictionary
{
    NSMutableDictionary *jsonDic = [@{} mutableCopy];
    if (self.line1 && self.line2 && self.city && self.state && self.zipCode && self.countryCode) {
        BOOL usingInternationalRule = [AffirmConfiguration sharedInstance].locale == AffirmLocaleCA;
        NSDictionary *address =  @{
            usingInternationalRule ? @"street1" : @"line1": self.line1,
            usingInternationalRule ? @"street2" : @"line2": self.line2,
            @"city": self.city,
            usingInternationalRule ? @"region1_code" : @"state": self.state,
            usingInternationalRule ? @"postal_code" : @"zipcode": self.zipCode,
            usingInternationalRule ? @"country_code" : @"country": self.countryCode
        };
        jsonDic[@"address"] = address;
    }
    if (self.name) {
        jsonDic[@"name"] = @{@"full": self.name};
    }
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
    return [[self class] billingDetailWithName:self.name
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
