//
//  AffirmPrequalDelegate.h
//  AffirmSDK
//
//  Created by yijie on 2019/3/25.
//  Copyright © 2019 Affirm, Inc. All rights reserved.
//

@class AffirmBaseWebViewController;

NS_ASSUME_NONNULL_BEGIN

/**
 A delegate which handles prequal flow failed event.
 */
@protocol AffirmPrequalDelegate <NSObject>

/**
 This method is called when prequal flow has failed.
 
 @param webViewController The current view controller that manages the prequal flow.
 @param error An instance error object.
 */
- (void)webViewController:(nullable AffirmBaseWebViewController *)webViewController didFailWithError:(NSError *)error;

@end

NS_ASSUME_NONNULL_END
