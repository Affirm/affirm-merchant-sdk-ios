//
//  AffirmClient.m
//  AffirmSDK
//
//  Created by Victor Zhu on 2019/3/18.
//  Copyright © 2019 Affirm, Inc. All rights reserved.
//

#import "AffirmClient.h"
#import "AffirmConstants.h"
#import "AffirmProtocol.h"
#import "AffirmRequest.h"
#import "AffirmLogger.h"
#import "AffirmConfiguration.h"
#import "AffirmUtils.h"

@defs(AffirmRequestProtocol)

- (NSString *)path
{
    [[AffirmLogger sharedInstance] logException:@"path required"];
    return nil;
}

- (AffirmHTTPMethod)method
{
    return AffirmHTTPMethodGET;
}

- (NSDictionary *)headers
{
    return @{@"Content-Type": @"application/json",
             @"Affirm-User-Agent": @"Affirm-iOS-SDK",
             @"Affirm-User-Agent-Version": [AffirmConfiguration affirmSDKVersion]};
}

- (NSDictionary *)parameters
{
    return nil;
}

- (Class)responseClass
{
    [[AffirmLogger sharedInstance] logEvent:@"responseClass is not overridden, but is not required"];
    return nil;
}

@end

@defs(AffirmResponseProtocol)

+ (id <AffirmResponseProtocol>)parse:(NSData *)data
{
    [[AffirmLogger sharedInstance] logException:@"parse method require override"];
    return nil;
}

+ (nullable id <AffirmResponseProtocol>)parseError:(NSData *)data
{
    NSError *error = nil;
    id responseObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    if (responseObject == nil) {
        return nil;
    }
    NSString *field = [responseObject valueForKey:@"field"];
    NSString *message = [responseObject valueForKey:@"message"];
    NSString *code = [responseObject valueForKey:@"code"];
    NSString *type = [responseObject valueForKey:@"type"];
    NSNumber *statusCode = [responseObject valueForKey:@"status_code"];
    return [[AffirmErrorResponse alloc] initWithField:field message:message code:code type:type statusCode:statusCode];
}

@end

@defs(AffirmClientProtocol)

+ (NSString *)host
{
    [[AffirmLogger sharedInstance] logException:@"host required"];
    return nil;
}

+ (void)send:(id <AffirmRequestProtocol>)request handler:(AffirmRequestHandler)handler
{
    NSString *method;
    NSURL *url;
    switch (request.method) {
        case AffirmHTTPMethodGET:
            method = @"GET";
            url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@?%@", [self host], request.path, [request.parameters queryURLEncoding]]];
            break;
        case AffirmHTTPMethodPOST:
            method = @"POST";
            url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", [self host], request.path]];
            break;
    }
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
    urlRequest.HTTPMethod = method;

    NSDictionary *headers = request.headers;
    for (NSString *key in headers) {
        [urlRequest setValue:headers[key] forHTTPHeaderField:key];
    }
    if (request.parameters && [NSJSONSerialization isValidJSONObject:request.parameters] && request.method == AffirmHTTPMethodPOST) {
        urlRequest.HTTPBody = [NSJSONSerialization dataWithJSONObject:request.parameters options:NSJSONWritingPrettyPrinted error:nil];
    }

    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:urlRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (handler) {
            NSHTTPURLResponse *result = (NSHTTPURLResponse *)response;
            if (data && request.responseClass != nil) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (result.statusCode == 200 && [request.responseClass respondsToSelector:@selector(parse:)]) {
                        id response = [request.responseClass performSelector:@selector(parse:) withObject:data];
                        handler(response, error);
                    } else {
                        id response = [request.responseClass performSelector:@selector(parseError:) withObject:data];
                        if (response) {
                            handler(response, error);
                        } else {
                            handler(nil, [@{NSLocalizedDescriptionKey: @"Couldn't parse response."} convertToNSErrorWithCode:@(result.statusCode)]);
                        }
                    }
                });
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    handler(nil, error);
                });
            }
        }
    }];
    [task resume];
}

@end

@implementation AffirmTrackerClient

+ (NSString *)host
{
    return @"https://tracker.affirm.com";
}

@end

@implementation AffirmCheckoutClient

+ (NSString *)host
{
    return [AffirmConfiguration sharedInstance].isProductionEnvironment ? @"https://api.affirm.com" : @"https://sandbox.affirm.com";
}

@end

