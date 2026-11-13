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
    // CI simulators can take longer than the 5 s HTML budget just to start a promo web view.
    self.app.launchArguments = @[@"-AffirmPromoHTMLTimeoutSeconds", @"30"];
    [self.app launch];
}

- (void)clearCookies
{
    // The confirmation alert is presented after the promo web view reloads.
    // On a slow simulator that tap can land before the alert is in the
    // accessibility tree, so wait for it and retry the tap if needed.
    XCUIElement *clearButton = self.app.buttons[@"Clear Cookies"];
    XCTAssertTrue([clearButton waitForExistenceWithTimeout:15]);
    
    XCUIElement *okButton = self.app.alerts.buttons[@"OK"];
    for (NSInteger attempt = 0; attempt < 3 && !okButton.exists; attempt++) {
        [clearButton tap];
        [okButton waitForExistenceWithTimeout:20];
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

- (XCUIElement *)waitForStatus:(NSString *)text
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"label CONTAINS %@", text];
    XCUIElement *status = [[self.app.staticTexts matchingPredicate:predicate] firstMatch];
    // Longer than the 30 s HTML budget, so a slow render ends before the wait does.
    if (![status waitForExistenceWithTimeout:45]) {
        [self attachScreenshotNamed:[@"missing " stringByAppendingString:text]];
        XCTFail(@"No status containing \"%@\" in:\n%@", text, self.app.debugDescription);
    }
    return status;
}

- (void)attachScreenshotNamed:(NSString *)name
{
    XCTAttachment *attachment = [XCTAttachment attachmentWithScreenshot:[XCUIScreen mainScreen].screenshot];
    attachment.name = name;
    attachment.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:attachment];
}

- (void)testRenderMigrationDemo
{
    [self.app.buttons[@"Native → HTML render demo"] tap];

    // Flag on: the native API call is shown as HTML; explicit HTML is HTML either way.
    [self waitForStatus:@"Decision: flag_true"];
    [self waitForStatus:@"Shown as: HTML (T2)"];
    [self waitForStatus:@"Decision: explicit_html"];
    [self attachScreenshotNamed:@"1-flag-on"];

    [self.app.buttons[@"Serif italic"] tap];
    [self.app.buttons[@"Indigo"] tap];
    [self waitForStatus:@"Decision: flag_true"];
    [self attachScreenshotNamed:@"2-serif-italic-indigo"];

    [self.app.buttons[@"Avenir"] tap];
    [self waitForStatus:@"Decision: unsupported_font"];
    [self attachScreenshotNamed:@"3-unsupported-font"];
    [self.app.buttons[@"System"] tap];

    [self.app.buttons[@"Unsafe"] tap];
    [self waitForStatus:@"Decision: flag_true"];
    [self attachScreenshotNamed:@"4-unsafe-markup"];

    [self.app.buttons[@"HTML fails"] tap];
    [self waitForStatus:@"native text, after the HTML failed (T3)"];
    [self waitForStatus:@"hidden, HTML failed (T5)"];
    [self attachScreenshotNamed:@"5-html-fails"];

    [self.app.buttons[@"Flag on"] tap];
    [self.app.switches.firstMatch tap];
    [self waitForStatus:@"Decision: opt_out"];
    [self attachScreenshotNamed:@"6-opt-out"];
    [self.app.switches.firstMatch tap];

    [self.app.buttons[@"As is"] tap];
    [self waitForStatus:@"Decision: flag_missing"];
    [self attachScreenshotNamed:@"7-server-as-is"];
}

- (void)testPromoTableDemo
{
    // Accessibility snapshots create a cell, and start a web view, for all 100 rows. CI simulators
    // are too slow for that: the UI queries themselves time out. Run this test locally.
    XCTSkipIf(NSProcessInfo.processInfo.environment[@"CI"] != nil, @"Too slow on CI simulators");

    [self.app.buttons[@"Promos in a table view"] tap];

    // This test covers reuse, not HTML success (testRenderMigrationDemo does); any finished
    // render, HTML or the native fallback, is enough here.
    [self waitForStatus:@"Shown as "];
    [self attachScreenshotNamed:@"table-1-first-screen"];

    XCUIElement *table = self.app.tables.firstMatch;
    for (NSInteger i = 0; i < 6; i++) {
        [table swipeUp];
    }
    // Cells scrolled off screen came back for new rows, each showing its own amount.
    [self waitForStatus:@"reused"];
    NSPredicate *reused = [NSPredicate predicateWithFormat:@"label MATCHES %@", @"(?s).*Reused: [1-9].*"];
    XCTAssertTrue([[[self.app.staticTexts matchingPredicate:reused] firstMatch] waitForExistenceWithTimeout:5]);
    [self waitForStatus:@"Shown as "];
    [self attachScreenshotNamed:@"table-2-after-scrolling"];

    [self.app.buttons[@"Native"] tap];
    [self waitForStatus:@"Shown as native text (T1)"];
    [self attachScreenshotNamed:@"table-3-native"];
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
