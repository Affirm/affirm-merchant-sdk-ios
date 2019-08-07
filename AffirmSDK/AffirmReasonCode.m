//
//  AffirmReasonCode.m
//  AffirmSDK
//
//  Created by Amy Beall on 7/12/19.
//
#import "AffirmUtils.h"
#import "AffirmReasonCode.h"

@implementation AffirmReasonCode

+ (AffirmReasonCode *)reasonCodeWithDict:(NSDictionary *)dict
{
    return [[self alloc] initWithDict:dict];
}

- (instancetype)initWithDict:(NSDictionary *)dict
{
    [AffirmValidationUtils checkNotNil:dict[@"reason"] name:@"reason"];
    [AffirmValidationUtils checkNotNil:dict[@"checkout_token"] name:@"checkout_token"];
    
    if (self = [super init]) {
        _reason = dict[@"reason"];
        _checkout_token = dict[@"checkout_token"];
    }
    return self;
}

@end
