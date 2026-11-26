//
//  ViewController.m
//  Examples
//
//  Created by Victor Zhu on 2019/3/5.
//  Copyright © 2019 Affirm, Inc. All rights reserved.
//

#import "ViewController.h"
#import <AffirmSDK/AffirmSDK.h>
#import "RenderMigrationViewController.h"
#import "ExpressCheckoutViewController.h"
#import "PromoTableViewController.h"
#import "Button.h"

@interface ViewController () <UITextFieldDelegate, AffirmPrequalDelegate, AffirmCheckoutDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIButton *promoButton;
@property (nonatomic, strong) UIStackView *stackView;
@property (nonatomic, strong) UITextField *amountTextField;
@property (nonatomic, strong) UITextField *promoIDTextField;
@property (nonatomic, strong) UITextField *publicKeyTextfield;
@property (nonatomic, strong) UITextField *caasTextfield;
@property (nonatomic, strong) UILabel *resultLabel;

@property (nonatomic, strong) AffirmPromotionalButton *promotionalButton;
@property (nonatomic, strong) UIViewController *promoViewController;

@end

@implementation ViewController

#pragma mark - Life Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self buildLayout];
    
    // Configure Textfields
    self.publicKeyTextfield.text = [AffirmConfiguration sharedInstance].publicKey;
    [self configureTextField];
}

#pragma mark - Layout

- (void)buildLayout
{
    self.view.backgroundColor = [UIColor whiteColor];

    UIScrollView *scrollView = [UIScrollView new];
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.showsVerticalScrollIndicator = NO;
    [self.view addSubview:scrollView];
    self.scrollView = scrollView;

    UIView *contentView = [UIView new];
    contentView.translatesAutoresizingMaskIntoConstraints = NO;
    contentView.backgroundColor = [UIColor whiteColor];
    [scrollView addSubview:contentView];

    UIStackView *stackView = [UIStackView new];
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.spacing = 15;
    [contentView addSubview:stackView];
    self.stackView = stackView;

    UILayoutGuide *safeArea = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [scrollView.topAnchor constraintEqualToAnchor:safeArea.topAnchor],
        [scrollView.bottomAnchor constraintEqualToAnchor:safeArea.bottomAnchor],
        [scrollView.leadingAnchor constraintEqualToAnchor:safeArea.leadingAnchor],
        [scrollView.trailingAnchor constraintEqualToAnchor:safeArea.trailingAnchor],
        [contentView.topAnchor constraintEqualToAnchor:scrollView.topAnchor],
        [contentView.bottomAnchor constraintEqualToAnchor:scrollView.bottomAnchor],
        [contentView.leadingAnchor constraintEqualToAnchor:scrollView.leadingAnchor],
        [contentView.trailingAnchor constraintEqualToAnchor:scrollView.trailingAnchor],
        [contentView.widthAnchor constraintEqualToAnchor:scrollView.widthAnchor],
        [stackView.topAnchor constraintEqualToAnchor:contentView.topAnchor constant:30],
        [stackView.bottomAnchor constraintEqualToAnchor:contentView.bottomAnchor constant:-30],
        [stackView.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor constant:30],
        [stackView.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor constant:-30],
    ]];

    // Using AffirmPromotionalButton for first button (See more in configurPromotionalMessage)
    self.promotionalButton = [[AffirmPromotionalButton alloc] initWithShowCTA:YES
                                                                     pageType:AffirmPageTypeProduct
                                                     presentingViewController:self
                                                                        frame:CGRectMake(0, 0, 315, 40)];
    [stackView addArrangedSubview:self.promotionalButton];

    // Using AffirmDataHandler for second button (See more in configurPromotionalMessage)
    self.promoButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.promoButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    self.promoButton.titleLabel.numberOfLines = 0;
    [self.promoButton addTarget:self action:@selector(showPromoModal:) forControlEvents:UIControlEventTouchUpInside];
    [stackView addArrangedSubview:self.promoButton];

    self.publicKeyTextfield = [self addTextFieldRowWithTitle:@"PublicKey:   " accessibilityLabel:@"public API key input"];
    // The other rows line their text fields up with this one, so this title gives way first.
    UILabel *publicKeyLabel = ((UIStackView *)self.publicKeyTextfield.superview).arrangedSubviews.firstObject;
    [publicKeyLabel setContentCompressionResistancePriority:749 forAxis:UILayoutConstraintAxisHorizontal];
    self.amountTextField = [self addTextFieldRowWithTitle:@"Amount:" accessibilityLabel:@"price input"];
    self.amountTextField.text = @"500";
    self.amountTextField.keyboardType = UIKeyboardTypeDecimalPad;
    self.promoIDTextField = [self addTextFieldRowWithTitle:@"PromoID:" accessibilityLabel:@"promo ID input"];
    self.caasTextfield = [self addTextFieldRowWithTitle:@"CAAS:" accessibilityLabel:nil];
    [NSLayoutConstraint activateConstraints:@[
        [self.amountTextField.leadingAnchor constraintEqualToAnchor:self.publicKeyTextfield.leadingAnchor],
        [self.promoIDTextField.leadingAnchor constraintEqualToAnchor:self.publicKeyTextfield.leadingAnchor],
        [self.caasTextfield.leadingAnchor constraintEqualToAnchor:self.publicKeyTextfield.leadingAnchor],
    ]];

    [self addButtonWithTitle:@"Native → HTML render demo" action:@selector(showRenderMigrationDemo:) tintsWhenPressed:NO];
    [self addButtonWithTitle:@"Promos in a table view" action:@selector(showPromoTableDemo:) tintsWhenPressed:NO];
    [self addButtonWithTitle:@"Buy with Affirm" action:@selector(checkout:) tintsWhenPressed:YES];
    [self addButtonWithTitle:@"Failed Checkout" action:@selector(showFailedCheckout:) tintsWhenPressed:YES];
    [self addButtonWithTitle:@"Express Checkout demo" action:@selector(showExpressCheckoutDemo:) tintsWhenPressed:NO];
    UIButton *vcnButton = [self addButtonWithTitle:@"VCN Checkout" action:@selector(vcnCheckout:) tintsWhenPressed:YES];
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(showVCNEligibility:)];
    longPress.minimumPressDuration = 0.5;
    longPress.allowableMovement = 10;
    [vcnButton addGestureRecognizer:longPress];
    [self addButtonWithTitle:@"Show Product Modal" action:@selector(showProductModal:) tintsWhenPressed:NO];
    [self addButtonWithTitle:@"Track Order Confirmation" action:@selector(trackOrderConfirmation:) tintsWhenPressed:YES];
    [self addButtonWithTitle:@"Clear Cookies" action:@selector(clearCookies:) tintsWhenPressed:NO];

    self.resultLabel = [UILabel new];
    self.resultLabel.text = @"Checkout result: ";
    self.resultLabel.font = [UIFont systemFontOfSize:17];
    self.resultLabel.numberOfLines = 0;
    [stackView addArrangedSubview:self.resultLabel];
}

- (UITextField *)addTextFieldRowWithTitle:(NSString *)title accessibilityLabel:(NSString *)accessibilityLabel
{
    UILabel *label = [UILabel new];
    label.text = title;
    label.font = [UIFont systemFontOfSize:17];
    [label setContentHuggingPriority:251 forAxis:UILayoutConstraintAxisHorizontal];
    [label setContentHuggingPriority:251 forAxis:UILayoutConstraintAxisVertical];

    UITextField *textField = [UITextField new];
    textField.borderStyle = UITextBorderStyleRoundedRect;
    textField.font = [UIFont systemFontOfSize:16];
    textField.minimumFontSize = 17;
    textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    textField.returnKeyType = UIReturnKeyDone;
    textField.accessibilityLabel = accessibilityLabel;
    textField.delegate = self;

    [self.stackView addArrangedSubview:[[UIStackView alloc] initWithArrangedSubviews:@[label, textField]]];
    return textField;
}

- (UIButton *)addButtonWithTitle:(NSString *)title action:(SEL)action tintsWhenPressed:(BOOL)tintsWhenPressed
{
    UIButton *button = [(tintsWhenPressed ? [Button class] : [UIButton class]) buttonWithType:UIButtonTypeSystem];
    [button setTitle:title forState:UIControlStateNormal];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [self.stackView addArrangedSubview:button];
    return button;
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

- (void)showRenderMigrationDemo:(id)sender
{
    NSDecimalNumber *dollarPrice = [NSDecimalNumber decimalNumberWithString:self.amountTextField.text];
    if ([dollarPrice isEqualToNumber:[NSDecimalNumber notANumber]]) {
        dollarPrice = [NSDecimalNumber decimalNumberWithString:@"500"];
    }
    RenderMigrationViewController *viewController = [[RenderMigrationViewController alloc] initWithAmount:dollarPrice];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:viewController];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)showExpressCheckoutDemo:(id)sender
{
    NSDecimalNumber *dollarPrice = [NSDecimalNumber decimalNumberWithString:self.amountTextField.text];
    if ([dollarPrice isEqualToNumber:[NSDecimalNumber notANumber]]) {
        dollarPrice = [NSDecimalNumber decimalNumberWithString:@"500"];
    }
    ExpressCheckoutViewController *viewController = [[ExpressCheckoutViewController alloc] initWithAmount:dollarPrice];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:viewController];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)showPromoTableDemo:(id)sender
{
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:[PromoTableViewController new]];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)showPromoModal:(id)sender
{
    if (self.promoViewController) {
        [self presentViewController:self.promoViewController animated:YES completion:nil];
    }
}

- (void)showProductModal:(id)sender
{
    NSDecimalNumber *dollarPrice = [NSDecimalNumber decimalNumberWithString:self.amountTextField.text];
    AffirmPromoModalViewController *viewController = [[AffirmPromoModalViewController alloc] initWithPromoId:self.promoIDTextField.text
                                                                                                      amount:dollarPrice
                                                                                                    pageType:AffirmPageTypeProduct
                                                                                                    delegate:self];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:viewController];
    [self presentViewController:nav
                       animated:YES
                     completion:nil];
}

- (void)checkout:(id)sender
{
    NSDecimalNumber *dollarPrice = [NSDecimalNumber decimalNumberWithString:self.amountTextField.text];
    AffirmItem *item = [AffirmItem itemWithName:@"Affirm Test Item"
                                            SKU:@"test_item"
                                      unitPrice:dollarPrice
                                       quantity:1
                                            URL:[NSURL URLWithString:@"http://sandbox.affirm.com/item"]
                                     categories:@[[AffirmCategory categoryWithName:@"Category 1" subCategories:@[@"Apparel", @"Pants"]],
                                                  [AffirmCategory categoryWithName:@"Category 2" subCategories:@[@"Mens", @"Apparel", @"Pants"]]]];
    
    AffirmShippingDetail *shipping = [AffirmShippingDetail shippingDetailWithName:@"Chester Cheetah"
                                                                 addressWithLine1:@"633 Folsom Street"
                                                                            line2:@""
                                                                             city:@"San Francisco"
                                                                            state:@"CA"
                                                                          zipCode:@"94107"
                                                                      countryCode:@"GBR"];
    NSDictionary *metadata = @{@"shipping_type": @"UPS Ground", @"entity_name": @"internal-sub_brand-name", @"webhook_session_id": @"ABC123"};
    
    // Checkout
    AffirmCheckout *checkout = [AffirmCheckout checkoutWithItems:@[item]
                                                        shipping:shipping
                                                     totalAmount:dollarPrice
                                                        metadata:metadata];
    
    // Billing
    AffirmBillingDetail *billing = [AffirmBillingDetail billingDetailWithName:@"Chester Cheetah"
                                                                        email:@"testtester@test.com"
                                                                  phoneNumber:nil
                                                             addressWithLine1:@"633 Folsom Street"
                                                                        line2:@""
                                                                         city:@"San Francisco"
                                                                        state:@"CA"
                                                                      zipCode:@"94107"
                                                                  countryCode:@"GBR"];
    checkout.billing = billing;
    
    // CAAS
    if (self.caasTextfield.text) {
        checkout.caas = self.caasTextfield.text;
    }
    
    AffirmCheckout *_checkout = [self generateVCNCheckout];
    AffirmCheckoutViewController *checkoutViewController = [[AffirmCheckoutViewController alloc] initWithDelegate:self checkout:_checkout useVCN:NO getReasonCodes:NO cardAuthWindow:10];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:checkoutViewController];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)showFailedCheckout:(id)sender
{
    NSDecimalNumber *dollarPrice = [NSDecimalNumber decimalNumberWithString:self.amountTextField.text];
    AffirmItem *item = [AffirmItem itemWithName:@"Affirm Test Item"
                                            SKU:@"test_item"
                                      unitPrice:dollarPrice
                                       quantity:1
                                            URL:[NSURL URLWithString:@"http://sandbox.affirm.com/item"]
                                     categories:@[[AffirmCategory categoryWithName:@"Category 1" subCategories:@[@"Apparel", @"Pants"]],
                                                  [AffirmCategory categoryWithName:@"Category 2" subCategories:@[@"Mens", @"Apparel", @"Pants"]]]];
    AffirmShippingDetail *shipping = [AffirmShippingDetail shippingDetailWithName:@"Test Tester"
                                                                            email:@"testtester@test.com"
                                                                      phoneNumber:@"1111111111"
                                                                 addressWithLine1:@"633 Folsom Street"
                                                                            line2:@""
                                                                             city:@"San Francisco"
                                                                            state:@"CA"
                                                                          zipCode:@"94107"
                                                                      countryCode:@"GBR"];
    
    // Checkout
    AffirmCheckout *checkout = [AffirmCheckout checkoutWithItems:@[item]
                                                        shipping:shipping
                                                     totalAmount:dollarPrice];
    
    // CAAS
    if (self.caasTextfield.text) {
        checkout.caas = self.caasTextfield.text;
    }
    
    AffirmCheckoutViewController *checkoutViewController = [[AffirmCheckoutViewController alloc] initWithDelegate:self checkout:checkout useVCN:NO getReasonCodes:NO cardAuthWindow:10];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:checkoutViewController];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)vcnCheckout:(UIButton *)sender
{
    AffirmCheckout *checkout = [self generateVCNCheckout];
    AffirmCheckoutViewController *checkoutViewController = [[AffirmCheckoutViewController alloc] initWithDelegate:self checkout:checkout useVCN:YES getReasonCodes:YES cardAuthWindow:10];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:checkoutViewController];
    [self presentViewController:nav animated:YES completion:nil];
}

- (AffirmCheckout *)generateVCNCheckout
{
    NSDecimalNumber *dollarPrice = [NSDecimalNumber decimalNumberWithString:self.amountTextField.text];
    AffirmItem *item = [AffirmItem itemWithName:@"Affirm Test Item"
                                            SKU:@"test_item"
                                      unitPrice:dollarPrice
                                       quantity:1
                                            URL:[NSURL URLWithString:@"http://sandbox.affirm.com/item"]];
    AffirmShippingDetail *shipping = [AffirmShippingDetail shippingDetailWithName:@"Chester Cheetah"
                                                                 addressWithLine1:@"633 Folsom Street"
                                                                            line2:@""
                                                                             city:@"San Francisco"
                                                                            state:@"CA"
                                                                          zipCode:@"94107"
                                                                      countryCode:@"GBR"];
    
    // Checkout
    AffirmCheckout *checkout = [AffirmCheckout checkoutWithItems:@[item]
                                                        shipping:shipping
                                                     totalAmount:dollarPrice];
    
    // Billing
    AffirmBillingDetail *billing = [AffirmBillingDetail billingDetailWithName:nil
                                                                        email:nil
                                                                  phoneNumber:nil
                                                             addressWithLine1:nil
                                                                        line2:nil
                                                                         city:nil
                                                                        state:nil
                                                                      zipCode:nil
                                                                  countryCode:nil];
    checkout.billing = billing;
    
    // CAAS
    if (self.caasTextfield.text) {
        checkout.caas = self.caasTextfield.text;
    }
    
    return checkout;
}

- (void)showVCNEligibility:(UIGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        if ([AffirmConfiguration sharedInstance].isCreditCardExists) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                                     message:nil
                                                                              preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:@"Show credit card info"
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * _Nonnull action) {
                [self showCreditCardInfo];
            }]];
            [alertController addAction:[UIAlertAction actionWithTitle:@"Start new checkout flow"
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * _Nonnull action) {
                [self showNewVCNCheckoutFlow];
            }]];
            [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                                                style:UIAlertActionStyleCancel
                                                              handler:nil]];
            [self presentViewController:alertController animated:YES completion:nil];
        } else {
            [self showNewVCNCheckoutFlow];
        }
    }
}

- (void)showCreditCardInfo
{
    AffirmCheckout *checkout = [self generateVCNCheckout];
    AffirmCreditCard *creditCard = [AffirmConfiguration sharedInstance].creditCard;
    UINavigationController *nav = [AffirmCardInfoViewController startCheckoutWithNavigation:checkout
                                                                                 creditCard:creditCard
                                                                             getReasonCodes:YES
                                                                                   delegate:self];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)showNewVCNCheckoutFlow
{
    AffirmCheckout *checkout = [self generateVCNCheckout];
    UINavigationController *nav = [AffirmEligibilityViewController startCheckoutWithNavigation:checkout
                                                                                getReasonCodes:YES
                                                                                      delegate:self];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)trackOrderConfirmation:(id)sender
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
    [AffirmOrderTrackerViewController trackOrder:order
                                        products:@[product0, product1]];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                             message:@"Track successfully"
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK"
                                                        style:UIAlertActionStyleCancel
                                                      handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)clearCookies:(id)sender
{
    [AffirmConfiguration deleteAffirmCookies];
    [self configurPromotionalMessage];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                             message:@"Clear successfully"
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK"
                                                        style:UIAlertActionStyleCancel
                                                      handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)configurPromotionalMessage
{
    NSDecimalNumber *dollarPrice = [NSDecimalNumber decimalNumberWithString:self.amountTextField.text];
    AffirmItem *item = [AffirmItem itemWithName:@"Affirm Test Item"
                                            SKU:@"test_item"
                                      unitPrice:dollarPrice
                                       quantity:1
                                            URL:[NSURL URLWithString:@"http://sandbox.affirm.com/item"]];

    // Configure promotionalButton with native styling
    [self.promotionalButton configureWithAmount:dollarPrice items:@[item] affirmLogoType:AffirmLogoTypeName affirmColor:AffirmColorTypeBlueBlack font:[UIFont systemFontOfSize:15] textColor:[UIColor grayColor]];
    
    // Configure promotionalButton with html styling
//    NSURL *fontURL = [NSURL URLWithString:@"https://fonts.googleapis.com/css?family=Saira+Stencil+One&display=swap"];
//    NSURL *cssURL = [[NSBundle mainBundle] URLForResource:@"css_promo_sample" withExtension:@"css"];
//    [self.promotionalButton configureByHtmlStylingWithAmount:dollarPrice
//                                                       items:@[item]
//                                              affirmLogoType:AffirmLogoTypeName
//                                                 affirmColor:AffirmColorTypeBlueBlack
//                                               remoteFontURL:fontURL
//                                                remoteCssURL:cssURL];
    
    [AffirmDataHandler getPromoMessageWithPromoID:nil
                                           amount:dollarPrice
                                            items:@[item]
                                          showCTA:YES
                                         pageType:AffirmPageTypeProduct
                                         logoType:AffirmLogoTypeName
                                        colorType:AffirmColorTypeBlueBlack
                                             font:[UIFont boldSystemFontOfSize:15]
                                        textColor:[UIColor grayColor]
                         presentingViewController:self
                                   withNavigation:YES
                                    withHtmlValue:YES
                                withAccessibility:YES
                                completionHandler:^(NSAttributedString *attributedString, NSString *html, NSString *accessibilityLabel, UIViewController *viewController, NSError *error) {
        
        // Configure promotionalButton with html string manually
//        if (html) {
//            [self.promotionalButton configureWithHtmlString:html
//                                                     amount:dollarPrice
//                                              remoteFontURL:fontURL
//                                               remoteCssURL:cssURL];
//            self.promotionalButton.accessibilityLabel = accessibilityLabel;
//        }
        
        // Configure native button using attributed string
        [self.promoButton setAttributedTitle:attributedString forState:UIControlStateNormal];
        self.promoButton.accessibilityLabel = accessibilityLabel;
        
        self.promoViewController = viewController;
    }];
}

- (void)configureTextField
{
    [@[self.publicKeyTextfield, self.amountTextField, self.promoIDTextField] enumerateObjectsUsingBlock:^(UITextField * _Nonnull textField, NSUInteger idx, BOOL * _Nonnull stop) {
        UIToolbar *toolbar = [UIToolbar new];
        UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                      target:nil
                                                                                      action:nil];
        UIBarButtonItem *doneItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                  target:textField
                                                                                  action:@selector(resignFirstResponder)];
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
        AffirmConfiguration *configuration = [AffirmConfiguration sharedInstance];
        [configuration configureWithPublicKey:textField.text
                                  environment:configuration.environment
                                 merchantName:configuration.merchantName];
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
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Error"
                                                                                 message:error.localizedDescription
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"OK"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * _Nonnull action) {
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
    // VCN creation can fail before the modal transition finishes. Presenting
    // during that transition drops the alert, so wait until the checkout is on screen.
    [self presentCheckoutError:error from:checkoutViewController];
}

- (void)presentCheckoutError:(NSError *)error from:(AffirmCheckoutViewController *)checkoutViewController
{
    UIViewController *presenter = checkoutViewController.navigationController ?: checkoutViewController;
    id<UIViewControllerTransitionCoordinator> coordinator = presenter.transitionCoordinator;
    if (presenter.view.window == nil || coordinator != nil) {
        if (coordinator) {
            [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
                [self presentCheckoutError:error from:checkoutViewController];
            }];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self presentCheckoutError:error from:checkoutViewController];
            });
        }
        return;
    }
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Error"
                                                                             message:error.localizedDescription
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * _Nonnull action) {
        [checkoutViewController dismissViewControllerAnimated:YES completion:nil];
    }]];
    [presenter presentViewController:alertController animated:YES completion:nil];
}

@end
