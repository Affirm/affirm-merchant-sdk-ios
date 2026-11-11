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

// This class is selected only by the Thor-backed workflow dispatch. Ordinary
// sandbox UI coverage above keeps its existing behavior.
@interface LivePromoThorTests : XCTestCase
@end
@implementation LivePromoThorTests
- (void)testRendersPromoFromLiveThor
{
    self.continueAfterFailure = NO;
    NSDictionary *inputs = [[NSProcessInfo processInfo] environment];
    NSString *url = inputs[@"AFFIRM_PROMO_BASE_URL"];
    NSString *key = inputs[@"AFFIRM_PUBLIC_KEY"];
    NSString *expected = inputs[@"AFFIRM_EXPECTED_PROMO_TEXT"];
    XCTAssertTrue(url.length > 0 && key.length > 0 && expected.length > 0,
                  @"The live SDK test requires Thor URL, public key and expected text");
    NSURL *thor = [NSURL URLWithString:url];
    XCTAssertEqualObjects(thor.scheme, @"https");
    XCTAssertTrue([thor.host hasSuffix:@".affirm-thor.com"]);
    XCUIApplication *app = [[XCUIApplication alloc] init];
    app.launchEnvironment = @{@"AFFIRM_PROMO_BASE_URL": url,
                              @"AFFIRM_PUBLIC_KEY": key,
                              @"AFFIRM_EXPECTED_PROMO_TEXT": expected};
    [app launch];
    XCUIElement *promo = app.buttons[@"affirm_live_promo_native_button"];
    NSPredicate *rendered = [NSPredicate predicateWithFormat:@"exists == YES AND label CONTAINS %@", expected];
    XCTNSPredicateExpectation *expectation = [[XCTNSPredicateExpectation alloc] initWithPredicate:rendered object:promo];
    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[expectation] timeout:30];
    NSLog(@"Live Thor promo hierarchy: %@", app.debugDescription);
    XCTAttachment *screenshot = [XCTAttachment attachmentWithScreenshot:[app screenshot]];
    screenshot.name = @"live-thor-promo";
    screenshot.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:screenshot];
    XCTAssertEqual(result, XCTWaiterResultCompleted, @"The native promo must render expected text %@; actual %@", expected, promo.label);
    XCTAssertTrue([promo.label containsString:expected]);
    [app terminate];
}
@end
