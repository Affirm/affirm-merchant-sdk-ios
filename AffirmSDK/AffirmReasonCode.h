//
//  AffirmReasonCode.h
//  AffirmSDK
//
//  Created by Amy Beall on 7/12/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AffirmReasonCode : NSObject

/**
 Reason. Required
 */
@property (nonatomic, copy, readonly, nonnull) NSString *reason;

/**
  Checkout token. Required
 */
@property (nonatomic, copy, readonly, nonnull) NSString *checkout_token;
/**
 Convenience constructor for a reason object with dictionary data.
 
 @param dict Data dictionary.
 @return The initialized reason code.
 */
+ (AffirmReasonCode *)reasonCodeWithDict: (NSDictionary *)dict
NS_SWIFT_NAME(reasonCode(dict:));

/**
 Initializer. See properties for more details.
 
 @param dict Data dictionary.
 @return The initialized reason code object.
 */
- (instancetype)initWithDict: (NSDictionary *)dict
NS_SWIFT_NAME(init(dict:));

@end

NS_ASSUME_NONNULL_END
