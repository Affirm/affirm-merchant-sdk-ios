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

- (void)testAla
{
    XCUIElement *alaElement = [self.app.buttons softMatchingWithSubstring:@"Starting at"];
    [self waitForElement:alaElement duration:10];
    XCTAssertTrue(alaElement.exists);

    [alaElement tap];

    XCUIElement *checkoutElement = self.app.buttons[@"See if you qualify"];
    [self waitForElement:checkoutElement duration:15];
    XCTAssertTrue(checkoutElement.exists);

    [checkoutElement tap];

    XCUIElement *phoneElement = self.app.textFields[@"Mobile number"];
    [self waitForElement:phoneElement duration:10];
    XCTAssertTrue(phoneElement.exists);

    [phoneElement tap];
    [phoneElement typeText:@"3105551001"];
    [self.app.buttons[@"Done"] tap];
    [self.app.buttons[@"Continue and open modal"] tap];

    XCUIElement *pinElement = self.app.textFields[@"0000"];
    [self waitForElement:pinElement duration:5];
    XCTAssertTrue(pinElement.exists);

    [pinElement tap];
    [pinElement typeText:@"1234"];

    XCUIElement *resultElement = [self.app.staticTexts softMatchingWithSubstring:@"You're prequalified for"];
    [self waitForElement:resultElement duration:15];
    XCTAssertTrue(resultElement.exists);
}

- (void)testBuyWithAffirm
{
    [self.app.buttons[@"Buy with Affirm"] tap];

    XCUIElement *phoneElement = self.app.textFields[@"Mobile number"];
    [self waitForElement:phoneElement duration:10];
    XCTAssertTrue(phoneElement.exists);

    [phoneElement tap];
    [phoneElement typeText:@"3105551001"];
    [self.app.buttons[@"Done"] tap];
    [self.app.buttons[@"Continue and open modal"] tap];

    XCUIElement *pinElement = self.app.textFields[@"0000"];
    [self waitForElement:pinElement duration:5];
    XCTAssertTrue(pinElement.exists);

    [pinElement tap];
    [pinElement typeText:@"1234"];

    XCUIElement *listElement = [self.app.buttons softMatchingWithSubstring:@"month 3 months APR"];
    [self waitForElement:listElement duration:20];
    XCTAssertTrue(listElement.exists);

    [listElement tap];
    
    XCUIElement *switchElement = self.app.switches[@"Auto-Pay Enabled"];
    [self waitForElement:switchElement duration:15];
    XCTAssertTrue(switchElement.exists);
    
    [switchElement tap];

    XCUIElement *continueElement = self.app.buttons[@"Continue"];
    XCTAssertTrue(continueElement.exists);
    [continueElement tap];
    
    XCUIElement *reviewedElement = self.app.staticTexts[@"I have reviewed and agree to the"];
    [self waitForElement:reviewedElement duration:5];
    XCTAssertTrue(reviewedElement.exists);
    [reviewedElement tap];
    
    [self.app.buttons[@"Confirm purchase, you will be redirected back to the merchant when it is complete."] tap];

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
    
    if (true) {
        XCUIElement *errorElement = self.app.staticTexts[@"Error"];
        [self waitForElement:errorElement duration:15];
        XCTAssertTrue(errorElement.exists);

        [self.app.buttons[@"OK"] tap];
    } else {
        XCUIElement *phoneElement = self.app.textFields[@"Mobile number"];
        [self waitForElement:phoneElement duration:15];
        XCTAssertTrue(phoneElement.exists);

        [phoneElement tap];
        [phoneElement typeText:@"3105551001"];
        [self.app.buttons[@"Done"] tap];
        [self.app.buttons[@"Continue and open modal"] tap];

        XCUIElement *pinElement = self.app.textFields[@"0000"];
        [self waitForElement:pinElement duration:5];
        XCTAssertTrue(pinElement.exists);

        [pinElement tap];
        [pinElement typeText:@"1234"];

        XCUIElement *listElement = [self.app.buttons softMatchingWithSubstring:@"month 3 months APR"];
        [self waitForElement:listElement duration:20];
        XCTAssertTrue(listElement.exists);

        [listElement tap];

        XCUIElement *review = self.app.staticTexts[@"Review your payment plan"];
         [self waitForElement:review duration:10];
         XCTAssertTrue(review.exists);
         [review swipeUp];
    }
}

@end
