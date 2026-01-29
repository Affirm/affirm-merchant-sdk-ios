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
    
    XCUIElement *alaElement = [self.app.buttons softMatchingWithSubstring:@"Learn more"];
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
