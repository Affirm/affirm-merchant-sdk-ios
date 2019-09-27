//
//  AffirmBillingDetail.h
//  AffirmSDK
//
//  Created by Victor Zhu on 2019/9/27.
//  Copyright © 2019 Affirm, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AffirmJSONifiable.h"

NS_ASSUME_NONNULL_BEGIN

@interface AffirmBillingDetail : NSObject <AffirmJSONifiable, NSCopying>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/**
 The customer's name. Optional.
 */
@property(nonatomic, copy, readonly, nullable) NSString *name;

/**
 The customer's phone number. Optional.
 */
@property(nonatomic, copy, readonly, nullable) NSString *phoneNumber;

/**
 The customer's email. Optional.
 */
@property(nonatomic, copy, readonly, nullable) NSString *email;

/**
 Address line 1. Optional.
 */
@property(nonatomic, copy, readonly, nullable) NSString *line1;

/**
 Address line 2. Optional.
 */
@property(nonatomic, copy, readonly, nullable) NSString *line2;

/**
 City. Optional.
 */
@property(nonatomic, copy, readonly, nullable) NSString *city;

/**
 State. Optional.
 */
@property(nonatomic, copy, readonly, nullable) NSString *state;

/**
 ZIP code. Optional.
 */
@property(nonatomic, copy, readonly, nullable) NSString *zipCode;

/**
 Country code. Optional.
 */
@property(nonatomic, copy, readonly, nullable) NSString *countryCode;

/**
 Convenience constructor for a billing detail object.

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
+ (AffirmBillingDetail *)billingDetailWithName:(nullable NSString *)name
                                         email:(nullable NSString *)email
                                   phoneNumber:(nullable NSString *)phoneNumber
                              addressWithLine1:(nullable NSString *)line1
                                         line2:(nullable NSString *)line2
                                          city:(nullable NSString *)city
                                         state:(nullable NSString *)state
                                       zipCode:(nullable NSString *)zipCode
                                   countryCode:(nullable NSString *)countryCode
NS_SWIFT_NAME(billingDetail(name:email:phoneNumber:line1:line2:city:state:zipCode:countryCode:));

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
- (instancetype)initBillingDetailWithName:(nullable NSString *)name
                                    email:(nullable NSString *)email
                              phoneNumber:(nullable NSString *)phoneNumber
                         addressWithLine1:(nullable NSString *)line1
                                    line2:(nullable NSString *)line2
                                     city:(nullable NSString *)city
                                    state:(nullable NSString *)state
                                  zipCode:(nullable NSString *)zipCode
                              countryCode:(nullable NSString *)countryCode
NS_SWIFT_NAME(init(name:email:phoneNumber:line1:line2:city:state:zipCode:countryCode:));

@end

NS_ASSUME_NONNULL_END
