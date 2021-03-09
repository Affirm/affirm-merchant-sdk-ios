# Affirm iOS SDK Changelog
All notable changes to the SDK will be documented in this file.

## Version 5.0.18 (January 12, 2021)
- Bug fix for promotional modal
- Enhancement for VCN checkout flow

## Version 5.0.17 (January 12, 2021)
- Add support for specifying Virtual Card Auth windows
- Enhanced Promo Messaging

## Version 5.0.16 (December 1, 2020)
- Hot fix to correct missing checkout token

## Version 5.0.15 (October 30, 2020)
- Bug fix and compatibility support

## Version 5.0.14 (October 27, 2020)
- Added CaaS support
- Added alternate checkout flow

## Version 5.0.13 (July 24, 2020)
- Added SKU based Financing Support

## Version 5.0.12 (May 29, 2020)
- Added parameters to product modal
- Added an example of product modal
- Bug-fix
- Added SDK size
- Added HTML support for AffirmDataHandler

## Version 5.0.11 (March 13, 2020)
- Update metadata

## Version 5.0.10 (February 21, 2020)
- Bug-fix

## Version 5.0.9 (February 13, 2020)
- Add webhook session ID
- Update logos
- Add support for CA currency
- Change promo endpoint
- Remove promoId dependency from ala messaging call
- Add iOS Callback callback
- Update iOS SDK to accept total amount
- Bug-fixes
- VCN Support null data

## Version 5.0.8 (November 12, 2019)
- Support for Blue and Black logo in text

## Version 5.0.7.1 (Nov 7, 2019)
- Bug Fixes
- Added navigation parameter for modal

## Version 5.0.6 (October 30, 2019)
- Contracts load in webview
- Version in metadata is inline with release

## Version 5.0.5 (September 27, 2019)
- Support type face, text size, and text color for promo messaging
- Support local fonts
- Handle empty ALA messages
- Shipping/Billing consistent with direct API requirements
- Add reason codes for VCN checkout cancellation
- Cannot exit checkout in Sandbox testing
- Minor Bug Fixes

## Version 5.0.4 (June 20, 2019)
- Updated modal configuration
- Custom CSS support in ALA messaging
- ALA messaging webviews
- ALA messaging logo and color support
- Updated sample controller implementation
- Button should be removed if ALA message is blank

## Version 5.0.3 (May 29, 2019)
- Added order_id
- HTML support in messaging

## Version 5.0.2 (April 29, 2019)
- Added page type
- Added session cookie
- Added method to remove cookies

## Version 5.0.1 (April 19, 2019)
### Changed
- Refactor code
  - HTTP Networking
  - Debug logging
  - Event tracker
  - SDK configuration and init
  - Prequalify Flow
  - Checkout Flow (direct + vcn)
  - Exceptional Flows
  - Activity indicator
  - Track order confirmed

- `AffirmConfiguration` can be setup with simplified method. Current implementation is as follows:
```
[[AffirmConfiguration sharedInstance] configureWithPublicKey:@"PUBLIC_API_KEY" environment:AffirmEnvironmentSandbox];
```
- `AffirmCheckoutType` was deprecated, no need to pass this paramter when start checkout. Activity indicator was built into the webview controller, automatically show/hidden according to the loading progress. Current implementation is as follows:
``` 
AffirmCheckoutViewController *checkoutVC = [AffirmCheckoutViewController startCheckout:checkout delegate:self];
```
- `AffirmErrorModal` was deprecated. Developer can handle callback flexibly when checkout creation was failed. 
```
- (void)checkout:(AffirmCheckoutViewController *)checkoutViewController didFailWithError:(NSError *)error;
```
- `AffirmAsLowAsButton` is modified to `AffirmPromotionalButton`. Current implementation is as follows:

	```
	AffirmPromotionalButton *button = [[AffirmPromotionalButton alloc] initWithPromoID:@"promoID"
                                                                              showCTA:showCTA
									      pageType:@"pageType"
                                                             presentingViewController:viewController
                                                                                frame:frame];
	```
	`AffirmPromotionalButton` now suppports Interface builder.
	
	`presentingViewController` must implement `AffirmPrequalDelegate`.
	
- `AffirmAsLowAsData` was deprecated. Promotional information is modified from `AffirmPromoRequest`, the processing of attribute text is encapsulated in `AffirmPromotionalButton`.

-  `AffirmPrequalDelegate` provides a callback when prequalify flow fails.

-  `totalAmount` was renamed to `payoutAmount` and `total` was renamed to `totalAmount` in `AffirmCheckout` Class.

-  `AffirmOrderTrackerViewController` shows how to track an order confirmed, it requires `AffirmOrder` and a list of `AffirmProduct`.

## Version 4.0.17 (Apr 16, 2019)
- Updated VCN checkout
- Bug fixes

## Version 4.0.16 (Feb 28, 2019)
- VCN checkout
- Updated promo attributes
- Bug Fixes

## Version 4.0.15 (Feb 14, 2019)
- BUg fix for nil check for Tax and Shipping
 
## Version 4.0.14 (Jan 28, 2019)
- Updated the demo application
- Added total amount as an input parameter
- Added total amount tests
- Fixed ALA test and updated CDN endpoints

## Version 4.0.13 (Jan 3, 2019)
- Promo end point updated

## Version 4.0.12 (Dec 21, 2018)
- Prequal support added
- Affirm logos updated

## Version 4.0.10 (May 30, 2018)
- Fixed a crash when pricingTemplate was NSNull
- Added platform_type to metadata

## Version 4.0.9 (March 5, 2018)
- Fixed Carthage issue

## Version 4.0.7 (February 23, 2018)
- Removed CFBundleExecutable key from Info.plist
- Fixed AsLowAs lowest_apr parsing

## Version 4.0.6 (August 7, 2017)
- Internal bug fix

## Version 4.0.5 (August 7, 2017)
- Internal changes to ALA
- Added ALA tests

## Version 4.0.4 (August 1, 2017)
- Minor internal updates to checkout and error modal
- Fixed tracker domain

## Version 4.0.3 (July 17, 2017)
- Minor internal updates
- Fixed unit tests

## Version 4.0.2 (July 14, 2017)
- Minor fixes to logger
- Added Travis config
- Minor updates to SDK demo

## Version 4.0.1 (July 12, 2017)
- Added Carthage support for SDK installation
- UI Tests on SDK demo

## Version 4.0.0 (July 10, 2017)
### Added
- Calls to start the checkout process now require passing an ```AffirmCheckoutType``` (either Automatic or Manual) to specify whether the SDK should display a loading spinner and handle error notifications or that the developer will manually handle these states. The call to start the checkout process is now
``` 
[AffirmCheckoutViewController startCheckout:checkout checkoutType:AffirmCheckoutType delegate:self]; 
```
- Added AffirmAsLowAsButton that encapsulates the AffirmAsLowAs functionality in a button that handles all states and only requires the developer to add to their view and configure to implement. Tapping on the button automatically opens the appropriate promo modal
- Added AffirmErrorModal that displays error notifications in the checkout flow if the Automatic checkout type is selected

### Changed
- Developers no longer need to configure AffirmAsLowAs text onto their label manually. The ALA functionality has been wrapped into a custom AffirmAsLowAsButton that handles all states and can be implemented as follows
```
AffirmAsLowAsButton *alaButton = [AffirmAsLowAsButton createButtonWithPromoID:@"promo_id" presentingViewController:self frame:frame];
[self.view addSubview:alaButton];
[alaButton configureWithAmount:amount affirmLogoType:AffirmLogoTypeName 		affirmColor:AffirmColorTypeBlue maxFontSize:18 callback:^(BOOL alaEnabled, NSError *error) {
//alaEnabled specifies whether ALA text or a default message is being displayed
}];
```
- Tapping on the ALA button automatically opens a product/site modal depending on whether ALA is enabled on the button
- The AffirmProductModal and AffirmSiteModal classes have now been merged into the AffirmPromoModal class. This modal can still be created and shown manually outside of tapping on the AffirmALAButton as follows
```
AffirmPromoModalViewController *promoVC = [AffirmPromoModalViewController promoModalControllerWithModalId:@"promo_id" amount:amount];
[self presentViewController:promoVC animated:YES completion:nil];
```
- AffirmAsLowAs has been broken into its own class and has been refactored to use a new endpoint internally
- The SDK now uses WKWebView internally to display all web content
- Fixed bug where the checkout VC would not close after the second open

## Version 3.0.0 (June 20, 2017)
### Added
- Delegate method that notifies when checkout ready to present
- Developer environment enums that must be specified when intializing a configuration
- Activity indicator that is automatically added/dismissed to denote loading state when presenting checkout or modal VCs
- Alternate checkout flow where the checkout VC is presented only when the checkoutReadyToPresent delegate method is fired. Helps avoid weird behavior where checkout VC pops up and immediately dismisses from screen in the case where checkout creation fails
- Descriptive error messages passed to an error's localizedDescription property

### Changed
- AffirmConfiguration now only needs to be set once with a preset developer environment. As a result, all SDK methods no longer require passing a configuration object. Current implementation is as follows:
```
    AffirmConfiguration *config = [AffirmConfiguration configurationWithPublicAPIKey:@"YOUR_API_KEY" environment:AffirmEnvironmentSandbox];
    [AffirmConfiguration setSharedConfiguration:config];
```
- AffirmAsLowAs now returns the asLowAs text and an appropriately scaled logo image instead of modifying the attributed text on a passed label. 
A helper method ```appendLogo:(UIImage *)logo toText:(NSString *)text``` has been provided to generate an attributed string that inserts the logo in the asLowAs text so it can be set to your label.
- AffirmContact and AffirmAddress classes have been merged into the AffirmShippingDetail class
- Method that starts checkout process has been renamed to ```[AffirmCheckoutViewController startCheckout:checkout withDelegate:self]```
- AffirmItem object no longer requires passing an imageURL parameter
- AffirmDisplayType enum in the AffirmAsLowAs class has been renamed to AffirmLogoType
