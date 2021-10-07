//
//  AffirmHowToViewController.m
//  AffirmSDK
//
//  Created by Victor Zhu on 2020/9/25.
//  Copyright © 2020 Affirm, Inc. All rights reserved.
//

#import "AffirmHowToViewController.h"
#import "AffirmUtils.h"

@interface AffirmHowToViewController ()

@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UIImageView *logoView;
@property (weak, nonatomic) IBOutlet UIButton *gotItButton;

@end

@implementation AffirmHowToViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.contentView.layer.masksToBounds = YES;
    self.contentView.layer.cornerRadius = 6.0f;

    self.logoView.image = [UIImage imageNamed:@"online" ofType:@"png" inBundle:[NSBundle resourceBundle]];

    self.gotItButton.layer.masksToBounds = YES;
    self.gotItButton.layer.cornerRadius = 6.0f;
}

- (IBAction)gotItPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
