//
//  XCUIElementQuery+Utils.m
//  ExamplesUITests
//
//  Created by Victor Zhu on 2019/4/16.
//  Copyright © 2019 Affirm, Inc. All rights reserved.
//

#import "XCUIElementQuery+Utils.h"

@implementation XCUIElementQuery (Utils)

- (XCUIElement *)softMatchingWithSubstring:(NSString *)substring
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"label CONTAINS[cd] %@", substring];
    return [self elementMatchingPredicate:predicate].firstMatch;
}

@end
