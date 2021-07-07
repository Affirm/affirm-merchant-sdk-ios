//
//  AffirmPromoMsgTests.m
//  AffirmSDKTests
//
//  Created by yijie on 2019/3/20.
//  Copyright © 2019 Affirm, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "../AffirmSDK/AffirmConfiguration.h"
#import "../AffirmSDK/AffirmUtils.h"
#import "../AffirmSDK/AffirmRequest.h"
#import "../AffirmSDK/AffirmDataHandler.h"
#import "../AffirmSDK/AffirmItem.h"

@interface AffirmPromoMsgTests : XCTestCase

@end

@implementation AffirmPromoMsgTests

- (void)setUp
{
    [[AffirmConfiguration sharedInstance] configureWithPublicKey:@"PKNCHBIVYOT8JSOZ" environment:AffirmEnvironmentSandbox];
}

- (void)testRequestPromoSuccess
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"start calculate price 500"];
    AffirmPromoRequest *request = [[AffirmPromoRequest alloc] initWithPublicKey:[AffirmConfiguration sharedInstance].publicKey promoId:@"promo_set_ios" amount:[NSDecimalNumber decimalNumberWithString:@"50000"] showCTA:YES pageType:nil logoType:@"text" logoColor:@"blue"];
    [AffirmCheckoutClient send:request handler:^(id<AffirmResponseProtocol>  _Nullable response, NSError * _Nonnull error) {
        XCTAssertNil(error);
        XCTAssertTrue([response isKindOfClass:[AffirmPromoResponse class]]);
        XCTAssertEqualObjects(((AffirmPromoResponse *)response).ala, @"Starting at $46/mo with Affirm. Learn more");
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:10 handler:nil];
    
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"start calculate price 100"];
    AffirmPromoRequest *request2 = [[AffirmPromoRequest alloc] initWithPublicKey:[AffirmConfiguration sharedInstance].publicKey promoId:@"promo_set_ios" amount:[NSDecimalNumber decimalNumberWithString:@"10000"] showCTA:YES pageType:nil logoType:@"text" logoColor:@"blue"];
    [AffirmCheckoutClient send:request2 handler:^(id<AffirmResponseProtocol>  _Nullable response, NSError * _Nonnull error) {
        XCTAssertNil(error);
        XCTAssertTrue([response isKindOfClass:[AffirmPromoResponse class]]);
        XCTAssertEqualObjects(((AffirmPromoResponse *)response).ala, @"Starting at $10/mo with Affirm. Learn more");
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

- (void)testDataHandler
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"start calculate price 10000"];
    NSDecimalNumber *dollarPrice = [NSDecimalNumber decimalNumberWithString:@"10000"];
    AffirmItem *item = [AffirmItem itemWithName:@"Affirm Test Item"
                                            SKU:@"test_item"
                                      unitPrice:dollarPrice
                                       quantity:1
                                            URL:[NSURL URLWithString:@"http://sandbox.affirm.com/item"]];
    
    [AffirmDataHandler getPromoMessageWithPromoID:nil
                                           amount:dollarPrice
                                            items:@[item]
                                          showCTA:YES
                                         pageType:AffirmPageTypeProduct
                                         logoType:AffirmLogoTypeName
                                        colorType:AffirmColorTypeBlueBlack
                                             font:[UIFont boldSystemFontOfSize:15]
                                        textColor:[UIColor grayColor]
                         presentingViewController:self
                                   withNavigation:YES
                                    withHtmlValue:YES
                                completionHandler:^(NSAttributedString *attributedString, NSString *html, UIViewController *viewController, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(attributedString);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

@end
