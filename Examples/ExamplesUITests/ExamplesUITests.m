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
    // The confirmation alert is presented after the promo web view reloads.
    // On a slow simulator that tap can land before the alert is in the
    // accessibility tree, so wait for it and retry the tap once if needed.
    XCUIElement *clearButton = self.app.buttons[@"Clear Cookies"];
    XCTAssertTrue([clearButton waitForExistenceWithTimeout:15]);
    
    XCUIElement *okButton = self.app.alerts.buttons[@"OK"];
    for (NSInteger attempt = 0; attempt < 2 && !okButton.exists; attempt++) {
        [clearButton tap];
        [okButton waitForExistenceWithTimeout:10];
    }
    XCTAssertTrue(okButton.exists);
    [okButton tap];
}

- (void)testAla
{
    [self clearCookies];
    
    // Affirm promo web copy changed; the CTA now contains "See" instead of "Learn more".
    XCUIElement *alaElement = [self.app.buttons softMatchingWithSubstring:@"See"];
    [self waitForElement:alaElement duration:10];
    XCTAssertTrue(alaElement.exists);
    
    [alaElement tap];
}

- (void)testBuyWithAffirm
{
    [self clearCookies];
    
    [self.app.buttons[@"Buy with Affirm"] tap];
}

- (void)testVCNCheckout
{
    [self clearCookies];
    
    [self.app.buttons[@"VCN Checkout"] tap];
    
    XCUIElement *errorElement = self.app.staticTexts[@"Error"];
    [self waitForElement:errorElement duration:15];
    XCTAssertTrue(errorElement.exists);
    
    [self.app.buttons[@"OK"] tap];
}

@end
