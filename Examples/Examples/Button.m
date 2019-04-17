//
//  Button.m
//  Examples
//
//  Created by Victor Zhu on 2019/4/8.
//  Copyright © 2019 Affirm, Inc. All rights reserved.
//

#import "Button.h"

@implementation Button

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    [UIView animateWithDuration:0.2 animations:^{
        self.titleLabel.layer.backgroundColor = highlighted ? self.tintColor.CGColor : [UIColor clearColor].CGColor;
    }];
}

@end
