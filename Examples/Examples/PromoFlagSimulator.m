//
//  PromoFlagSimulator.m
//  Examples
//
//  Copyright © 2026 Affirm, Inc. All rights reserved.
//

#import "PromoFlagSimulator.h"

NSNotificationName const PromoFlagSimulatorDidDeliverResponseNotification = @"PromoFlagSimulatorDidDeliverResponse";
NSString *const PromoFlagSimulatorResponseKey = @"response";

static PromoFlagSimulation PromoFlagSimulatorCurrent = PromoFlagSimulationOff;
static BOOL PromoFlagSimulatorReportsResponses = NO;
static NSString *const PromoFlagSimulatorHandledKey = @"PromoFlagSimulatorHandled";

@interface PromoFlagSimulator ()

@property (nonatomic, strong, nullable) NSURLSessionDataTask *task;

@end

@implementation PromoFlagSimulator

+ (PromoFlagSimulation)simulation
{
    return PromoFlagSimulatorCurrent;
}

+ (void)setSimulation:(PromoFlagSimulation)simulation
{
    [self registerOnce];
    PromoFlagSimulatorCurrent = simulation;
}

+ (BOOL)reportsResponses
{
    return PromoFlagSimulatorReportsResponses;
}

+ (void)setReportsResponses:(BOOL)reportsResponses
{
    [self registerOnce];
    PromoFlagSimulatorReportsResponses = reportsResponses;
}

+ (void)registerOnce
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [NSURLProtocol registerClass:self];
    });
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    return (PromoFlagSimulatorCurrent != PromoFlagSimulationOff || PromoFlagSimulatorReportsResponses)
        && [request.URL.path containsString:@"/api/promos/v2/"]
        && [NSURLProtocol propertyForKey:PromoFlagSimulatorHandledKey inRequest:request] == nil;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    return request;
}

- (void)startLoading
{
    NSMutableURLRequest *request = [self.request mutableCopy];
    [NSURLProtocol setProperty:@YES forKey:PromoFlagSimulatorHandledKey inRequest:request];
    PromoFlagSimulation simulation = PromoFlagSimulatorCurrent;
    self.task = [[NSURLSession sharedSession] dataTaskWithRequest:request
                                                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            [self.client URLProtocol:self didFailWithError:error];
            return;
        }
        NSData *delivered = simulation == PromoFlagSimulationOff ? data : [PromoFlagSimulator rewrite:data simulation:simulation];
        [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
        [self.client URLProtocol:self didLoadData:delivered];
        [self.client URLProtocolDidFinishLoading:self];
        [PromoFlagSimulator postResponse:delivered];
    }];
    [self.task resume];
}

- (void)stopLoading
{
    [self.task cancel];
}

+ (NSData *)rewrite:(NSData *)data simulation:(PromoFlagSimulation)simulation
{
    NSMutableDictionary *json = data ? [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil] : nil;
    NSMutableDictionary *promo = [json isKindOfClass:[NSMutableDictionary class]] ? json[@"promo"] : nil;
    if (![promo isKindOfClass:[NSMutableDictionary class]]) {
        return data;
    }
    NSMutableDictionary *config = [promo[@"config"] isKindOfClass:[NSDictionary class]]
        ? [promo[@"config"] mutableCopy]
        : [NSMutableDictionary dictionary];
    if (simulation == PromoFlagSimulationFlagMissing) {
        [config removeObjectForKey:@"ios_sdk_migrate_native_to_html_render"];
    } else {
        config[@"ios_sdk_migrate_native_to_html_render"] = simulation == PromoFlagSimulationFlagOff ? @NO : @YES;
    }
    promo[@"config"] = config;

    NSString *html = [promo[@"html_ala"] isKindOfClass:[NSString class]] ? promo[@"html_ala"] : @"";
    if (simulation == PromoFlagSimulationUnsafeMarkup) {
        promo[@"html_ala"] = [@"<script>alert('script')</script>"
                              @"<img src=\"x\" onerror=\"alert('onerror')\">"
                              @"<span style=\"color:red;font-size:40px\" onclick=\"alert('click')\">[inline style removed] </span>"
                              stringByAppendingString:html];
    } else if (simulation == PromoFlagSimulationBrokenHTML) {
        promo[@"html_ala"] = @"<script>alert('nothing left after sanitizing')</script>";
    }
    return [NSJSONSerialization dataWithJSONObject:json options:0 error:nil] ?: data;
}

+ (void)postResponse:(NSData *)data
{
    id json = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
    NSData *pretty = json ? [NSJSONSerialization dataWithJSONObject:json
                                                            options:NSJSONWritingPrettyPrinted | NSJSONWritingSortedKeys | NSJSONWritingWithoutEscapingSlashes
                                                              error:nil] : nil;
    NSString *text = pretty ? [[NSString alloc] initWithData:pretty encoding:NSUTF8StringEncoding]
        : (data ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : nil);
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:PromoFlagSimulatorDidDeliverResponseNotification
                                                            object:nil
                                                          userInfo:@{PromoFlagSimulatorResponseKey: text ?: @""}];
    });
}

@end
