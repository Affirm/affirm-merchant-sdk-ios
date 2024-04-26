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

- (void)clearCookies
{
    [self.app.buttons[@"Clear Cookies"] tap];
    [self.app.buttons[@"OK"] tap];
}

- (void)testAla
{
    [self clearCookies];
    
    XCUIElement *alaElement = [self.app.buttons softMatchingWithSubstring:@"/mo"];
    [self waitForElement:alaElement duration:10];
    XCTAssertTrue(alaElement.exists);
    
    [alaElement tap];
    
    XCUIElement *checkoutElement = self.app.buttons[@"See if you qualify"];
    [self waitForElement:checkoutElement duration:15];
    XCTAssertTrue(checkoutElement.exists);
}

- (void)testBuyWithAffirm
{
    [self clearCookies];
    
    [self.app.buttons[@"Buy with Affirm"] tap];
    
    if (false) {
        XCUIElement *errorElement = self.app.staticTexts[@"Error"];
        [self waitForElement:errorElement duration:15];
        XCTAssertTrue(errorElement.exists);
        
        [self.app.buttons[@"OK"] tap];
    } else {
        XCUIElement *phoneElement = [self.app.textFields softMatchingWithSubstring:@"Mobile number"];
        [self waitForElement:phoneElement duration:10];
        XCTAssertTrue(phoneElement.exists);
    }
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
    [self clearCookies];
    
    [self.app.buttons[@"VCN Checkout"] tap];
    
    if (true) {
        XCUIElement *errorElement = self.app.staticTexts[@"Error"];
        [self waitForElement:errorElement duration:15];
        XCTAssertTrue(errorElement.exists);
        
        [self.app.buttons[@"OK"] tap];
    } else {
        XCUIElement *phoneElement = [self.app.textFields softMatchingWithSubstring:@"Mobile number"];
        [self waitForElement:phoneElement duration:15];
        XCTAssertTrue(phoneElement.exists);
    }
}

@end
