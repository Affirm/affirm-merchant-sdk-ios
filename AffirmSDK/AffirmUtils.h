//
//  AffirmUtils.h
//  AffirmSDK
//
//  Created by Victor Zhu on 2019/3/4.
//  Copyright © 2019 Affirm, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDictionary (Utils)

- (NSString *)queryURLEncoding;
- (NSError *)convertToNSErrorWithCode:(NSNumber *)code;
- (NSError *)convertToNSError;

@end

@interface NSBundle (Utils)

+ (NSBundle *)sdkBundle;
+ (NSBundle *)resourceBundle;

@end

@interface NSString (Utils)

- (NSDictionary *)convertToDictionary;
- (NSString *)stringByRemovingIllegalCharacters;
- (NSDecimalNumber *)currencyDecimal;

@end

@interface NSDecimalNumber (Utils)

- (NSDecimalNumber *)toIntegerCents;
- (NSString *)formattedString;
- (NSString *)formattedStringWithFractionDigits:(NSInteger)fractionDigits;

@end

@interface AffirmJSONValue : NSObject

+ (NSString *)stringFromValue:(nullable id)value fallback:(NSString *)fallback;
+ (nullable NSString *)nullableStringFromValue:(nullable id)value;
+ (NSNumber *)numberFromValue:(nullable id)value fallback:(NSNumber *)fallback;
+ (nullable NSArray<NSString *> *)stringArrayFromValue:(nullable id)value;

@end

@interface AffirmValidationUtils : NSObject

+ (void)checkNotNil:(id)value
               name:(NSString *)name;

+ (void)checkNotNegative:(NSDecimalNumber *)value
                    name:(NSString *)name;

@end

@interface UIImage (Utils)

+ (nullable UIImage *)imageNamed:(NSString *)name ofType:(NSString *)type inBundle:(nullable NSBundle *)bundle;

@end

NS_ASSUME_NONNULL_END
