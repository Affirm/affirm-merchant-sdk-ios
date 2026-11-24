//
//  ExpressCheckoutViewController.m
//  Examples
//
//  Copyright © 2026 Affirm, Inc. All rights reserved.
//

#import "ExpressCheckoutViewController.h"
#import <AffirmSDK/AffirmSDK.h>

static NSString *const CallbackURLDefaultsKey = @"ExpressCheckoutShippingAndTotalsCallbackURL";

@interface ExpressCheckoutViewController () <AffirmCheckoutDelegate, UITextFieldDelegate>

@property (nonatomic, strong) NSDecimalNumber *amount;
@property (nonatomic, strong) UIStackView *stackView;
@property (nonatomic, strong) UITextField *callbackURLTextField;
@property (nonatomic, strong) AffirmCheckoutButton *defaultButton;
@property (nonatomic, strong) AffirmCheckoutButton *styledButton;
@property (nonatomic, strong) UISegmentedControl *sizeControl;
@property (nonatomic, strong) UISegmentedControl *themeControl;
@property (nonatomic, strong) UISegmentedControl *shapeControl;
@property (nonatomic, strong) UISegmentedControl *textControl;
@property (nonatomic, strong) UISwitch *fullWidthSwitch;
@property (nonatomic, strong) UIView *styledButtonBackground;
@property (nonatomic, strong) UILabel *resultLabel;

@end

@implementation ExpressCheckoutViewController

- (instancetype)initWithAmount:(NSDecimalNumber *)amount
{
    if (self = [super initWithNibName:nil bundle:nil]) {
        _amount = amount;
        self.title = @"Express Checkout";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                           target:self
                                                                                           action:@selector(close)];
    [self buildLayout];
}

#pragma mark - Layout

- (void)buildLayout
{
    UIScrollView *scrollView = [UIScrollView new];
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    [self.view addSubview:scrollView];

    UIStackView *stackView = [UIStackView new];
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.alignment = UIStackViewAlignmentFill;
    stackView.spacing = 12;
    [scrollView addSubview:stackView];
    self.stackView = stackView;

    UILayoutGuide *safeArea = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [scrollView.topAnchor constraintEqualToAnchor:safeArea.topAnchor],
        [scrollView.bottomAnchor constraintEqualToAnchor:safeArea.bottomAnchor],
        [scrollView.leadingAnchor constraintEqualToAnchor:safeArea.leadingAnchor],
        [scrollView.trailingAnchor constraintEqualToAnchor:safeArea.trailingAnchor],
        [stackView.topAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.topAnchor constant:20],
        [stackView.bottomAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.bottomAnchor constant:-20],
        [stackView.leadingAnchor constraintEqualToAnchor:scrollView.frameLayoutGuide.leadingAnchor constant:20],
        [stackView.trailingAnchor constraintEqualToAnchor:scrollView.frameLayoutGuide.trailingAnchor constant:-20],
    ]];

    [self addNote:[NSString stringWithFormat:@"Public key: %@\nThe merchant must have Express Checkout enabled and a Shipping & Totals endpoint.", [AffirmConfiguration sharedInstance].publicKey]];

    self.callbackURLTextField = [UITextField new];
    self.callbackURLTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.callbackURLTextField.placeholder = @"https://merchant.com/shipping-and-totals";
    self.callbackURLTextField.keyboardType = UIKeyboardTypeURL;
    self.callbackURLTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.callbackURLTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.callbackURLTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.callbackURLTextField.returnKeyType = UIReturnKeyDone;
    self.callbackURLTextField.accessibilityLabel = @"Shipping and totals URL input";
    self.callbackURLTextField.text = [[NSUserDefaults standardUserDefaults] stringForKey:CallbackURLDefaultsKey];
    self.callbackURLTextField.delegate = self;
    [self addTitle:@"Shipping & Totals URL"];
    [self.stackView addArrangedSubview:self.callbackURLTextField];

    [self addTitle:@"Default button"];
    self.defaultButton = [[AffirmCheckoutButton alloc] initWithPageType:AffirmPageTypeProduct frame:CGRectZero];
    [self.defaultButton addTarget:self action:@selector(startExpressCheckout:) forControlEvents:UIControlEventTouchUpInside];
    [self.stackView addArrangedSubview:[self centered:self.defaultButton background:nil]];

    [self addTitle:@"Styled button"];
    self.sizeControl = [self addSegmentedControlWithItems:@[@"Small", @"Medium", @"Large"] selected:AffirmCheckoutButtonSizeMedium];
    self.themeControl = [self addSegmentedControlWithItems:@[@"Dark", @"Light"] selected:AffirmCheckoutButtonThemeDark];
    self.shapeControl = [self addSegmentedControlWithItems:@[@"Sharp", @"Pill", @"Rounded"] selected:AffirmCheckoutButtonShapePill];
    self.textControl = [self addSegmentedControlWithItems:@[@"Buy now", @"Checkout", @"Logo"] selected:AffirmCheckoutButtonTextTypeBuyNow];

    UILabel *fullWidthLabel = [UILabel new];
    fullWidthLabel.text = @"Full width";
    self.fullWidthSwitch = [UISwitch new];
    [self.fullWidthSwitch addTarget:self action:@selector(styleChanged) forControlEvents:UIControlEventValueChanged];
    [self.stackView addArrangedSubview:[[UIStackView alloc] initWithArrangedSubviews:@[fullWidthLabel, self.fullWidthSwitch]]];

    self.styledButton = [[AffirmCheckoutButton alloc] initWithPageType:AffirmPageTypeProduct frame:CGRectZero];
    [self.styledButton addTarget:self action:@selector(startExpressCheckout:) forControlEvents:UIControlEventTouchUpInside];
    // The light theme has no border, so it sits on a tinted background to stay visible.
    self.styledButtonBackground = [UIView new];
    self.styledButtonBackground.backgroundColor = [UIColor secondarySystemBackgroundColor];
    self.styledButtonBackground.layer.cornerRadius = 12;
    [self.stackView addArrangedSubview:[self centered:self.styledButton background:self.styledButtonBackground]];

    self.resultLabel = [UILabel new];
    self.resultLabel.numberOfLines = 0;
    self.resultLabel.text = @"Checkout result: ";
    self.resultLabel.accessibilityIdentifier = @"express checkout result";
    [self.stackView addArrangedSubview:self.resultLabel];
}

- (void)addTitle:(NSString *)title
{
    UILabel *label = [UILabel new];
    label.text = title;
    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    [self.stackView addArrangedSubview:label];
}

- (void)addNote:(NSString *)note
{
    UILabel *label = [UILabel new];
    label.text = note;
    label.numberOfLines = 0;
    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    label.textColor = [UIColor secondaryLabelColor];
    [self.stackView addArrangedSubview:label];
}

- (UISegmentedControl *)addSegmentedControlWithItems:(NSArray<NSString *> *)items selected:(NSInteger)selected
{
    UISegmentedControl *control = [[UISegmentedControl alloc] initWithItems:items];
    control.selectedSegmentIndex = selected;
    [control addTarget:self action:@selector(styleChanged) forControlEvents:UIControlEventValueChanged];
    [self.stackView addArrangedSubview:control];
    return control;
}

/// Centers the button, or stretches it when it is full width, in a padded container.
- (UIView *)centered:(AffirmCheckoutButton *)button background:(nullable UIView *)background
{
    UIView *container = background ?: [UIView new];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [container addSubview:button];
    NSLayoutConstraint *stretch = [button.widthAnchor constraintEqualToAnchor:container.widthAnchor constant:-32];
    // Below the button's content hugging, so it only stretches when it is full width.
    stretch.priority = UILayoutPriorityDefaultLow - 1;
    [NSLayoutConstraint activateConstraints:@[
        [button.topAnchor constraintEqualToAnchor:container.topAnchor constant:16],
        [button.bottomAnchor constraintEqualToAnchor:container.bottomAnchor constant:-16],
        [button.centerXAnchor constraintEqualToAnchor:container.centerXAnchor],
        [button.leadingAnchor constraintGreaterThanOrEqualToAnchor:container.leadingAnchor constant:16],
        stretch,
    ]];
    return container;
}

#pragma mark - Actions

- (void)close
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)styleChanged
{
    self.styledButton.size = self.sizeControl.selectedSegmentIndex;
    self.styledButton.theme = self.themeControl.selectedSegmentIndex;
    self.styledButton.shape = self.shapeControl.selectedSegmentIndex;
    self.styledButton.buttonText = self.textControl.selectedSegmentIndex;
    self.styledButton.fullWidth = self.fullWidthSwitch.on;
    self.styledButtonBackground.backgroundColor = self.styledButton.theme == AffirmCheckoutButtonThemeLight ? [UIColor systemGray4Color] : [UIColor secondarySystemBackgroundColor];
}

- (void)setButtonsEnabled:(BOOL)enabled
{
    self.defaultButton.enabled = enabled;
    self.styledButton.enabled = enabled;
}

- (void)startExpressCheckout:(AffirmCheckoutButton *)sender
{
    [self.view endEditing:YES];
    NSString *callbackURL = [self.callbackURLTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (callbackURL.length == 0) {
        [self showAlertWithTitle:@"Shipping & Totals URL required" message:@"Express Checkout gets shipping, tax and the total from your Shipping & Totals endpoint."];
        return;
    }
    [[NSUserDefaults standardUserDefaults] setObject:callbackURL forKey:CallbackURLDefaultsKey];

    AffirmItem *item = [AffirmItem itemWithName:@"Affirm Test Item"
                                            SKU:@"test_item"
                                      unitPrice:self.amount
                                       quantity:1
                                            URL:[NSURL URLWithString:@"http://sandbox.affirm.com/item"]];
    // The subtotal of the items, in cents, as a string.
    NSString *subtotal = [[self.amount decimalNumberByMultiplyingByPowerOf10:2] stringValue];
    NSError *error;
    AffirmCheckout *checkout = [AffirmCheckout expressCheckoutWithItems:@[item]
                                                                orderId:[NSUUID UUID].UUIDString
                                           shippingAndTotalsCallbackURL:callbackURL
                                                               metadata:@{@"subtotal": subtotal}
                                                                  error:&error];
    if (!checkout) {
        [self showAlertWithTitle:@"Can't start Express Checkout" message:error.localizedDescription];
        return;
    }

    [self setButtonsEnabled:NO];
    AffirmCheckoutViewController *controller = [[AffirmCheckoutViewController alloc] initWithDelegate:self
                                                                                              checkout:checkout
                                                                                                useVCN:NO
                                                                                        getReasonCodes:NO];
    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:controller] animated:YES completion:nil];
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - AffirmCheckoutDelegate

- (void)checkout:(AffirmCheckoutViewController *)checkoutViewController completedWithToken:(NSString *)checkoutToken
{
    // Forward the token to your server, which authorizes it with Affirm.
    self.resultLabel.text = [NSString stringWithFormat:@"Received token:\n%@", checkoutToken];
    [self setButtonsEnabled:YES];
    [checkoutViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)vcnCheckout:(UIViewController *)checkoutViewController completedWithCreditCard:(AffirmCreditCard *)creditCard
{
    // Express Checkout does not support VCN.
}

- (void)checkoutCancelled:(UIViewController *)checkoutViewController
{
    self.resultLabel.text = @"Checkout was cancelled";
    [self setButtonsEnabled:YES];
    [checkoutViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)checkoutCancelled:(AffirmCheckoutViewController *)checkoutViewController checkoutCanceledWithReason:(AffirmReasonCode *)reasonCode
{
    self.resultLabel.text = [NSString stringWithFormat:@"Checkout was cancelled: %@", reasonCode.reason];
    [self setButtonsEnabled:YES];
    [checkoutViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)checkout:(AffirmCheckoutViewController *)checkoutViewController didFailWithError:(NSError *)error
{
    self.resultLabel.text = [NSString stringWithFormat:@"Checkout failed:\n%@", error.localizedDescription];
    [self setButtonsEnabled:YES];
    [checkoutViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
