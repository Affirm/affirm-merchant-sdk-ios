//
//  XCUIElementQuery+Utils.h
//  ExamplesUITests
//
//  Created by Victor Zhu on 2019/4/16.
//  Copyright © 2019 Affirm, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

NS_ASSUME_NONNULL_BEGIN

@interface XCUIElementQuery (Utils)

- (XCUIElement *)softMatchingWithSubstring:(NSString *)substring;

@end

NS_ASSUME_NONNULL_END
