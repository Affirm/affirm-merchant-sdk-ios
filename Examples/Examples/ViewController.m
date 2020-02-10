//
//  ViewController.m
//  Examples
//
//  Created by Victor Zhu on 2019/3/5.
//  Copyright © 2019 Affirm, Inc. All rights reserved.
//

#import "ViewController.h"
#import <AffirmSDK/AffirmSDK.h>

@interface ViewController () <UITextFieldDelegate, AffirmPrequalDelegate, AffirmCheckoutDelegate>

@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;
@property (nonatomic, weak) IBOutlet UIButton *promoButton;
@property (nonatomic, weak) IBOutlet UIStackView *stackView;
@property (nonatomic, weak) IBOutlet UITextField *amountTextField;
@property (nonatomic, weak) IBOutlet UITextField *promoIDTextField;
@property (nonatomic, weak) IBOutlet UITextField *publicKeyTextfield;
@property (nonatomic, weak) IBOutlet UILabel *resultLabel;

@property (nonatomic, strong) AffirmPromotionalButton *promotionalButton;
@property (nonatomic, strong) UIViewController *promoViewController;

@end

@implementation ViewController

#pragma mark - Life Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Using AffirmPromotionalButton for first button
    self.promotionalButton = [[AffirmPromotionalButton alloc] initWithShowCTA:YES
                                                                     pageType:AffirmPageTypeProduct
                                                     presentingViewController:self
                                                                        frame:CGRectMake(0, 0, 315, 34)];
    [self.stackView insertArrangedSubview:self.promotionalButton atIndex:0];

    // Using AffirmDataHandler for second button
    self.promoButton.titleLabel.numberOfLines = 0;
    NSDecimalNumber *dollarPrice = [NSDecimalNumber decimalNumberWithString:self.amountTextField.text];
    [AffirmDataHandler getPromoMessageWithPromoID:nil
                                           amount:dollarPrice
                                          showCTA:YES
                                         pageType:AffirmPageTypeBanner
                                         logoType:AffirmLogoTypeSymbol
                                        colorType:AffirmColorTypeBlueBlack
                                             font:[UIFont boldSystemFontOfSize:15]
                                        textColor:[UIColor grayColor]
                         presentingViewController:self
                                   withNavigation:YES
                                completionHandler:^(NSAttributedString *attributedString, UIViewController *viewController, NSError *error) {
                                    [self.promoButton setAttributedTitle:attributedString forState:UIControlStateNormal];
                                    self.promoViewController = viewController;
                                }];

    // Configure Textfields
    self.publicKeyTextfield.text = [AffirmConfiguration sharedInstance].publicKey;
    [self configureTextField];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
    [self configurPromotionalMessage];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillChangeFrame:(NSNotification *)notification
{
    NSValue *rectValue = notification.userInfo[UIKeyboardFrameEndUserInfoKey];
    self.scrollView.contentInset = UIEdgeInsetsMake(0, 0, CGRectGetHeight(rectValue.CGRectValue), 0);
}

- (void)keyboardWillBeHidden:(NSNotification *)notification
{
    self.scrollView.contentInset = UIEdgeInsetsZero;
}

#pragma mark - Actions

- (IBAction)showPromoModal:(id)sender
{
    [self presentViewController:self.promoViewController animated:YES completion:nil];
}

- (IBAction)checkout:(id)sender
{
    NSDecimalNumber *dollarPrice = [NSDecimalNumber decimalNumberWithString:self.amountTextField.text];
    AffirmItem *item = [AffirmItem itemWithName:@"Affirm Test Item" SKU:@"test_item" unitPrice:dollarPrice quantity:1 URL:[NSURL URLWithString:@"http://sandbox.affirm.com/item"]];
    AffirmShippingDetail *shipping = [AffirmShippingDetail shippingDetailWithName:@"Chester Cheetah" addressWithLine1:@"633 Folsom Street" line2:@"" city:@"San Francisco" state:@"CA" zipCode:@"94107" countryCode:@"USA"];
    AffirmCheckout *checkout = [AffirmCheckout checkoutWithItems:@[item] shipping:shipping totalAmount:[dollarPrice toIntegerCents]];
    AffirmBillingDetail *billing = [AffirmBillingDetail billingDetailWithName:@"Chester Cheetah" email:@"testtester@test.com" phoneNumber:nil addressWithLine1:@"633 Folsom Street" line2:@"" city:@"San Francisco" state:@"CA" zipCode:@"94107" countryCode:@"USA"];
    checkout.billing = billing;

    UINavigationController *nav = [AffirmCheckoutViewController startCheckoutWithNavigation:checkout useVCN:NO getReasonCodes:NO delegate:self];
    [self presentViewController:nav animated:YES completion:nil];
}

- (IBAction)showFailedCheckout:(id)sender
{
    NSDecimalNumber *dollarPrice = [NSDecimalNumber decimalNumberWithString:self.amountTextField.text];
    AffirmItem *item = [AffirmItem itemWithName:@"Affirm Test Item" SKU:@"test_item" unitPrice:dollarPrice quantity:1 URL:[NSURL URLWithString:@"http://sandbox.affirm.com/item"]];
    AffirmShippingDetail *shipping = [AffirmShippingDetail shippingDetailWithName:@"Test Tester" email:@"testtester@test.com" phoneNumber:@"1111111111" addressWithLine1:@"633 Folsom Street" line2:@"" city:@"San Francisco" state:@"CA" zipCode:@"94107" countryCode:@"USA"];
    AffirmCheckout *checkout = [AffirmCheckout checkoutWithItems:@[item] shipping:shipping totalAmount:[dollarPrice toIntegerCents]];

    UINavigationController *nav = [AffirmCheckoutViewController startCheckoutWithNavigation:checkout useVCN:NO getReasonCodes:NO delegate:self];
    [self presentViewController:nav animated:YES completion:nil];
}

- (IBAction)vcnCheckout:(UIButton *)sender
{
    NSDecimalNumber *dollarPrice = [NSDecimalNumber decimalNumberWithString:self.amountTextField.text];
    AffirmItem *item = [AffirmItem itemWithName:@"Affirm Test Item" SKU:@"test_item" unitPrice:dollarPrice quantity:1 URL:[NSURL URLWithString:@"http://sandbox.affirm.com/item"]];
    AffirmShippingDetail *shipping = [AffirmShippingDetail shippingDetailWithName:@"Chester Cheetah" addressWithLine1:@"633 Folsom Street" line2:@"" city:@"San Francisco" state:@"CA" zipCode:@"94107" countryCode:@"USA"];
    AffirmCheckout *checkout = [AffirmCheckout checkoutWithItems:@[item] shipping:shipping totalAmount:[dollarPrice toIntegerCents]];
    AffirmBillingDetail *billing = [AffirmBillingDetail billingDetailWithName:nil email:nil phoneNumber:nil addressWithLine1:nil line2:nil city:nil state:nil zipCode:nil countryCode:nil];
    checkout.billing = billing;

    UINavigationController *nav = [AffirmCheckoutViewController startCheckoutWithNavigation:checkout useVCN:YES getReasonCodes:YES delegate:self];
    [self presentViewController:nav animated:YES completion:nil];
}

- (IBAction)trackOrderConfirmation:(id)sender
{
    AffirmOrder *order = [[AffirmOrder alloc] initWithStoreName:@"Affirm Store"
                                                     checkoutId:nil
                                                         coupon:@"SUMMER2018"
                                                       currency:@"USD"
                                                       discount:NSDecimalNumber.zero
                                                        orderId:@"T12345"
                                                  paymentMethod:@"Visa"
                                                        revenue:[NSDecimalNumber decimalNumberWithString:@"2920"]
                                                       shipping:[NSDecimalNumber decimalNumberWithString:@"534"]
                                                 shippingMethod:@"Fedex"
                                                            tax:[NSDecimalNumber decimalNumberWithString:@"285"]
                                                          total:[NSDecimalNumber decimalNumberWithString:@"3739"]];
    AffirmProduct *product0 = [[AffirmProduct alloc] initWithBrand:@"Affirm"
                                                         category:@"Apparel"
                                                           coupon:@"SUMMER2018"
                                                             name:@"Affirm T-Shirt"
                                                            price:[NSDecimalNumber decimalNumberWithString:@"730"]
                                                        productId:@"SKU-1234"
                                                         quantity:1
                                                          variant:@"Black"
                                                         currency:nil];
    AffirmProduct *product1 = [[AffirmProduct alloc] initWithBrand:@"Affirm"
                                                         category:@"Apparel"
                                                           coupon:@"SUMMER2018"
                                                             name:@"Affirm Turtleneck Sweater"
                                                            price:[NSDecimalNumber decimalNumberWithString:@"2190"]
                                                        productId:@"SKU-5678"
                                                         quantity:1
                                                          variant:@"Black"
                                                         currency:nil];
    [AffirmOrderTrackerViewController trackOrder:order products:@[product0, product1]];

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:@"Track successfully" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (IBAction)clearCookies:(id)sender
{
    [AffirmConfiguration deleteAffirmCookies];
    [self configurPromotionalMessage];

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:@"Clear successfully" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)configurPromotionalMessage
{
    NSString *amountText = self.amountTextField.text;
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"css_promo_sample" withExtension:@"css"];
    [self.promotionalButton configureByHtmlStylingWithAmount:[NSDecimalNumber decimalNumberWithString:amountText]
                                              affirmLogoType:AffirmLogoTypeName
                                                 affirmColor:AffirmColorTypeBlueBlack
                                               remoteFontURL:[NSURL URLWithString:@"https://fonts.googleapis.com/css?family=Saira+Stencil+One&display=swap"]
                                                remoteCssURL:url];
}

- (void)configureTextField
{
    [@[self.publicKeyTextfield, self.amountTextField, self.promoIDTextField] enumerateObjectsUsingBlock:^(UITextField * _Nonnull textField, NSUInteger idx, BOOL * _Nonnull stop) {
        UIToolbar *toolbar = [UIToolbar new];
        UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        UIBarButtonItem *doneItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:textField action:@selector(resignFirstResponder)];
        toolbar.items = @[flexibleItem, doneItem];
        [toolbar sizeToFit];
        textField.inputAccessoryView = toolbar;
    }];
}

#pragma mark - UITextField delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if (textField == self.publicKeyTextfield) {
        [[AffirmConfiguration sharedInstance] configureWithPublicKey:textField.text environment:AffirmEnvironmentSandbox];
    } else if (textField == self.promoIDTextField) {
        self.promotionalButton.promoID = textField.text;
    }
    [self configurPromotionalMessage];
}

#pragma mark - Affirm prequal delegate

- (void)webViewController:(nullable AffirmBaseWebViewController *)webViewController didFailWithError:(NSError *)error
{
    // The prequal process failed
    NSLog(@"Prequal failed with error: %@", error.userInfo);
    if (webViewController) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Error" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [webViewController dismissViewControllerAnimated:YES completion:nil];
        }]];
        [webViewController presentViewController:alertController animated:YES completion:nil];
    }
}

#pragma mark - Affirm checkout delegate

- (void)checkout:(AffirmCheckoutViewController *)checkoutViewController completedWithToken:(NSString *)checkoutToken
{
    // The user has completed the checkout and created a checkout token.
    // This token should be forwarded to your server, which should then authorize it with Affirm and create a charge.
    self.resultLabel.text = [NSString stringWithFormat:@"Received token:\n%@", checkoutToken];
    [checkoutViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)vcnCheckout:(AffirmCheckoutViewController *)checkoutViewController completedWithCreditCard:(AffirmCreditCard *)creditCard
{
    // The user has completed the checkout and returned credit card details.
    // All charge actions are done using your existing payment gateway and debit card processor
    self.resultLabel.text = [NSString stringWithFormat:@"Received credit card:\ncredit card id: %@\ncheckout token: %@\ncard holder name: %@\nnumber:%@\ncvv: %@\nexpiration: %@\ncallback id: %@", creditCard.creditCardId, creditCard.checkoutToken, creditCard.cardholderName, creditCard.number, creditCard.cvv, creditCard.expiration, creditCard.callbackId];
    [checkoutViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)checkoutCancelled:(AffirmCheckoutViewController *)checkoutViewController
{
    // The checkout process was cancelled
    NSLog(@"Checkout was cancelled");
    self.resultLabel.text = [NSString stringWithFormat:@"Checkout was cancelled"];
    [checkoutViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)checkoutCancelled:(AffirmCheckoutViewController *)checkoutViewController checkoutCanceledWithReason:(AffirmReasonCode *)reasonCode
{
    // The user has completed the checkout and returned credit card details.
    // All charge actions are done using your existing payment gateway and debit card processor
    NSLog(@"Checkout canceled with a reason: %@", reasonCode.reason);
    self.resultLabel.text = [NSString stringWithFormat:@"Checkout canceled \n reason: %@, \n checkout_token: %@", reasonCode.reason, reasonCode.checkout_token];
    [checkoutViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)checkout:(AffirmCheckoutViewController *)checkoutViewController didFailWithError:(NSError *)error
{
    // The checkout process failed
    NSLog(@"Checkout failed with error: %@", error);
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Error" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [checkoutViewController dismissViewControllerAnimated:YES completion:nil];
    }]];
    [checkoutViewController presentViewController:alertController animated:YES completion:nil];
}

@end
