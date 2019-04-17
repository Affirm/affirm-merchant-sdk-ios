//
//  AffirmUtils.h
//  AffirmSDK
//
//  Created by Victor Zhu on 2019/3/4.
//  Copyright © 2019 Affirm, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

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

@end

@interface NSDecimalNumber (Utils)

- (NSDecimalNumber *)toIntegerCents;

@end

@interface AffirmValidationUtils : NSObject

+ (void)checkNotNil:(id)value
               name:(NSString *)name;

+ (void)checkNotNegative:(NSDecimalNumber *)value
                    name:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
