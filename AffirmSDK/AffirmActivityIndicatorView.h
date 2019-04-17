//
//  AffirmActivityIndicatorView.h
//  AffirmSDK
//
//  Created by yijie on 2019/3/19.
//  Copyright © 2019 Affirm, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 An AffirmActivityIndicator represents a loading state by displaying a loading spinner on the screen.
 */
@interface AffirmActivityIndicatorView : UIView

/**
 The color of the spinning loading indicator
 */
@property (nonatomic, strong) UIColor *progressTintColor;

/**
 The color of the path below the spinning loading indicator
 */
@property (nonatomic, strong) UIColor *backgroundTintColor;

/**
 The animation state of the spinning loading indicator
 */
@property (nonatomic) BOOL isAnimating;

/**
 The line width of the indicator
 */
@property (nonatomic) CGFloat lineWidth;

/**
 The indicator begins animating.
 */
- (void)startAnimating;

/**
 The indicator remove animations and hidden.
 */
- (void)stopAnimating;

@end

NS_ASSUME_NONNULL_END
