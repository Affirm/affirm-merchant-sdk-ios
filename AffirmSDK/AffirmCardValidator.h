//
//  AffirmCardValidator.h
//  AffirmSDK
//
//  Created by Victor Zhu on 2020/9/23.
//  Copyright © 2020 Affirm, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    AffirmBrandTypeUnknown,
    AffirmBrandTypeVisa,
    AffirmBrandTypeAmex,
    AffirmBrandTypeMastercard,
    AffirmBrandTypeDiscover,
    AffirmBrandTypeJCB,
    AffirmBrandTypeDinersClub,
    AffirmBrandTypeUnionPay
} AffirmBrandType;

@interface AffirmBrand : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *rangeStart;
@property (nonatomic, strong) NSString *rangeEnd;
@property (nonatomic) NSInteger length;
@property (nonatomic) AffirmBrandType type;

- (instancetype)initWithName:(NSString *)name
                  rangeStart:(NSString *)rangeStart
                    rangeEnd:(NSString *)rangeEnd
                      length:(NSInteger)length
                        type:(AffirmBrandType)type;
+ (instancetype)brandWithName:(NSString *)name
                   rangeStart:(NSString *)rangeStart
                     rangeEnd:(NSString *)rangeEnd
                       length:(NSInteger)length
                         type:(AffirmBrandType)type;
- (BOOL)matchesNumber:(NSString *)number;

@end

@interface AffirmCardValidator : NSObject

+ (instancetype)sharedCardValidator;
- (nullable AffirmBrand *)brandForCardNumber:(NSString *)cardNumber;
+ (NSArray <NSNumber *> *)cardNumberFormatForBrand:(AffirmBrandType)type;

@end

NS_ASSUME_NONNULL_END
