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
    [AffirmTrackerClient send:request handler:^(AffirmResponse * _Nullable response, NSError * _Nullable error) {
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

- (void)testErrorResponseUI
{
    NSString *jsonString = @"{\"status_code\":400,\"type\":\"invalid_request\",\"code\":\"no-eligible-financing-program\",\"field\":\"total\",\"message\":\"Invalid Request\",\"ui\":{\"main\":\"We can't offer financing\",\"sub\":\"Try a different amount\",\"sub_extra\":[\"extra one\",\"extra two\"]}}";
    AffirmResponse *response = [AffirmErrorResponse parseError:[jsonString dataUsingEncoding:NSUTF8StringEncoding]];
    XCTAssertTrue([response isKindOfClass:[AffirmErrorResponse class]]);
    
    AffirmErrorResponse *errorResponse = (AffirmErrorResponse *)response;
    XCTAssertEqualObjects(errorResponse.message, @"Invalid Request");
    XCTAssertEqualObjects(errorResponse.code, @"no-eligible-financing-program");
    XCTAssertEqualObjects(errorResponse.field, @"total");
    XCTAssertEqualObjects(errorResponse.type, @"invalid_request");
    XCTAssertEqualObjects(errorResponse.statusCode, @400);
    XCTAssertEqualObjects(errorResponse.ui.main, @"We can't offer financing");
    XCTAssertEqualObjects(errorResponse.ui.sub, @"Try a different amount");
    XCTAssertEqualObjects(errorResponse.ui.subExtra, (@[@"extra one", @"extra two"]));
    XCTAssertEqualObjects([errorResponse.ui dictionary], (@{@"main": @"We can't offer financing",
                                                            @"sub": @"Try a different amount",
                                                            @"sub_extra": @[@"extra one", @"extra two"]}));
    XCTAssertEqualObjects([errorResponse dictionary][@"ui"], [errorResponse.ui dictionary]);
}

- (void)testErrorResponseUIRejectsNonStringValues
{
    NSString *jsonString = @"{\"message\":{\"unexpected\":true},\"status_code\":\"400\",\"ui\":{\"main\":1,\"sub\":false,\"sub_extra\":[\"ok\", 2]}}";
    AffirmResponse *response = [AffirmErrorResponse parseError:[jsonString dataUsingEncoding:NSUTF8StringEncoding]];
    AffirmErrorResponse *errorResponse = (AffirmErrorResponse *)response;
    XCTAssertEqualObjects(errorResponse.message, @"");
    XCTAssertEqualObjects(errorResponse.statusCode, @(-1));
    XCTAssertNil(errorResponse.ui.main);
    XCTAssertNil(errorResponse.ui.sub);
    XCTAssertNil(errorResponse.ui.subExtra);
}

- (void)testErrorResponseWithoutUI
{
    NSString *jsonString = @"{\"status_code\":400,\"type\":\"invalid_request\",\"message\":\"Invalid Request: Must be valid Amount\"}";
    AffirmResponse *response = [AffirmErrorResponse parseError:[jsonString dataUsingEncoding:NSUTF8StringEncoding]];
    AffirmErrorResponse *errorResponse = (AffirmErrorResponse *)response;
    XCTAssertEqualObjects(errorResponse.message, @"Invalid Request: Must be valid Amount");
    XCTAssertEqualObjects(errorResponse.code, @"");
    XCTAssertNil(errorResponse.ui);
    XCTAssertNil([errorResponse dictionary][@"ui"]);
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
