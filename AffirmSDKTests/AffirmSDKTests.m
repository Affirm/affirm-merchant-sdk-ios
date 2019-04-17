//
//  AffirmSDKTests.m
//  AffirmSDKTests
//
//  Created by Victor Zhu on 2019/3/4.
//  Copyright © 2019 Affirm, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "AffirmConfiguration.h"
#import "AffirmUtils.h"
#import "AffirmRequest.h"

@interface AffirmSDKTests : XCTestCase

@end

@implementation AffirmSDKTests

- (void)setUp
{
    [[AffirmConfiguration sharedInstance] configureWithPublicKey:@"PKNCHBIVYOT8JSOZ" environment:AffirmEnvironmentSandbox];
}

- (void)testTracker
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"track test"];
    AffirmLogRequest *request = [[AffirmLogRequest alloc] initWithEventName:@"Test" eventParameters:@{} logCount:0];
    [AffirmTrackerClient send:request
                      handler:^(id<AffirmResponseProtocol>  _Nullable response, NSError * _Nonnull error) {
                          XCTAssertNil(error);
                          [expectation fulfill];
                      }];
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)testUtil
{
    NSDictionary *someParams = @{
                                 @"amount": @(30000),
                                 @"publicKey": @"PKNCHBIVYOT8JSOZ",
                                 @"is_sdk": @"true"
                                 };
    
    XCTAssertEqualObjects([someParams queryURLEncoding], @"amount=30000&publicKey=PKNCHBIVYOT8JSOZ&is_sdk=true");
    XCTAssertNotNil([NSBundle sdkBundle]);
    XCTAssertNotNil([NSBundle resourceBundle]);
    XCTAssertEqualObjects([[NSDecimalNumber decimalNumberWithString:@"500"] toIntegerCents], @(50000));
    
    NSString *jsonString = @"{\"number\":\"40012959709\",\"callback_id\":\"4DACF-ASBJ-WEAS-GBNZ\",\"date\":\"2018-09-12\"}";
    XCTAssertEqualObjects([jsonString convertToDictionary][@"number"], @"40012959709");
    XCTAssertEqualObjects([jsonString convertToDictionary][@"callback_id"], @"4DACF-ASBJ-WEAS-GBNZ");
    XCTAssertEqualObjects([jsonString convertToDictionary][@"date"], @"2018-09-12");
    
    NSString *jsonStringError = @"{\"number\":\"40012959709,\"callback_id\":\"4DACF-ASBJ-WEAS-GBNZ\",\"date\":\"2018-09-12\"}";
    XCTAssertNil([jsonStringError convertToDictionary]);
}

@end
