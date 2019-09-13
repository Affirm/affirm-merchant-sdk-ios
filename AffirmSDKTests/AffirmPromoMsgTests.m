//
//  AffirmPromoMsgTests.m
//  AffirmSDKTests
//
//  Created by yijie on 2019/3/20.
//  Copyright © 2019 Affirm, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "AffirmConfiguration.h"
#import "AffirmUtils.h"
#import "AffirmRequest.h"

@interface AffirmPromoMsgTests : XCTestCase

@end

@implementation AffirmPromoMsgTests

- (void)setUp
{
    [[AffirmConfiguration sharedInstance] configureWithPublicKey:@"PKNCHBIVYOT8JSOZ" environment:AffirmEnvironmentSandbox];
}

- (void)testCalculatePrice
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"start calculate price 500"];
    AffirmPromoRequest *request = [[AffirmPromoRequest alloc] initWithPublicKey:[AffirmConfiguration sharedInstance].publicKey promoId:@"promo_set_ios" amount:[NSDecimalNumber decimalNumberWithString:@"50000"] showCTA:YES pageType:nil logoType:@"text" logoColor:@"blue"];
    [AffirmCheckoutClient send:request handler:^(id<AffirmResponseProtocol>  _Nullable response, NSError * _Nonnull error) {
        XCTAssertNil(error);
        XCTAssertTrue([response isKindOfClass:[AffirmPromoResponse class]]);
        XCTAssertEqualObjects(((AffirmPromoResponse *)response).ala, @"Starting at $44/mo with Affirm. Learn more");
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:10 handler:nil];
    
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"start calculate price 100"];
    AffirmPromoRequest *request2 = [[AffirmPromoRequest alloc] initWithPublicKey:[AffirmConfiguration sharedInstance].publicKey promoId:@"promo_set_ios" amount:[NSDecimalNumber decimalNumberWithString:@"10000"] showCTA:YES pageType:nil logoType:@"text" logoColor:@"blue"];
    [AffirmCheckoutClient send:request2 handler:^(id<AffirmResponseProtocol>  _Nullable response, NSError * _Nonnull error) {
        XCTAssertNil(error);
        XCTAssertTrue([response isKindOfClass:[AffirmPromoResponse class]]);
        XCTAssertEqualObjects(((AffirmPromoResponse *)response).ala, @"Starting at $9/mo with Affirm. Learn more");
        [expectation2 fulfill];
    }];
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)testRequestPromoFailed
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"start calculate price 50000"];
    AffirmPromoRequest *request = [[AffirmPromoRequest alloc] initWithPublicKey:[AffirmConfiguration sharedInstance].publicKey promoId:@"promo_set_ios" amount:[NSDecimalNumber decimalNumberWithString:@"5000000"] showCTA:YES pageType:nil logoType:@"text" logoColor:@"blue"];
    [AffirmCheckoutClient send:request handler:^(id<AffirmResponseProtocol>  _Nullable response, NSError * _Nonnull error) {
        XCTAssertNil(error);
        XCTAssertNotNil(response);
        XCTAssertFalse([response isKindOfClass:[AffirmPromoResponse class]]);
        XCTAssertTrue([response isKindOfClass:[AffirmErrorResponse class]]);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

@end
