//
//  AffirmConfigurationTests.m
//  AffirmSDKTests
//
//  Created by yijie on 2019/3/20.
//  Copyright © 2019 Affirm, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "../AffirmSDK/AffirmConfiguration.h"
#import "../AffirmSDK/AffirmUtils.h"
#import "../AffirmSDK/AffirmRequest.h"

@interface AffirmConfigurationTests : XCTestCase

@end

@implementation AffirmConfigurationTests

- (void)setUp
{
    [[AffirmConfiguration sharedInstance] configureWithPublicKey:@"PKNCHBIVYOT8JSOZ" environment:AffirmEnvironmentSandbox];
}

- (void)testExamples
{
    XCTAssertEqualObjects([[AffirmConfiguration sharedInstance] environmentDescription], @"sandbox");
    XCTAssertFalse([AffirmConfiguration sharedInstance].isProductionEnvironment);
    XCTAssertEqualObjects([AffirmConfiguration sharedInstance].publicKey, @"PKNCHBIVYOT8JSOZ");
    [[AffirmConfiguration sharedInstance] configureWithPublicKey:@"OKSJJASBDJBAJBC" environment:AffirmEnvironmentProduction];
    XCTAssertEqualObjects([[AffirmConfiguration sharedInstance] environmentDescription], @"production");
    XCTAssertTrue([AffirmConfiguration sharedInstance].isProductionEnvironment);
    XCTAssertEqualObjects([AffirmConfiguration sharedInstance].publicKey, @"OKSJJASBDJBAJBC");
}

@end
