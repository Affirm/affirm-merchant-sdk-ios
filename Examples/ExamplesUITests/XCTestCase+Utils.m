//
//  XCTestCase+Utils.m
//  ExamplesUITests
//
//  Created by Victor Zhu on 2019/4/16.
//  Copyright © 2019 Affirm, Inc. All rights reserved.
//

#import "XCTestCase+Utils.h"

@implementation XCTestCase (Utils)

- (void)waitForDuration:(NSTimeInterval)duration
{
    XCTestExpectation *waitExpectation = [[XCTestExpectation alloc] initWithDescription:@"Waiting"];
    NSTimeInterval when = DISPATCH_TIME_NOW + duration;
    dispatch_after(when, dispatch_get_main_queue(), ^{
        [waitExpectation fulfill];
    });
    [self waitForExpectationsWithTimeout:duration handler:nil];
}

- (void)waitForElement:(XCUIElement *)element duration:(NSTimeInterval)duration
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"exists == YES"];
    [self expectationForPredicate:predicate evaluatedWithObject:element handler:nil];
    [self waitForExpectationsWithTimeout:duration handler:nil];
}

@end
