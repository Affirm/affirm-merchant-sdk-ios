//
//  AffirmLogger.m
//  AffirmSDK
//
//  Created by Victor Zhu on 2019/3/12.
//  Copyright © 2019 Affirm, Inc. All rights reserved.
//

#import "AffirmLogger.h"
#import "AffirmRequest.h"

@interface AffirmLogger ()

@property (nonatomic) NSInteger logCount;

@end

@implementation AffirmLogger

+ (instancetype)sharedInstance
{
    static AffirmLogger *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    return _sharedInstance;
}

- (void)logException:(NSString *)message
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:message
                                 userInfo:nil];
}

- (void)logEvent:(NSString *)name
{
    [self logEvent:name parameters:@{}];
}

- (void)logEvent:(NSString *)name parameters:(NSDictionary *)parameters
{
    if (self.enableLogPrinted) {
        NSLog(@"[%@]:\n%@", name, parameters.description);
    }
}

- (void)trackEvent:(NSString *)name
{
    [self logEvent:name parameters:@{}];
}

- (void)trackEvent:(NSString *)name parameters:(NSDictionary * _Nonnull)parameters
{
    AffirmLogRequest *logRequest = [[AffirmLogRequest alloc] initWithEventName:name
                                                               eventParameters:parameters
                                                                      logCount:self.logCount];
    [AffirmTrackerClient send:logRequest
                      handler:^(AffirmResponse * _Nullable response, NSError * _Nullable error) {
                                [[AffirmLogger sharedInstance] logEvent:[NSString stringWithFormat:@"Tracked with error: %@", error.localizedDescription]];
                            }];
    self.logCount++;
}

@end
