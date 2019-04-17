//
//  AffirmPopupViewController.h
//  AffirmSDK
//
//  Created by Paul on 3/18/19.
//  Copyright © 2019 Affirm, Inc. All rights reserved.
//

#import "AffirmBaseWebViewController.h"

NS_ASSUME_NONNULL_BEGIN

/**
 The AffirmPopupViewController is a view controller which manages the various popups which users may see.
 */
@interface AffirmPopupViewController : AffirmBaseWebViewController

/**
 Initializer.

 @param URL The disclosure URL.
 @return The initialized disclosure view controller.
 */
- (instancetype)initWithURL:(NSURL *)URL;

@end

NS_ASSUME_NONNULL_END
