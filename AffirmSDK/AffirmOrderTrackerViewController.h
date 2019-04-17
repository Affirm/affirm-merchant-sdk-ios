//
//  AffirmOrderTrackerViewController.h
//  AffirmSDK
//
//  Created by Victor Zhu on 2019/4/4.
//  Copyright © 2019 Affirm, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@class AffirmOrder, AffirmProduct;

NS_ASSUME_NONNULL_BEGIN

@interface AffirmOrderTrackerViewController : UIViewController

/**
 The order object used to start the track process.
 */
@property (nonatomic, copy, readonly) AffirmOrder *order;

/**
 The products object used to start the track process.
 */
@property (nonatomic, copy, readonly) NSArray <AffirmProduct *>*products;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil
                         bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;

/**
 Convenience constructor starts the track order confirmation, showIndicator uses NO as default

 @param order An order object which contains the information about the order.
 @param products An array which contains the list of all prodcuts.
 */
+ (void)trackOrder:(AffirmOrder *)order
          products:(NSArray <AffirmProduct *>*)products
NS_SWIFT_NAME(track(order:products:));

@end

NS_ASSUME_NONNULL_END
