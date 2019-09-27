//
//  AffirmCheckoutDataModel.h
//  AffirmSDK
//
//  Created by yijie on 2019/3/6.
//  Copyright © 2019 Affirm, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AffirmJSONifiable.h"

NS_ASSUME_NONNULL_BEGIN

/**
 An AffirmShippingDetail object represents the shipping details for a customer.
 */
@interface AffirmShippingDetail : NSObject <AffirmJSONifiable, NSCopying>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/**
 The customer's name. Required in shipping contact; otherwise optional. (See AffirmCheckout for more info.)
 */
@property(nonatomic, copy, readonly) NSString *name;

/**
 The customer's phone number. Optional.
 */
@property(nonatomic, copy, readonly, nullable) NSString *phoneNumber;

/**
 The customer's email. Optional.
 */
@property(nonatomic, copy, readonly, nullable) NSString *email;

/**
 Address line 1. Required.
 */
@property(nonatomic, copy, readonly) NSString *line1;

/**
 Address line 2. Required.
 */
@property(nonatomic, copy, readonly) NSString *line2;

/**
 City. Required.
 */
@property(nonatomic, copy, readonly) NSString *city;

/**
 State. Required.
 */
@property(nonatomic, copy, readonly) NSString *state;

/**
 ZIP code. Required.
 */
@property(nonatomic, copy, readonly) NSString *zipCode;

/**
 Country code. Required.
 */
@property(nonatomic, copy, readonly) NSString *countryCode;

/**
 Convenience constructor for a shipping detail object.

 @param name Name
 @param line1 Address line 1.
 @param line2 Address line 2.
 @param city City
 @param state State
 @param zipCode ZIP code.
 @param countryCode Country code.
 @return The initialized address.
 */
+ (AffirmShippingDetail *)shippingDetailWithName:(NSString *)name
                                addressWithLine1:(NSString *)line1
                                           line2:(NSString *)line2
                                            city:(NSString *)city
                                           state:(NSString *)state
                                         zipCode:(NSString *)zipCode
                                     countryCode:(NSString *)countryCode
NS_SWIFT_NAME(shippingDetail(name:line1:line2:city:state:zipCode:countryCode:));

/**
 Convenience constructor for a shipping detail object with email and phone number.

 @param name Name
 @param email Email
 @param phoneNumber Phone number.
 @param line1 Address line 1.
 @param line2 Address line 2.
 @param city City
 @param state State
 @param zipCode ZIP code.
 @param countryCode Country code.
 @return The initialized address.
 */
+ (AffirmShippingDetail *)shippingDetailWithName:(NSString *)name
                                           email:(nullable NSString *)email
                                     phoneNumber:(nullable NSString *)phoneNumber
                                addressWithLine1:(NSString *)line1
                                           line2:(NSString *)line2
                                            city:(NSString *)city
                                           state:(NSString *)state
                                         zipCode:(NSString *)zipCode
                                     countryCode:(NSString *)countryCode
NS_SWIFT_NAME(shippingDetail(name:email:phoneNumber:line1:line2:city:state:zipCode:countryCode:));

/**
 Initializer for a shipping detail object with email and phone number.

 @param name Name
 @param email Email
 @param phoneNumber Phone number.
 @param line1 Address line 1.
 @param line2 Address line 2.
 @param city City
 @param state State
 @param zipCode ZIP code.
 @param countryCode Country code.
 @return The initialized address.
 */
- (instancetype)initShippingDetailWithName:(NSString *)name
                                     email:(nullable NSString *)email
                               phoneNumber:(nullable NSString *)phoneNumber
                          addressWithLine1:(NSString *)line1
                                     line2:(NSString *)line2
                                      city:(NSString *)city
                                     state:(NSString *)state
                                   zipCode:(NSString *)zipCode
                               countryCode:(NSString *)countryCode
NS_SWIFT_NAME(init(name:email:phoneNumber:line1:line2:city:state:zipCode:countryCode:));

@end

NS_ASSUME_NONNULL_END
