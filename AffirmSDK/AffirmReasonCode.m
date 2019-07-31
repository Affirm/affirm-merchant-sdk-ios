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
    
    if (self = [super init]) {
        _reason = dict[@"reason"];
    }
    return self;
}

@end
