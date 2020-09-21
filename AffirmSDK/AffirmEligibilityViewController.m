//
//  AffirmEligibilityViewController.m
//  AffirmSDK
//
//  Created by Victor Zhu on 2020/9/21.
//  Copyright © 2020 Affirm, Inc. All rights reserved.
//

#import "AffirmEligibilityViewController.h"
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

@interface AffirmEligibilityViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *logoView;
@property (weak, nonatomic) IBOutlet UIView *fieldView;

@end

@implementation AffirmEligibilityViewController

- (instancetype)initWithDelegate:(id<AffirmCheckoutDelegate>)delegate
                        checkout:(AffirmCheckout *)checkout
                          useVCN:(BOOL)useVCN
                  getReasonCodes:(BOOL)getReasonCodes
{
    [AffirmValidationUtils checkNotNil:delegate name:@"checkout delegate"];
    [AffirmValidationUtils checkNotNil:checkout name:@"checkout"];

    if (self = [super initWithNibName:@"AffirmEligibilityViewController" bundle:[NSBundle sdkBundle]]) {
        _delegate = delegate;
        _checkout = [checkout copy];
        _useVCN = useVCN;
        _getReasonCodes = getReasonCodes;
    }
    return self;
}

+ (UINavigationController *)startCheckoutWithNavigation:(AffirmCheckout *)checkout
                                                 useVCN:(BOOL)useVCN
                                         getReasonCodes:(BOOL)getReasonCodes
                                               delegate:(nonnull id<AffirmCheckoutDelegate>)delegate
{
    AffirmEligibilityViewController *checkoutController = [self startCheckout:checkout useVCN:useVCN getReasonCodes:getReasonCodes delegate:delegate];
    return [[UINavigationController alloc] initWithRootViewController:checkoutController];
}

+ (AffirmEligibilityViewController *)startCheckout:(AffirmCheckout *)checkout
                                          delegate:(nonnull id<AffirmCheckoutDelegate>)delegate
{
    return [[self alloc] initWithDelegate:delegate
                                 checkout:checkout
                                   useVCN:NO
                           getReasonCodes:NO];
}

+ (AffirmEligibilityViewController *)startCheckout:(AffirmCheckout *)checkout
                                            useVCN:(BOOL)useVCN
                                          delegate:(nonnull id<AffirmCheckoutDelegate>)delegate
{
    return [[self alloc] initWithDelegate:delegate
                                 checkout:checkout
                                   useVCN:useVCN
                           getReasonCodes:NO];
}

+ (AffirmEligibilityViewController *)startCheckout:(AffirmCheckout *)checkout
                                            useVCN:(BOOL)useVCN
                                    getReasonCodes:(BOOL)getReasonCodes
                                          delegate:(nonnull id<AffirmCheckoutDelegate>)delegate
{
    return [[self alloc] initWithDelegate:delegate
                                 checkout:checkout
                                   useVCN:useVCN
                           getReasonCodes:getReasonCodes];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Close"
                                                                              style:UIBarButtonItemStyleDone
                                                                             target:self
                                                                             action:@selector(cancel:)];
    self.logoView.image = [UIImage imageNamed:@"blue-black_logo-transparent_bg" inBundle:[NSBundle resourceBundle]];
    self.fieldView.layer.masksToBounds = YES;
    self.fieldView.layer.cornerRadius = 5.0f;
    self.fieldView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.fieldView.layer.borderWidth = 1 / UIScreen.mainScreen.scale;
}

- (void)cancel:(id)sender
{
    [self.delegate checkoutCancelled:self];
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
