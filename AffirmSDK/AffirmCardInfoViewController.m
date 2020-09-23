//
//  AffirmCardInfoViewController.m
//  AffirmSDK
//
//  Created by Victor Zhu on 2020/9/22.
//  Copyright © 2020 Affirm, Inc. All rights reserved.
//

#import "AffirmCardInfoViewController.h"
#import "AffirmCreditCard.h"
#import "AffirmUtils.h"
#import "AffirmCardValidator.h"

@interface AffirmCardInfoViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *logoView;
@property (weak, nonatomic) IBOutlet UIView *cardView;
@property (weak, nonatomic) IBOutlet UILabel *cardNoLabel;
@property (weak, nonatomic) IBOutlet UILabel *expiresLabel;
@property (weak, nonatomic) IBOutlet UILabel *cvvLabel;
@property (weak, nonatomic) IBOutlet UIButton *actionButton;
@property (weak, nonatomic) IBOutlet UIButton *cardButton;

@end

@implementation AffirmCardInfoViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Close"
                                                                              style:UIBarButtonItemStyleDone
                                                                             target:self
                                                                             action:@selector(cancel:)];
    self.logoView.image = [UIImage imageNamed:@"white_logo-transparent_bg" inBundle:[NSBundle resourceBundle]];
    self.cardView.layer.masksToBounds = YES;
    self.cardView.layer.cornerRadius = 5.0f;
    self.actionButton.layer.masksToBounds = YES;
    self.actionButton.layer.cornerRadius = 5.0f;
    self.actionButton.layer.borderColor = [UIColor blueColor].CGColor;
    self.actionButton.layer.borderWidth = 1.0f;
    self.cardButton.layer.masksToBounds = YES;
    self.cardButton.layer.cornerRadius = 5.0f;
    self.cardButton.layer.borderColor = [UIColor blueColor].CGColor;
    self.cardButton.layer.borderWidth = 1.0f;
    [self setCardNo:self.creditCard.number];
    [self setExpires:self.creditCard.expiration];
    self.cvvLabel.text = self.creditCard.cvv;
}

- (void)setCardNo:(NSString *)text
{
    AffirmBrandType type = AffirmBrandTypeUnknown;
    AffirmBrand *brand = [[AffirmCardValidator sharedCardValidator] brandForCardNumber:self.creditCard.number];
    if (brand) { type = brand.type; }

    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:16], NSForegroundColorAttributeName: [UIColor whiteColor]}];
    NSArray *cardNumberFormat = [AffirmCardValidator cardNumberFormatForBrand:type];
    NSUInteger index = 0;
    for (NSNumber *segmentLength in cardNumberFormat) {
        NSUInteger segmentIndex = 0;
        for (; index < attributedString.length && segmentIndex < [segmentLength unsignedIntegerValue]; index++, segmentIndex++) {
            if (index + 1 != attributedString.length && segmentIndex + 1 == [segmentLength unsignedIntegerValue]) {
                [attributedString addAttribute:NSKernAttributeName value:@(5)
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

- (void)cancel:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)cancelCard
{

}

- (IBAction)editPressed:(id)sender
{
    UIAlertController *controller = [UIAlertController alertControllerWithTitle:nil message:@"Edit amount or cancel card" preferredStyle:UIAlertControllerStyleAlert];
    [controller addAction:[UIAlertAction actionWithTitle:@"Edit amount" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.navigationController popToRootViewControllerAnimated:YES];
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
}

@end
