//
//  AffirmSDKTests.m
//  AffirmSDKTests
//
//  Created by Victor Zhu on 2019/3/4.
//  Copyright © 2019 Affirm, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "../AffirmSDK/AffirmConfiguration.h"
#import "../AffirmSDK/AffirmUtils.h"
#import "../AffirmSDK/AffirmRequest.h"
#import "../AffirmSDK/AffirmCardValidator.h"

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

- (void)testVisaCard
{
    AffirmBrand *brand = [[AffirmCardValidator sharedCardValidator] brandForCardNumber:@"4242 4242 4242 4242"];
    XCTAssertEqual(brand.type, AffirmBrandTypeVisa);
}

- (void)testMasterCard
{
    AffirmBrand *brand = [[AffirmCardValidator sharedCardValidator] brandForCardNumber:@"5555555555554444"];
    XCTAssertEqual(brand.type, AffirmBrandTypeMastercard);
}

- (void)testAmericanExpress
{
    AffirmBrand *brand = [[AffirmCardValidator sharedCardValidator] brandForCardNumber:@"378282246310005"];
    XCTAssertEqual(brand.type, AffirmBrandTypeAmex);
}

- (void)testDiscover
{
    AffirmBrand *brand = [[AffirmCardValidator sharedCardValidator] brandForCardNumber:@"6011111111111117"];
    XCTAssertEqual(brand.type, AffirmBrandTypeDiscover);
}

- (void)testDinersClub
{
    AffirmBrand *brand = [[AffirmCardValidator sharedCardValidator] brandForCardNumber:@"3056930009020004"];
    XCTAssertEqual(brand.type, AffirmBrandTypeDinersClub);
}

- (void)testJCB
{
    AffirmBrand *brand = [[AffirmCardValidator sharedCardValidator] brandForCardNumber:@"3566002020360505"];
    XCTAssertEqual(brand.type, AffirmBrandTypeJCB);
}

@end
