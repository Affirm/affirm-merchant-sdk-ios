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
