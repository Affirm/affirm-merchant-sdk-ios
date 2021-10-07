//
//  AffirmEligibilityViewController.m
//  AffirmSDK
//
//  Created by Victor Zhu on 2020/9/21.
//  Copyright © 2020 Affirm, Inc. All rights reserved.
//

#import "AffirmEligibilityViewController.h"
#import "AffirmCheckoutViewController.h"
#import "AffirmActivityIndicatorView.h"
#import "AffirmPopupViewController.h"
#import "AffirmCheckoutDelegate.h"
#import "AffirmConfiguration.h"
#import "AffirmCheckout.h"
#import "AffirmCreditCard.h"
#import "AffirmClient.h"
#import "AffirmReasonCode.h"
#import "AffirmRequest.h"
#import "AffirmLogger.h"
#import "AffirmConstants.h"
#import "AffirmUtils.h"
#import "AffirmHowToViewController.h"

@interface AffirmEligibilityViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UILabel *merchantLabel;
@property (weak, nonatomic) IBOutlet UIImageView *logoView;
@property (weak, nonatomic) IBOutlet UIView *fieldView;
@property (weak, nonatomic) IBOutlet UITextField *amountField;
@property (weak, nonatomic) IBOutlet UIButton *continueButton;

@end

@implementation AffirmEligibilityViewController

- (instancetype)initWithDelegate:(id<AffirmCheckoutDelegate>)delegate
                        checkout:(AffirmCheckout *)checkout
                  getReasonCodes:(BOOL)getReasonCodes
{
    [AffirmValidationUtils checkNotNil:delegate name:@"checkout delegate"];
    [AffirmValidationUtils checkNotNil:checkout name:@"checkout"];

    if (self = [super initWithNibName:@"AffirmEligibilityViewController" bundle:[NSBundle sdkBundle]]) {
        _delegate = delegate;
        _checkout = [checkout copy];
        _getReasonCodes = getReasonCodes;
    }
    return self;
}

+ (UINavigationController *)startCheckoutWithNavigation:(AffirmCheckout *)checkout
                                         getReasonCodes:(BOOL)getReasonCodes
                                               delegate:(nonnull id<AffirmCheckoutDelegate>)delegate
{
    AffirmEligibilityViewController *checkoutController = [self startCheckout:checkout getReasonCodes:getReasonCodes delegate:delegate];
    return [[UINavigationController alloc] initWithRootViewController:checkoutController];
}

+ (AffirmEligibilityViewController *)startCheckout:(AffirmCheckout *)checkout
                                    getReasonCodes:(BOOL)getReasonCodes
                                          delegate:(nonnull id<AffirmCheckoutDelegate>)delegate
{
    return [[self alloc] initWithDelegate:delegate
                                 checkout:checkout
                           getReasonCodes:getReasonCodes];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"close_blue" ofType:@"png" inBundle:[NSBundle resourceBundle]] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStylePlain target:self action:@selector(cancel:)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"question_blue" ofType:@"png" inBundle:[NSBundle resourceBundle]] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStylePlain target:self action:@selector(question:)];
    NSString *merchantName = [AffirmConfiguration sharedInstance].merchantName;
    if (merchantName) {
        self.merchantLabel.text = [NSString stringWithFormat:@"In proud partnership with %@", merchantName];
    } else {
        self.merchantLabel.text = nil;
    }
    self.logoView.image = [UIImage imageNamed:@"blue-black_logo-transparent_bg" ofType:@"png" inBundle:[NSBundle resourceBundle]];
    NSDecimalNumber *totalAmount = self.checkout.totalAmount;
    if (totalAmount && totalAmount != NSDecimalNumber.notANumber) {
        totalAmount = [totalAmount decimalNumberByDividingBy:[NSDecimalNumber decimalNumberWithString:@"100"]];
        self.amountField.text = [totalAmount formattedString];
    } else {
        self.amountField.text = nil;
    }
    UILabel *maxAmountLabel = [UILabel new];
    maxAmountLabel.text = @"of $4,000";
    maxAmountLabel.textColor = [UIColor lightGrayColor];
    [maxAmountLabel sizeToFit];
    self.amountField.rightView = maxAmountLabel;
    self.amountField.rightViewMode = UITextFieldViewModeAlways;
    self.continueButton.layer.masksToBounds = YES;
    self.continueButton.layer.cornerRadius = 6.0f;
}

- (void)cancel:(id)sender
{
    [self.delegate checkoutCancelled:self];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)question:(id)sender
{
    AffirmHowToViewController *controller = [[AffirmHowToViewController alloc] initWithNibName:@"AffirmHowToViewController" bundle:[NSBundle sdkBundle]];
    controller.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    controller.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:controller animated:YES completion:nil];
}

- (IBAction)getStarted:(id)sender
{
    NSCAssert(self.navigationController != nil, @"The current view controller is not contained in a navigation controller.");

    NSDecimalNumber *totalAmount = [self.amountField.text currencyDecimal];
    self.checkout.totalAmount = [totalAmount decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:@"100"]];

    AffirmCheckoutViewController *controller = [AffirmCheckoutViewController startCheckout:self.checkout useVCN:YES getReasonCodes:self.getReasonCodes delegate:self.delegate];
    [self.navigationController pushViewController:controller animated:YES];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString *term = [textField.text stringByReplacingCharactersInRange:range withString:string];
    if (term.length == 0) {
        return YES;
    }

    NSDecimalNumber *number = [term currencyDecimal];
    if (number && number != [NSDecimalNumber notANumber]) {
        textField.text = [number formattedString];
    } else {
        textField.text = nil;
    }
    return NO;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

@end
