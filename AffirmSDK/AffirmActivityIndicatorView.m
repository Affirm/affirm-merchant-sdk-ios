//
//  AffirmActivityIndicatorView.m
//  AffirmSDK
//
//  Created by yijie on 2019/3/19.
//  Copyright © 2019 Affirm, Inc. All rights reserved.
//

#import "AffirmActivityIndicatorView.h"

@interface AffirmActivityIndicatorView()

@property (nonatomic, strong) CAShapeLayer *progressLayer;

@end

@implementation AffirmActivityIndicatorView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.hidden = YES;
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    [self.backgroundTintColor ?: [UIColor colorWithRed:246/255.0 green:248/255.0 blue:252/255.0 alpha:1.0] setStroke];
    CGContextAddArc(context, 40, 40, 30, 0, M_PI * 2, 0);
    CGContextSetLineWidth(context, self.lineWidth ?: 1.5);
    CGContextStrokePath(context);
}

- (void)startAnimating
{
    if (self.isAnimating) {
        return;
    }

    if (self.progressLayer.superlayer == nil) {
        [self.layer addSublayer:self.progressLayer];
    }
    self.alpha = 1;
    self.hidden = NO;

    CABasicAnimation *animationStrokeStart = [CABasicAnimation animationWithKeyPath:@"strokeStart"];
    animationStrokeStart.beginTime = 0.5;
    animationStrokeStart.fromValue = @(0);
    animationStrokeStart.toValue = @(1);
    animationStrokeStart.duration = 1;
    animationStrokeStart.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    
    CABasicAnimation *animationStrokeEnd = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    animationStrokeEnd.fromValue = @(0);
    animationStrokeEnd.toValue = @(1);
    animationStrokeEnd.duration = 1;
    animationStrokeEnd.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    
    CABasicAnimation *animationZ = [[CABasicAnimation alloc] init];
    animationZ.keyPath = @"transform.rotation.z";
    animationZ.fromValue = @(0);
    animationZ.toValue = @(2 * M_PI);
    
    CAAnimationGroup *group = [CAAnimationGroup animation];
    group.duration = 1.5;
    group.animations = @[animationStrokeStart, animationStrokeEnd, animationZ];
    group.repeatCount = INFINITY;
    group.removedOnCompletion = NO;
    group.fillMode = kCAFillModeForwards;
    
    [self.progressLayer addAnimation:group forKey:@"progressAnimation"];
    self.isAnimating = YES;
}

- (void)stopAnimating
{
    if (!self.isAnimating) {
        return;
    }

    [UIView animateWithDuration:0.25 animations:^{
        self.alpha = 0;
    } completion:^(BOOL finished) {
        self.hidden = YES;
        [self.progressLayer removeAllAnimations];
        self.isAnimating = NO;
    }];
}

- (CAShapeLayer *)progressLayer
{
    if (!_progressLayer) {
        _progressLayer = [CAShapeLayer layer];
        _progressLayer.frame = CGRectMake(10, 10, 60, 60);
        _progressLayer.fillColor = [UIColor clearColor].CGColor;
        _progressLayer.strokeColor = (self.progressTintColor ?: [UIColor colorWithRed:16/255.0 green:160/255.0 blue:234/255.0 alpha:1.0]).CGColor;
        _progressLayer.lineWidth = self.lineWidth ?: 1.5;
        UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(30, 30)
                                                            radius:30
                                                        startAngle:0
                                                          endAngle:2 * M_PI
                                                         clockwise:YES];
        _progressLayer.path = path.CGPath;
    }
    return _progressLayer;
}

@end
