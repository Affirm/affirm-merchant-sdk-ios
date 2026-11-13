How to upgrade? 
====================
If you want to upgrade you sdk to the lastest, please check the following points:

## Version
The latest version is `v5.0.41`, you can upgrade sdk by [CocoaPods](https://cocoapods.org/) and [Carthage](https://github.com/Carthage/Carthage).

For example:

if you use [CocoaPods](https://cocoapods.org/), please make sure you pod repo contains `v5.0.41`, you can use `pod search AffirmSDK` to check it. Otherwise, you should update pod repo before upgrade.


## Fetch updated library

If you already use specific sdk version in Podfile, please modify the line related to affirmSDK as follows:

```
pod 'AffirmSDK', '~> 5.0.41'
```

Otherwise, just use `pod update AffirmSDK` in terminal to update AffirmSDK.


## Unreleased: what changes for promotional messaging

No API is removed or renamed, and existing code compiles unchanged. Check the following before you ship:

- **The minimum iOS version is now 15.0** in CocoaPods, Swift Package Manager and the Xcode project.
- **`configureWithAmount:…` can render as HTML.** When Affirm turns this on for the promo, the native API shows the promo HTML in the button's web view with your font, size and text color, and falls back to the native text if the HTML fails or takes longer than 5 seconds. Fonts other than the system, serif and monospaced system fonts (regular, bold, italic, bold italic) always stay native. See [HTML rendering for the native API](README.md#html-rendering-for-the-native-api).
- **To keep native text**, opt out before configuring promos:
  ```
  [AffirmConfiguration sharedInstance].useLegacyNativeRendering = YES;
  ```
- **Promo HTML is sanitized** in every HTML mode, including `configureByHtmlStylingWithAmount:…` and `configureWithHtmlString:…`. Inline `style`, ARIA attributes, `id`, `name`, `data-*`, scripts, event handlers and non-https links and images are removed, so move any styling you rely on into your stylesheet's classes.
- **`remoteCssURL` and `remoteFontURL` must be https or files in your app bundle.** The stylesheets, fonts and promo images must also load within 5 seconds. Otherwise the HTML promo fails and the button is hidden, because explicit HTML never falls back to native text.
- **VoiceOver reads a promo as one button.** If your UI tests find promo text inside the web view, find the button by its accessibility label instead.

## Make code changes against the new SDK API

- `AffirmConfiguration` can be setup with simplified method. Current implementation is as follows:
  ```
  [[AffirmConfiguration sharedInstance] configureWithPublicKey:@"PUBLIC_API_KEY" environment:AffirmEnvironmentSandbox];
  ```

  >  ~~AffirmConfiguration *config = [AffirmConfiguration configurationWithPublicAPIKey:@"PUBLIC_API_KEY" environment:AffirmEnvironmentSandbox];~~
  ~~[AffirmConfiguration setSharedConfiguration:config];~~
  

- ~~`AffirmCheckoutType`~~ was deprecated, no need to pass this paramter when start checkout. Activity indicator was built into the webview controller, automatically show/hidden according to the loading progress. Current implementation is as follows:
  
  ``` 
  AffirmCheckoutViewController *checkoutVC = [AffirmCheckoutViewController startCheckout:checkout delegate:self];
  ```

  > ~~AffirmCheckoutViewController *checkoutVC = [AffirmCheckoutViewController startCheckout:checkout checkoutType:AffirmCheckoutTypeAutomatic useVCN:NO delegate:self];~~


- ~~`AffirmErrorModal`~~ was deprecated. Developer can handle callback flexibly when checkout creation was failed. 
  ```
  - (void)checkout:(AffirmCheckoutViewController *)checkoutViewController didFailWithError:(NSError *)error;
  ```

  > ~~`- (void)checkout:(AffirmCheckoutViewController *)checkoutVC creationFailedWithError:(NSError *)error`~~

- ~~`AffirmAsLowAsButton`~~ is modified to `AffirmPromotionalButton`. Current implementation is as follows:

	```
	AffirmPromotionalButton *button = [[AffirmPromotionalButton alloc] initWithPromoID:@"promoID"
                                                                              showCTA:showCTA
                                                             presentingViewController:viewController
                                                                                frame:frame];
	```
	`AffirmPromotionalButton` now suppports Interface builder.
	
	`presentingViewController` must implement `AffirmPrequalDelegate`.
	
- ~~`AffirmAsLowAsData`~~ was deprecated. Promotional information is modified from `AffirmPromoRequest`, the processing of attribute text is encapsulated in `AffirmPromotionalButton`.

-  `AffirmPrequalDelegate` provides a callback when prequalify flow fails.

-  ~~`totalAmount`~~ was renamed to `payoutAmount` and ~~`total`~~ was renamed to `totalAmount` in `AffirmCheckout` Class.

## Rebuild and ship
Rebuild you project, if there is no compile error and AffirmSDK work as you expected. **Congratulations!** you can ship it now.


