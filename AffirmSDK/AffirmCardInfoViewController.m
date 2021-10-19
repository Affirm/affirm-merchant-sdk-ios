//
//  AffirmCardInfoViewController.m
//  AffirmSDK
//
//  Created by Victor Zhu on 2020/9/22.
//  Copyright © 2020 Affirm, Inc. All rights reserved.
//

#import "AffirmCardInfoViewController.h"
#import "AffirmConfiguration.h"
#import "AffirmCreditCard.h"
#import "AffirmCheckout.h"
#import "AffirmUtils.h"
#import "AffirmCardValidator.h"
#import "AffirmRequest.h"
#import "AffirmClient.h"
#import "AffirmLogger.h"
#import "AffirmEligibilityViewController.h"
#import "AffirmActivityIndicatorView.h"
#import "AffirmHowToViewController.h"
#import "AffirmCheckoutViewController.h"
#import "AffirmCheckoutDelegate.h"


@interface AffirmConfiguration ()

- (void)updateCreditCard:(AffirmCreditCard *)creditCard;

@end

@interface AffirmEligibilityViewController ()

+ (AffirmEligibilityViewController *)startCheckout:(AffirmCheckout *)checkout
                                    getReasonCodes:(BOOL)getReasonCodes
                                          delegate:(nonnull id<AffirmCheckoutDelegate>)delegate;

@end

@interface AffirmCardInfoViewController ()

@property (weak, nonatomic) IBOutlet UILabel *amountLabel;
@property (weak, nonatomic) IBOutlet UIImageView *logoView;
@property (weak, nonatomic) IBOutlet UIView *cardBackView;
@property (weak, nonatomic) IBOutlet UIView *cardView;
@property (weak, nonatomic) IBOutlet UILabel *cardNoLabel;
@property (weak, nonatomic) IBOutlet UILabel *expiresLabel;
@property (weak, nonatomic) IBOutlet UILabel *cvvLabel;
@property (weak, nonatomic) IBOutlet UIImageView *cardLogoView;
@property (weak, nonatomic) IBOutlet UIButton *actionButton;
@property (weak, nonatomic) IBOutlet UIButton *cardButton;
@property (weak, nonatomic) IBOutlet UIButton *infoButton;
@property (nonatomic, strong) AffirmActivityIndicatorView *activityIndicatorView;
@property (weak, nonatomic) IBOutlet UIImageView *backLogoView;
@property (weak, nonatomic) IBOutlet UIButton *rightButton;
@property (weak, nonatomic) IBOutlet UILabel *holderLabel;
@property (weak, nonatomic) IBOutlet UILabel *tipLabel;
@property (weak, nonatomic) IBOutlet UILabel *timerLabel;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *timerTopLayoutToCard;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *timerTopLayoutToTip;

@property (nonatomic, strong) NSTimer *timer;

@end

@implementation AffirmCardInfoViewController

- (instancetype)initWithDelegate:(id<AffirmCheckoutDelegate>)delegate
                        checkout:(AffirmCheckout *)checkout
                      creditCard:(AffirmCreditCard *)creditCard
                  getReasonCodes:(BOOL)getReasonCodes
{
    [AffirmValidationUtils checkNotNil:delegate name:@"checkout delegate"];
    [AffirmValidationUtils checkNotNil:checkout name:@"checkout"];

    if (self = [super initWithNibName:@"AffirmCardInfoViewController" bundle:[NSBundle sdkBundle]]) {
        _delegate = delegate;
        _checkout = [checkout copy];
        _creditCard = creditCard;
        _getReasonCodes = getReasonCodes;
    }
    return self;
}

+ (UINavigationController *)startCheckoutWithNavigation:(AffirmCheckout *)checkout
                                             creditCard:(AffirmCreditCard *)creditCard
                                         getReasonCodes:(BOOL)getReasonCodes
                                               delegate:(nonnull id<AffirmCheckoutDelegate>)delegate
{
    AffirmCardInfoViewController *checkoutController = [self startCheckout:checkout
                                                                creditCard:creditCard
                                                            getReasonCodes:getReasonCodes
                                                                  delegate:delegate];
    return [[UINavigationController alloc] initWithRootViewController:checkoutController];
}

+ (AffirmCardInfoViewController *)startCheckout:(AffirmCheckout *)checkout
                                     creditCard:(AffirmCreditCard *)creditCard
                                 getReasonCodes:(BOOL)getReasonCodes
                                       delegate:(nonnull id<AffirmCheckoutDelegate>)delegate
{
    return [[self alloc] initWithDelegate:delegate
                                 checkout:checkout
                               creditCard:(AffirmCreditCard *)creditCard
                           getReasonCodes:getReasonCodes];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.navigationItem setHidesBackButton:YES];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"close_grey" ofType:@"png" inBundle:[NSBundle resourceBundle]] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStylePlain target:self action:@selector(cancel:)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"question_dark" ofType:@"png" inBundle:[NSBundle resourceBundle]] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStylePlain target:self action:@selector(question:)];

    NSDecimalNumber *totalAmount = self.checkout.totalAmount;
    if (totalAmount && totalAmount != NSDecimalNumber.notANumber) {
        totalAmount = [totalAmount decimalNumberByDividingBy:[NSDecimalNumber decimalNumberWithString:@"100"]];
        self.amountLabel.text = totalAmount.formattedString;
    } else {
        self.amountLabel.text = nil;
    }

    self.logoView.image = [UIImage imageNamed:@"white_logo-transparent_bg" ofType:@"png" inBundle:[NSBundle resourceBundle]];
    self.cardView.layer.masksToBounds = YES;
    self.cardView.layer.cornerRadius = 16.0f;

    self.cardBackView.layer.masksToBounds = YES;
    self.cardBackView.layer.cornerRadius = 16.0f;
    self.cardBackView.layer.borderColor = [UIColor darkGrayColor].CGColor;
    self.cardBackView.layer.borderWidth = 1 / [UIScreen mainScreen].scale;

    self.backLogoView.image = [UIImage imageNamed:@"blue-black_logo-transparent_bg" ofType:@"png" inBundle:[NSBundle resourceBundle]];
    [self.rightButton setImage:[UIImage imageNamed:@"right" ofType:@"png" inBundle:[NSBundle resourceBundle]] forState:UIControlStateNormal];
    self.holderLabel.text = [NSString stringWithFormat:@"Authorized Cardholder: %@", self.creditCard.cardholderName];

    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = self.cardView.bounds;
    gradient.colors = @[(id)[UIColor colorWithWhite:1 alpha:0.32].CGColor, (id)[UIColor colorWithRed:35.0f/255.0f green:41.0f/255.0f blue:47.0f/255.0f alpha:0.0001].CGColor];
    gradient.startPoint = CGPointMake(0.07245350629091263, 0.2407626062631607);
    gradient.endPoint = CGPointMake(0.927546501159668, 0.7592374086380005);
    gradient.locations = @[@0, @0.9898];
    [self.cardView.layer insertSublayer:gradient atIndex:0];

    self.cardButton.layer.masksToBounds = YES;
    self.cardButton.layer.cornerRadius = 6.0f;
    [self setCardNo:self.creditCard.number];
    [self setExpires:self.creditCard.expiration];
    self.cvvLabel.text = self.creditCard.cvv;

    [self.infoButton setImage:[UIImage imageNamed:@"info" ofType:@"png" inBundle:[NSBundle resourceBundle]] forState:UIControlStateNormal];

    AffirmActivityIndicatorView *activityIndicatorView = [[AffirmActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 80, 80)];
    [self.view addSubview:activityIndicatorView];
    self.activityIndicatorView = activityIndicatorView;

    self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(setTimerText) userInfo: nil repeats:YES];
    
    NSString *tipText = AffirmConfiguration.sharedInstance.cardTip;
    self.timerTopLayoutToCard.constant = 15;
    if (tipText && tipText.length > 0) {
        self.tipLabel.text = tipText;
        self.timerTopLayoutToCard.active = NO;
        self.timerTopLayoutToTip.active = YES;
    } else {
        self.timerTopLayoutToCard.active = YES;
        self.timerTopLayoutToTip.active = NO;
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.activityIndicatorView.center = self.view.center;
}

- (void)dealloc
{
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

- (void)setCardNo:(NSString *)text
{
    AffirmBrandType type = AffirmBrandTypeUnknown;
    AffirmBrand *brand = [[AffirmCardValidator sharedCardValidator] brandForCardNumber:self.creditCard.number];
    if (brand) { type = brand.type; }

    self.cardLogoView.image = [UIImage imageNamed:type == AffirmBrandTypeVisa ? @"visa" : @"mastercard" ofType:@"png" inBundle:[NSBundle resourceBundle]];

    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text attributes:@{NSFontAttributeName: [UIFont fontWithName:AffirmFontNameAlmaMonoBold size:24], NSForegroundColorAttributeName: [UIColor whiteColor]}];
    NSArray *cardNumberFormat = [AffirmCardValidator cardNumberFormatForBrand:type];
    NSUInteger index = 0;
    for (NSNumber *segmentLength in cardNumberFormat) {
        NSUInteger segmentIndex = 0;
        for (; index < attributedString.length && segmentIndex < [segmentLength unsignedIntegerValue]; index++, segmentIndex++) {
            if (index + 1 != attributedString.length && segmentIndex + 1 == [segmentLength unsignedIntegerValue]) {
                [attributedString addAttribute:NSKernAttributeName value:@(10)
                                         range:NSMakeRange(index, 1)];
            } else {
                [attributedString addAttribute:NSKernAttributeName value:@(0)
                                         range:NSMakeRange(index, 1)];
            }
        }
    }
    self.cardNoLabel.attributedText = attributedString;
}

- (void)setExpires:(NSString *)text
{
    NSString *_text = text;
    NSString *expirationMonth = [_text substringToIndex:MIN(_text.length, 2)];
    NSString *expirationYear = _text.length < 2 ? @"" : [_text substringFromIndex:2];
    if (expirationYear) {
        expirationYear = [expirationYear stringByRemovingIllegalCharacters];
        expirationYear = [expirationYear substringToIndex:MIN(expirationYear.length, 4)];
    }

    if (expirationMonth.length == 1 && ![expirationMonth isEqualToString:@"0"] && ![expirationMonth isEqualToString:@"1"]) {
        expirationMonth = [NSString stringWithFormat:@"0%@", text];
    }

    NSMutableArray *array = [NSMutableArray array];
    if (expirationMonth && ![expirationMonth isEqualToString:@""]) {
        [array addObject:expirationMonth];
    }
    if (expirationMonth.length == 2 && expirationMonth.integerValue > 0 && expirationMonth.integerValue <= 12) {
        [array addObject:expirationYear];
    }

    _text = [array componentsJoinedByString:@"/"];
    self.expiresLabel.text = _text;
}

- (void)setTimerText
{
    NSTimeInterval seconds = [self.creditCard.expiredDate timeIntervalSinceNow];
    if (seconds > 0) {
        NSString *hour = [NSString stringWithFormat:@"%02d", (int)seconds / 3600];
        NSString *min = [NSString stringWithFormat:@"%02d", ((int)seconds % 3600) / 60];
        NSString *sec = [NSString stringWithFormat:@"%02d", (int)seconds % 60];
        NSString *time = [NSString stringWithFormat:@"%@:%@:%@", hour, min, sec];

        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = [NSString stringWithFormat:@"HH:mm:ss"];
        self.timerLabel.text = [NSString stringWithFormat:@"This card is valid for %@", time];
    } else {
        self.timerLabel.text = @"00:00:00";
        [self.timer invalidate];
        self.timer = nil;

        UIAlertController *controller = [UIAlertController alertControllerWithTitle:nil message:@"This card is expired." preferredStyle:UIAlertControllerStyleAlert];
        [controller addAction:[UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [self dismissViewControllerAnimated:YES completion:nil];
        }]];
        [self presentViewController:controller animated:YES completion:nil];
    }
}

- (void)cancel:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)cancelCard
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)question:(id)sender
{
    AffirmHowToViewController *controller = [[AffirmHowToViewController alloc] initWithNibName:@"AffirmHowToViewController" bundle:[NSBundle sdkBundle]];
    controller.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    controller.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:controller animated:YES completion:nil];
}

- (IBAction)infoPressed:(id)sender
{
    [UIView transitionWithView:self.cardView duration:0.25 options:UIViewAnimationOptionTransitionFlipFromRight | UIViewAnimationOptionShowHideTransitionViews animations:^{
        self.cardView.alpha = 0;
    } completion:nil];

    [UIView transitionWithView:self.cardBackView duration:0.25 options:UIViewAnimationOptionTransitionFlipFromRight | UIViewAnimationOptionShowHideTransitionViews animations:^{
        self.cardBackView.alpha = 1;
    } completion:nil];
}

- (IBAction)flipBack:(id)sender
{
    [UIView transitionWithView:self.cardView duration:0.25 options:UIViewAnimationOptionTransitionFlipFromLeft | UIViewAnimationOptionShowHideTransitionViews animations:^{
        self.cardView.alpha = 1;
    } completion:nil];

    [UIView transitionWithView:self.cardBackView duration:0.25 options:UIViewAnimationOptionTransitionFlipFromLeft | UIViewAnimationOptionShowHideTransitionViews animations:^{
        self.cardBackView.alpha = 0;
    } completion:nil];
}

- (IBAction)editPressed:(id)sender
{
    UIAlertController *controller = [UIAlertController alertControllerWithTitle:nil message:@"Edit amount or cancel card" preferredStyle:UIAlertControllerStyleAlert];
    [controller addAction:[UIAlertAction actionWithTitle:@"Edit amount" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if ([self.navigationController.viewControllers.firstObject isKindOfClass:[AffirmEligibilityViewController class]]) {
            [self.navigationController popToRootViewControllerAnimated:YES];
        } else {
            AffirmEligibilityViewController *controller = [AffirmEligibilityViewController startCheckout:self.checkout
                                                                                          getReasonCodes:self.getReasonCodes
                                                                                                delegate:self.delegate];
            [self.navigationController pushViewController:controller animated:YES];
        }
    }]];
    [controller addAction:[UIAlertAction actionWithTitle:@"Cancel card" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self cancelCard];
    }]];
    [controller addAction:[UIAlertAction actionWithTitle:@"Never mind" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:controller animated:YES completion:nil];
}

- (IBAction)copyCardPressed:(id)sender
{
    [[UIPasteboard generalPasteboard] setString:self.creditCard.number];
    
    [self.delegate vcnCheckout:self
       completedWithCreditCard:self.creditCard];
}

@end
