//
//  AffirmUtils.m
//  AffirmSDK
//
//  Created by Victor Zhu on 2019/3/4.
//  Copyright © 2019 Affirm, Inc. All rights reserved.
//

#import "AffirmUtils.h"
#import "AffirmConfiguration.h"
#import "AffirmLogger.h"

@implementation NSDictionary (Utils)

- (NSString *)queryURLEncoding
{
    NSMutableArray<NSString *> *parametersArray = [NSMutableArray array];
    [self enumerateKeysAndObjectsUsingBlock:^(NSString *  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[NSString class]]) {
            NSString *queryString = [[NSString stringWithFormat:@"%@", obj] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
            [parametersArray addObject:[NSString stringWithFormat:@"%@=%@", key, queryString]];
        } else if ([obj isKindOfClass:[NSArray class]]) {
            NSData *data = [NSJSONSerialization dataWithJSONObject:obj options:NSJSONWritingPrettyPrinted error:nil];
            NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            dataString = [dataString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
            [parametersArray addObject:[NSString stringWithFormat:@"%@=%@", key, dataString]];
        } else if ([obj isKindOfClass:[NSDecimalNumber class]]) {
            [parametersArray addObject:[NSString stringWithFormat:@"%@=%@", key, [(NSDecimalNumber *)obj stringValue]]];
        }
    }];
    return [parametersArray componentsJoinedByString:@"&"];
}

- (NSError *)convertToNSErrorWithCode:(NSNumber *)code
{
    return [NSError errorWithDomain:AffirmSDKErrorDomain
                               code:[code integerValue]
                           userInfo:self.appendErrorDescription];
}

- (NSError *)convertToNSError
{
    return [self convertToNSErrorWithCode:@(-1)];
}

- (NSDictionary *)appendErrorDescription
{
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] initWithDictionary:self];
    if (self[@"message"]) {
        [userInfo addEntriesFromDictionary: @{NSLocalizedDescriptionKey: self[@"message"]}];
    }
    return userInfo;
}

@end

@implementation NSBundle (Utils)

+ (NSBundle *)sdkBundle
{
#if SWIFT_PACKAGE
    return SWIFTPM_MODULE_BUNDLE;
#else
    return [NSBundle bundleForClass:[AffirmConfiguration class]];
#endif
}

+ (NSBundle *)resourceBundle
{
    return [NSBundle bundleWithPath:[self.sdkBundle pathForResource:@"AffirmSDK" ofType:@"bundle"]];
}

@end

@implementation NSString (Utils)

- (NSDictionary *)convertToDictionary
{
    if (self == nil) {
        return nil;
    }
    NSError *error;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[self dataUsingEncoding:NSUTF8StringEncoding]
                                                         options:0
                                                           error:&error];
    if (error) {
        return nil;
    }
    return dict;
}

- (NSString *)stringByRemovingIllegalCharacters
{
    NSCharacterSet *set = [NSCharacterSet decimalDigitCharacterSet].invertedSet;
    NSArray *components = [self componentsSeparatedByCharactersInSet:set];
    return [components componentsJoinedByString:@""];
}

- (NSDecimalNumber *)currencyDecimal
{
    NSNumberFormatter *numberFormatter = [NSNumberFormatter new];
    numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    numberFormatter.usesGroupingSeparator = YES;
    NSMutableCharacterSet *set = [NSMutableCharacterSet characterSetWithCharactersInString:numberFormatter.currencyGroupingSeparator];
    [set addCharactersInString:numberFormatter.currencySymbol];
    [set addCharactersInString:numberFormatter.internationalCurrencySymbol];
    NSMutableString *term = [self mutableCopy];
    NSRange range = [term rangeOfCharacterFromSet:set];
    while (range.location != NSNotFound) {
        [term replaceCharactersInRange:range withString:@""];
        range = [term rangeOfCharacterFromSet:set];
    }

    NSDecimalNumber *number = [NSDecimalNumber decimalNumberWithString:term];
    return number;
}

@end

@implementation NSDecimalNumber (Utils)

- (NSDecimalNumber *)toIntegerCents
{
    if (self == [NSDecimalNumber notANumber]) {
        [[AffirmLogger sharedInstance] logException:@"NaN can't be convert to cents"];
    }
    
    NSDecimalNumberHandler *round = [NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode:NSRoundPlain
                                                                                           scale:0
                                                                                raiseOnExactness:YES
                                                                                 raiseOnOverflow:YES
                                                                                raiseOnUnderflow:YES
                                                                             raiseOnDivideByZero:YES];
    return [self decimalNumberByMultiplyingByPowerOf10:2 withBehavior:round];
}

- (NSString *)formattedString
{
    NSNumberFormatter *numberFormatter = [NSNumberFormatter new];
    numberFormatter.numberStyle = NSNumberFormatterCurrencyStyle;
    numberFormatter.usesGroupingSeparator = YES;
    numberFormatter.minimumFractionDigits = 2;
    numberFormatter.maximumFractionDigits = 2;
    return [numberFormatter stringFromNumber:self];
}

@end

@implementation UIImage (Utils)

+ (nullable UIImage *)imageNamed:(NSString *)name ofType:(NSString *)type inBundle:(nullable NSBundle *)bundle
{
    return [UIImage imageWithContentsOfFile:[bundle pathForResource:name ofType:type]];
}

@end

@implementation AffirmValidationUtils

+ (void)checkNotNil:(id)value
               name:(NSString *)name
{
    if (value == nil) {
        [[AffirmLogger sharedInstance] logException:[NSString stringWithFormat:@"%@ must not be nil", name]];
    }
}

+ (void)checkNotNegative:(NSDecimalNumber *)value
                    name:(NSString *)name
{
    if ([value compare:[NSDecimalNumber zero]] == NSOrderedAscending) {
        [[AffirmLogger sharedInstance] logException:[NSString stringWithFormat:@"%@ must not be negative", name]];
    }
}

@end
