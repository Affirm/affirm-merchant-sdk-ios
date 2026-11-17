//
//  PromoFlagSimulator.h
//  Examples
//
//  Copyright © 2026 Affirm, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, PromoFlagSimulation) {
    /// Promo responses are passed through untouched.
    PromoFlagSimulationOff,
    /// Sets `ios_sdk_migrate_native_to_html_render: true` in the promo config.
    PromoFlagSimulationFlagOn,
    /// Sets `ios_sdk_migrate_native_to_html_render: false` in the promo config.
    PromoFlagSimulationFlagOff,
    /// Removes `ios_sdk_migrate_native_to_html_render` from the promo config.
    PromoFlagSimulationFlagMissing,
    /// Flag on, and unsafe markup is added to `html_ala` to show what the SDK strips.
    PromoFlagSimulationUnsafeMarkup,
    /// Flag on, and `html_ala` is replaced with content that is empty after sanitizing.
    PromoFlagSimulationBrokenHTML,
};

/// Demo only. Rewrites promo responses on their way into the SDK, so every flag value and
/// failure can be tried whatever the server sends for this merchant. Merchant apps never need
/// anything like this.
/// Posted on the main queue for each promo response handed to the SDK, after any rewrite.
/// `userInfo[PromoFlagSimulatorResponseKey]` is the response as pretty-printed JSON.
extern NSNotificationName const PromoFlagSimulatorDidDeliverResponseNotification;
extern NSString *const PromoFlagSimulatorResponseKey;

@interface PromoFlagSimulator : NSURLProtocol

@property (class, nonatomic) PromoFlagSimulation simulation;
/// Also intercepts promo requests while `simulation` is off, to post them unchanged.
@property (class, nonatomic) BOOL reportsResponses;

@end

NS_ASSUME_NONNULL_END
