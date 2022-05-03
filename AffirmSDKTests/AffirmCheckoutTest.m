//
//  AffirmCheckoutTest.m
//  AffirmSDKTests
//
//  Created by Paul on 3/21/19.
//  Copyright © 2019 Affirm, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "../AffirmSDK/AffirmConfiguration.h"
#import "../AffirmSDK/AffirmCheckout.h"
#import "../AffirmSDK/AffirmItem.h"
#import "../AffirmSDK/AffirmShippingDetail.h"
#import "../AffirmSDK/AffirmDiscount.h"
#import "../AffirmSDK/AffirmUtils.h"
#import "../AffirmSDK/AffirmRequest.h"
#import "../AffirmSDK/AffirmClient.h"

@interface AffirmCheckoutTest : XCTestCase

@property (nonatomic, strong) AffirmItem *item;
@property (nonatomic, strong) AffirmShippingDetail *shipping;
@property (nonatomic, strong) AffirmDiscount *discount;
@property (nonatomic, strong) AffirmCheckout *checkout;

@end

@implementation AffirmCheckoutTest

- (void)setUp
{
    self.continueAfterFailure = NO;
    _item = [AffirmItem itemWithName:@"Affirm Test Item" SKU:@"test_item" unitPrice:[NSDecimalNumber decimalNumberWithString:@"15.00"] quantity:1 URL:[NSURL URLWithString:@"http://sandbox.affirm.com/item"]];
    _shipping = [AffirmShippingDetail shippingDetailWithName:@"Test Tester" addressWithLine1:@"325 Pacific Ave." line2:@"" city:@"San Francisco" state:@"CA" zipCode:@"94111" countryCode:@"USA"];
    _discount = [AffirmDiscount discountWithName:@"Affirm Test Discount" amount:[NSDecimalNumber decimalNumberWithString:@"3.00"]];
    _checkout = [AffirmCheckout checkoutWithItems:@[_item] shipping:_shipping taxAmount:[NSDecimalNumber decimalNumberWithString:@"1.00"] shippingAmount:[NSDecimalNumber decimalNumberWithString:@"5.00"]];
}

- (void)testAffirmItem {
    NSDictionary *item = @{
                           @"display_name": @"Affirm Test Item",
                           @"sku": @"test_item",
                           @"unit_price": @1500,
                           @"qty": @1,
                           @"item_url": @"http://sandbox.affirm.com/item"
                           };
    XCTAssertEqualObjects([_item toJSONDictionary], item);
}

- (void)testAffirmDiscount
{
    NSDictionary *discount = @{
                               @"discount_display_name": @"Affirm Test Discount",
                               @"discount_amount": @300
                               };
    XCTAssertEqualObjects([_discount toJSONDictionary], discount);
}

- (void)testCheckoutSuccessCase
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"checkout response error format"];
    [[AffirmConfiguration sharedInstance] configureWithPublicKey:@"2G9MNM7462PB1TAV"
                                                     environment:AffirmEnvironmentSandbox
                                                    merchantName:@"Affirm Example"];
    AffirmCheckoutRequest *request = [[AffirmCheckoutRequest alloc] initWithPublicKey:[AffirmConfiguration sharedInstance].publicKey
                                                                             checkout:self.checkout
                                                                               useVCN:NO cardAuthWindow:0];
    [AffirmCheckoutClient send:request handler:^(AffirmResponse *  _Nullable response, NSError * _Nonnull error) {
        XCTAssertTrue([response isKindOfClass:[AffirmCheckoutResponse class]]);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)testCheckoutFailedCase
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"checkout response error format"];
    NSDecimalNumber *dollarPrice = [NSDecimalNumber decimalNumberWithString:@"500"];
    AffirmItem *item = [AffirmItem itemWithName:@"Affirm Test Item" SKU:@"test_item" unitPrice:dollarPrice quantity:1 URL:[NSURL URLWithString:@"http://sandbox.affirm.com/item"]];
    AffirmShippingDetail *shipping = [AffirmShippingDetail shippingDetailWithName:@"Test Tester" email:@"testtester@test.com" phoneNumber:@"1111111111" addressWithLine1:@"633 Folsom Street" line2:@"" city:@"San Francisco" state:@"CA" zipCode:@"94107" countryCode:@"USA"];
    AffirmCheckout *checkout = [AffirmCheckout checkoutWithItems:@[item] shipping:shipping payoutAmount:[dollarPrice toIntegerCents]];
    [[AffirmConfiguration sharedInstance] configureWithPublicKey:@"2G9MNM7462PB1TAV"
                                                     environment:AffirmEnvironmentSandbox
                                                    merchantName:@"Affirm Example"];
    AffirmCheckoutRequest *request = [[AffirmCheckoutRequest alloc] initWithPublicKey:[AffirmConfiguration sharedInstance].publicKey
                                                                             checkout:checkout
                                                                               useVCN:NO cardAuthWindow:0];
    [AffirmCheckoutClient send:request handler:^(AffirmResponse *  _Nullable response, NSError * _Nonnull error) {
        XCTAssertTrue([response isKindOfClass:[AffirmErrorResponse class]]);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

@end
