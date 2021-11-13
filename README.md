
Affirm iOS SDK
==============
[![CocoaPods](https://img.shields.io/cocoapods/v/AffirmSDK.svg)](http://cocoadocs.org/docsets/AffirmSDK) [![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage) [![license](https://img.shields.io/cocoapods/l/AffirmSDK.svg)]()

The Affirm iOS SDK allows you to offer Affirm in your own app.

Installation
============

[CocoaPods](https://cocoapods.org/) and [Carthage](https://github.com/Carthage/Carthage) are the recommended methods for installing the Affirm SDK. 

<strong> CocoaPods </strong>

Add the following to your Podfile and run `pod install`
```ruby
pod 'AffirmSDK'
```

<strong> Carthage </strong>

Add the following to your Cartfile and follow the setup instructions [here](https://github.com/Carthage/Carthage#adding-frameworks-to-an-application).
```
github "Affirm/affirm-merchant-sdk-ios"
```

<strong>Swift Package Manager<strong>

From Xcode 11+ :

1. Select File > Swift Packages > Add Package Dependency. Enter `https://github.com/Affirm/affirm-merchant-sdk-ios` in the "Choose Package Repository" dialog.
2. In the next page, specify the version resolving rule as "Up to Next Major" with "5.0.21".
3. After Xcode checked out the source and resolving the version, you can choose the "AffirmSDK" library and add it to your app target.

For more info, read [Adding Package Dependencies to Your App](https://developer.apple.com/documentation/xcode/adding_package_dependencies_to_your_app) from Apple.

Alternatively, you can also add AffirmSDK to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/Affirm/affirm-merchant-sdk-ios", .upToNextMajor(from: "5.0.21"))
]
```

<strong> Manual </strong>

Alternatively, if you do not want to use CocoaPods or Carthage, you may clone our [GitHub repository](https://github.com/Affirm/affirm-merchant-sdk-ios) and simply drag and drop the `AffirmSDK` folder into your XCode project.

Usage Overview
==============

An Affirm integration consists of two components: checkout and promotional messaging.

Before you can use these components, you must first set the AffirmSDK with your public API key from your sandbox [Merchant Dashboard](https://sandbox.affirm.com/dashboard). You must set this key to the shared AffirmConfiguration once (preferably in your AppDelegate) as follows:
```
[[AffirmConfiguration sharedInstance] configureWithPublicKey:@"PUBLIC_API_KEY" locale:AffirmLocaleUS environment:AffirmEnvironmentSandbox merchantName:@"Affirm Example"];
```

## Checkout

### Checkout creation

Checkout creation is the process in which a customer uses Affirm to pay for a purchase in your app. This process is governed by the `AffirmCheckoutViewController` object, which requires three parameters:

- The `AffirmCheckout` object which contains details about the order
- The `useVCN` object which determines whether the checkout flow should use virtual card network to handle the checkout.

  - if set YES, it will return the debit card information from this delegate 
    ```
    - (void)vcnCheckout:(AffirmCheckoutViewController *)checkoutViewController completedWithCreditCard:(AffirmCreditCard *)creditCard
    ```

  - if set NO, it will return checkout token from this delegate 
    ```
    - (void)checkout:(AffirmCheckoutViewController *)checkoutViewController completedWithToken:(NSString *)checkoutToken
    ```

- The `AffirmCheckoutDelegate` object which receives messages at various stages in the checkout process

Once the AffirmCheckoutViewController has been constructed from the parameters above, you may present it with any other view controller. This initiates the flow which guides the user through the Affirm checkout process. An example of how this is implemented is provided as follows:

```
// initialize an AffirmItem with item details
AffirmItem *item = [AffirmItem itemWithName:@"Affirm Test Item" SKU:@"test_item" unitPrice:price quantity:1 URL:[NSURL URLWithString:@"http://sandbox.affirm.com/item"]];

// initialize an AffirmShippingDetail with the user's shipping address
AffirmShippingDetail *shipping = [AffirmShippingDetail shippingDetailWithName:@"Chester Cheetah" addressWithLine1:@"633 Folsom Street" line2:@"" city:@"San Francisco" state:@"CA" zipCode:@"94107" countryCode:@"USA"];

// initialize an AffirmCheckout object with the item(s), shipping details, tax amount, shipping amount, discounts, financing program, and order ID
AffirmCheckout *checkout = [[AffirmCheckout alloc] initWithItems:@[item] shipping:shipping taxAmount:[NSDecimalNumber zero] shippingAmount:[NSDecimalNumber zero] discounts:nil metadata:nil financingProgram:nil orderId:@"JKLMO4321"];

// The minimum requirements are to initialize the AffirmCheckout object with the item(s), shipping details, and payout Amount
AffirmCheckout *checkout = [AffirmCheckout checkoutWithItems:@[item] shipping:shipping payoutAmount:price];

// initialize an UINavigationController with the checkout object and present it
AffirmCheckoutViewController *checkoutViewController = [[AffirmCheckoutViewController alloc] initWithDelegate:self checkout:checkout useVCN:NO getReasonCodes:NO cardAuthWindow:10];
UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:checkoutViewController];
[self presentViewController:nav animated:YES completion:nil];

// It is recommended that you round the total in the checkout request to two decimal places. Affirm SDK converts the float total to integer cents before initiating the checkout, so may round up or down depending on the decimal places. Ensure that the rounding in your app uses the same calculation across your other backend systems, otherwise, it may cause an error of 1 cent or more in the total validation on your end. 
```

The flow ends once the user has successfully confirmed the checkout or vcn checkout, canceled the checkout, or encountered an error in the process. In each of these cases, Affirm will send a message to the AffirmCheckoutDelegate along with additional information about the result.

### Charge authorization

Once the checkout has been successfully confirmed by the user, the AffirmCheckoutDelegate object will receive a checkout token. This token should be forwarded to your server, which should then use the token to authorize a charge on the user's account. For more details about the server integration, see our [API documentation](https://docs.affirm.com/Integrate_Affirm/Direct_API#3._Authorize_the_charge).

Note - For VCN Checkout, all actions should be done using your existing payment gateway and debit card processor using the virtual card number returned after a successful checkout.

## Promotional Messaging

Affirm promotional messaging components—monthly payment messaging and educational modals—show customers how they can use Affirm to finance their purchases. Promos consist of promotional messaging, which appears directly in your app, and a modal, which  offers users an ability to prequalify.

To create promotional messaging view, the SDK provides the `AffirmPromotionalButton` class, only requires the developer to add to their view and configure to implement. The AffirmPromotionalButton is implemented as follows:

```
self.promotionalButton = [[AffirmPromotionalButton alloc] initWithPromoID:nil
                                                                  showCTA:YES
                                                                 pageType:AffirmPageTypeProduct
                                                 presentingViewController:self
                                                                    frame:CGRectMake(0, 0, 315, 34)];
[self.stackView insertArrangedSubview:self.promotionalButton atIndex:0];
```

To show / refresh promotional messaging, use
```
[self.promotionalButton configureByHtmlStylingWithAmount:[NSDecimalNumber decimalNumberWithString:amountText]
                                          affirmLogoType:AffirmLogoTypeName
                                             affirmColor:AffirmColorTypeBlue
                                           remoteFontURL:fontURL
                                            remoteCssURL:cssURL];
```
or
```
self.promotionalButton.configure(amount: NSDecimalNumber(string: amountText),
                         affirmLogoType: .name,
                            affirmColor: .blue,
                                   font: UIFont.italicSystemFont(ofSize: 15),
                              textColor: .gray)
```

If you have got the html raw string, you could show the promotional messaging using
```
[self.promotionalButton configureWithHtmlString:html
                                         amount:amount
                                  remoteFontURL:fontURL
                                   remoteCssURL:cssURL];
```
**[Note: the amount fields passed to the promotional messaging configuration methods should be in dollars (no cents), so it is best practice to round up to the nearest dollar before passing.]**

If you want to use local fonts, you need do following steps:
> 1. Add the font files to your project (make sure that the files are targeted properly to your application)
> 2. Add the font files to yourApp-Info.plist
> 3. Use the font in your CSS file, for example
```
@font-face
{
font-family: 'OpenSansCondensed-Bold';
src: local('OpenSansCondensed-Bold'),url('OpenSansCondensed-Bold.ttf') format('truetype');
}

body {
font-family: 'OpenSansCondensed-Light';
font-weight: normal;
!important;
}
```
**[Note: if no promotional message returned, the button will be hidden automatically]**

Tapping on the Promotional button automatically opens a modal in an `AffirmPrequalModalViewController` with more information, including (if you have it configured) a button that prompts the user to prequalify for Affirm financing.

**[Note: The AffirmPrequalModalViewController is deprecated as of SDK version 4.0.13.]** To display the AffirmPromoModal outside of tapping on the AffirmPromotionalButton, you may initialize and display an instance of the promo modal viewController as follows:

```
AffirmPromoModalViewController *viewController = [[AffirmPromoModalViewController alloc] initWithPromoId:@"promo_id" amount:amount delegate:delegate];
UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:viewController];
[self.presentingViewController presentViewController:nav animated:YES completion:nil];
```

## Retrieve raw string from As low as message

You can retrieve raw string using `AffirmDataHandler`.

```
NSDecimalNumber *dollarPrice = [NSDecimalNumber decimalNumberWithString:self.amountTextField.text];
[AffirmDataHandler getPromoMessageWithPromoID:nil
                                       amount:dollarPrice
                                      showCTA:YES
                                     pageType:AffirmPageTypeBanner
                                     logoType:AffirmLogoTypeName
                                    colorType:AffirmColorTypeBlue
                                         font:[UIFont boldSystemFontOfSize:15]
                                    textColor:[UIColor grayColor]
                     presentingViewController:self
                            completionHandler:^(NSAttributedString *attributedString, UIViewController *viewController, NSError *error) {
                                [self.promoButton setAttributedTitle:attributedString forState:UIControlStateNormal];
                                self.promoViewController = viewController;
}];
```
After that, you could present promo modal using
```
UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:self.promoViewController];
[self presentViewController:nav animated:YES completion:nil];
```

## Track Order Confirmed

The trackOrderConfirmed event triggers when a customer completes their purchase. The SDK provides the  `AffirmOrderTrackerViewController` class to track it, it requires `AffirmOrder` and an array with `AffirmProduct`.

```
[AffirmOrderTrackerViewController trackOrder:order products:@[product0, product1]];
```

**[Note: this feature will be improved after the endpoint is ready for app and it will be disappeared after 5 seconds]**

Example
=======

A demo app that integrates Affirm is included in the repo. You may clone our [GitHub repository](https://github.com/Affirm/affirm-merchant-sdk-ios) into a new XCode project folder and run the Examples project.

Upgrade
==============

If you are using an older version of the SDK, you can refer to this [upgrade document](https://github.com/Affirm/affirm-merchant-sdk-ios/blob/master/UPGRADE.md). We recommend that you install the lastest version of this SDK to access the most up-to-date features and experience. 

Changelog
==============

All notable changes to this project will be documented in [changelog document](https://github.com/Affirm/affirm-merchant-sdk-ios/blob/master/CHANGELOG.md).

Package Size
==============

Final Binary Size: 0.67 MB
