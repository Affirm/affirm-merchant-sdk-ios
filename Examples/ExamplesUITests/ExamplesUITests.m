//
//  ExamplesUITests.m
//  ExamplesUITests
//
//  Created by Victor Zhu on 2019/3/5.
//  Copyright © 2019 Affirm, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "XCTestCase+Utils.h"
#import "XCUIElementQuery+Utils.h"

@interface ExamplesUITests : XCTestCase

@property (nonatomic, strong) XCUIApplication *app;

@end

@implementation ExamplesUITests

- (void)setUp
{
    self.continueAfterFailure = NO;
    self.app = [[XCUIApplication alloc] init];
    [self.app launch];
}

- (void)testAlaData
{
    XCUIElement *alaElement = [self.app.buttons elementBoundByIndex:0];
    [self waitForElement:alaElement duration:10];
    XCTAssertTrue(alaElement.exists);

    [alaElement tap];

    XCUIElement *checkoutElement = self.app.staticTexts[@"Pay over time"];
    [self waitForElement:checkoutElement duration:10];
    XCTAssertTrue(checkoutElement.exists);
}

- (void)testAla
{
    XCUIElement *alaElement = [self.app.buttons softMatchingWithSubstring:@"Starting at"];
    [self waitForElement:alaElement duration:10];
    XCTAssertTrue(alaElement.exists);

    [alaElement tap];

    XCUIElement *checkoutElement = self.app.buttons[@"Just select Affirm at checkout."];
    [self waitForElement:checkoutElement duration:15];
    XCTAssertTrue(checkoutElement.exists);

    [checkoutElement tap];

    XCUIElement *phoneElement = self.app.textFields[@"Your mobile number"];
    [self waitForElement:phoneElement duration:10];
    XCTAssertTrue(phoneElement.exists);

    [phoneElement tap];
    [phoneElement typeText:@"3105551001"];
    [self.app.buttons[@"Done"] tap];
    [self.app.buttons[@"Continue"] tap];

    XCUIElement *pinElement = self.app.textFields[@"0000"];
    [self waitForElement:pinElement duration:5];
    XCTAssertTrue(pinElement.exists);

    [pinElement tap];
    [pinElement typeText:@"1234"];

    XCUIElement *resultElement = [self.app.staticTexts softMatchingWithSubstring:@"You're prequalified for"];
    [self waitForElement:resultElement duration:10];
    XCTAssertTrue(resultElement.exists);
}

- (void)testBuyWithAffirm
{
    [self.app.buttons[@"Buy with Affirm"] tap];

    XCUIElement *phoneElement = self.app.textFields[@"Your mobile number"];
    [self waitForElement:phoneElement duration:10];
    XCTAssertTrue(phoneElement.exists);

    [phoneElement tap];
    [phoneElement typeText:@"3105551001"];
    [self.app.buttons[@"Done"] tap];
    [self.app.buttons[@"Continue"] tap];

    XCUIElement *pinElement = self.app.textFields[@"0000"];
    [self waitForElement:pinElement duration:5];
    XCTAssertTrue(pinElement.exists);

    [pinElement tap];
    [pinElement typeText:@"1234"];

    XCUIElement *listElement = [self.app.buttons softMatchingWithSubstring:@"per month for"];
    [self waitForElement:listElement duration:10];
    XCTAssertTrue(listElement.exists);

    [listElement tap];

    XCUIElement *continueElement = self.app.buttons[@"Continue"];
    [self waitForElement:continueElement duration:15];
    XCTAssertTrue(continueElement.exists);

    [continueElement tap];
    [self.app.buttons[@"No, not now"] tap];
    [self.app.staticTexts[@"I have reviewed and agree to the"] tap];
    [self.app.staticTexts[@"Please review the following information and confirm your loan."] swipeUp];
    [self.app.buttons[@"Confirm loan"] tap];

    XCUIElement *thanksElement = self.app.staticTexts[@"Thanks for buying with Affirm!"];
    [self waitForElement:thanksElement duration:10];
    XCTAssertTrue(thanksElement.exists);
}

- (void)testFailedCheckout
{
    [self.app.buttons[@"Failed Checkout"] tap];

    XCUIElement *errorElement = self.app.staticTexts[@"Error"];
    [self waitForElement:errorElement duration:15];
    XCTAssertTrue(errorElement.exists);

    [self.app.buttons[@"OK"] tap];
}

- (void)testVCNCheckout
{
    [self.app.buttons[@"VCN Checkout"] tap];

    XCUIElement *phoneElement = self.app.textFields[@"Your mobile number"];
    [self waitForElement:phoneElement duration:10];
    XCTAssertTrue(phoneElement.exists);

    [phoneElement tap];
    [phoneElement typeText:@"3105551001"];
    [self.app.buttons[@"Done"] tap];
    [self.app.buttons[@"Continue"] tap];

    XCUIElement *pinElement = self.app.textFields[@"0000"];
    [self waitForElement:pinElement duration:5];
    XCTAssertTrue(pinElement.exists);

    [pinElement tap];
    [pinElement typeText:@"1234"];

    XCUIElement *listElement = [self.app.buttons softMatchingWithSubstring:@"per month for"];
    [self waitForElement:listElement duration:10];
    XCTAssertTrue(listElement.exists);

    [listElement tap];

    XCUIElement *continueElement = self.app.buttons[@"Continue"];
    [self waitForElement:continueElement duration:15];
    XCTAssertTrue(continueElement.exists);

    [continueElement tap];
    [self.app.buttons[@"No, not now"] tap];
    [self.app.staticTexts[@"I have reviewed and agree to the"] tap];
    [self.app.staticTexts[@"Please review the following information and confirm your loan."] swipeUp];
    [self.app.buttons[@"Confirm loan"] tap];

    XCUIElement *thanksElement = self.app.staticTexts[@"Thanks for buying with Affirm!"];
    [self waitForElement:thanksElement duration:10];
    XCTAssertTrue(thanksElement.exists);
}

@end
