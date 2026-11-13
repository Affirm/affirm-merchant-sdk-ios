//
//  RenderMigrationViewController.m
//  Examples
//
//  Copyright © 2026 Affirm, Inc. All rights reserved.
//

#import "RenderMigrationViewController.h"
#import <AffirmSDK/AffirmSDK.h>
#import "PromoFlagSimulator.h"

// Internal SDK diagnostics, read here only to explain what the demo shows. Not a supported API.
static NSNotificationName const RenderDidFinishNotification = @"AffirmPromoRenderDidFinish";

@interface RenderMigrationViewController () <AffirmPrequalDelegate>

@property (nonatomic, strong) NSDecimalNumber *amount;
@property (nonatomic, strong) UIStackView *stackView;
@property (nonatomic, strong) UISegmentedControl *responseControl;
@property (nonatomic, strong) UISwitch *optOutSwitch;
@property (nonatomic, strong) UISegmentedControl *fontControl;
@property (nonatomic, strong) UISegmentedControl *colorControl;
@property (nonatomic, strong) AffirmPromotionalButton *nativeAPIButton;
@property (nonatomic, strong) AffirmPromotionalButton *explicitHTMLButton;
@property (nonatomic, strong) UILabel *nativeAPIStatus;
@property (nonatomic, strong) UILabel *explicitHTMLStatus;

@end

@implementation RenderMigrationViewController

- (instancetype)initWithAmount:(NSDecimalNumber *)amount
{
    if (self = [super initWithNibName:nil bundle:nil]) {
        _amount = amount;
        self.title = @"Native → HTML render";
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                           target:self
                                                                                           action:@selector(close)];
    [self buildLayout];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(renderDidFinish:)
                                                 name:RenderDidFinishNotification
                                               object:nil];
    [self reload];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if (self.isBeingDismissed || self.navigationController.isBeingDismissed) {
        // Leave the rest of the example app talking to the real sandbox.
        PromoFlagSimulator.simulation = PromoFlagSimulationOff;
        [AffirmConfiguration sharedInstance].useLegacyNativeRendering = NO;
    }
}

- (void)close
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Layout

- (void)buildLayout
{
    UIScrollView *scrollView = [UIScrollView new];
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    [self.view addSubview:scrollView];

    UIStackView *stackView = [UIStackView new];
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.spacing = 12;
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    [scrollView addSubview:stackView];
    self.stackView = stackView;

    UILayoutGuide *content = scrollView.contentLayoutGuide;
    UILayoutGuide *frame = scrollView.frameLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [scrollView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [stackView.topAnchor constraintEqualToAnchor:content.topAnchor constant:20],
        [stackView.bottomAnchor constraintEqualToAnchor:content.bottomAnchor constant:-20],
        [stackView.leadingAnchor constraintEqualToAnchor:frame.leadingAnchor constant:20],
        [stackView.trailingAnchor constraintEqualToAnchor:frame.trailingAnchor constant:-20],
    ]];

    [self addHeader:@"Simulated server response"
               note:@"The sandbox does not send ios_sdk_migrate_native_to_html_render yet, so this demo adds it to the promo response."];
    self.responseControl = [self addSegments:@[@"As is", @"Flag on", @"Unsafe", @"HTML fails"] selected:1];

    UIStackView *optOutRow = [UIStackView new];
    optOutRow.spacing = 8;
    UILabel *optOutLabel = [self labelWithText:@"useLegacyNativeRendering (opt out)" style:UIFontTextStyleBody];
    self.optOutSwitch = [UISwitch new];
    [self.optOutSwitch addTarget:self action:@selector(reload) forControlEvents:UIControlEventValueChanged];
    [optOutRow addArrangedSubview:optOutLabel];
    [optOutRow addArrangedSubview:self.optOutSwitch];
    [self.stackView addArrangedSubview:optOutRow];

    [self addHeader:@"Native style"
               note:@"Only the system, serif and monospaced designs (regular, bold, italic, bold italic) map to HTML. Other fonts stay native."];
    self.fontControl = [self addSegments:@[@"System", @"Bold", @"Serif italic", @"Mono", @"Avenir"] selected:0];
    self.colorControl = [self addSegments:@[@"Gray", @"Indigo", @"Label"] selected:0];

    [self addHeader:@"configureWithAmount:…font:textColor:"
               note:@"Native API. Shown as HTML when the flag is on, with this font, size and color, a transparent background and no margins. Falls back to native text if the HTML fails."];
    self.nativeAPIButton = [self newPromoButton];
    self.nativeAPIStatus = [self addCardWithButton:self.nativeAPIButton];

    [self addHeader:@"configureByHtmlStylingWithAmount:…"
               note:@"Explicit HTML. Always HTML, with browser default text and margins on an opaque background. Hidden, not replaced, if the HTML fails."];
    self.explicitHTMLButton = [self newPromoButton];
    self.explicitHTMLStatus = [self addCardWithButton:self.explicitHTMLButton];
}

- (void)addHeader:(NSString *)title note:(NSString *)note
{
    UILabel *titleLabel = [self labelWithText:title style:UIFontTextStyleHeadline];
    [self.stackView addArrangedSubview:titleLabel];
    [self.stackView setCustomSpacing:4 afterView:titleLabel];
    UILabel *noteLabel = [self labelWithText:note style:UIFontTextStyleFootnote];
    noteLabel.textColor = [UIColor secondaryLabelColor];
    [self.stackView addArrangedSubview:noteLabel];
}

- (UISegmentedControl *)addSegments:(NSArray<NSString *> *)titles selected:(NSInteger)selected
{
    UISegmentedControl *control = [[UISegmentedControl alloc] initWithItems:titles];
    control.selectedSegmentIndex = selected;
    [control addTarget:self action:@selector(reload) forControlEvents:UIControlEventValueChanged];
    [self.stackView addArrangedSubview:control];
    return control;
}

- (UILabel *)labelWithText:(NSString *)text style:(UIFontTextStyle)style
{
    UILabel *label = [UILabel new];
    label.text = text;
    label.font = [UIFont preferredFontForTextStyle:style];
    label.adjustsFontForContentSizeCategory = YES;
    label.numberOfLines = 0;
    return label;
}

- (AffirmPromotionalButton *)newPromoButton
{
    AffirmPromotionalButton *button = [[AffirmPromotionalButton alloc] initWithShowCTA:YES
                                                                              pageType:AffirmPageTypeProduct
                                                              presentingViewController:self
                                                                                 frame:CGRectMake(0, 0, 315, 40)];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    return button;
}

/// The tinted card shows whether the promo's background is transparent.
- (UILabel *)addCardWithButton:(AffirmPromotionalButton *)button
{
    UIView *card = [UIView new];
    card.backgroundColor = [[UIColor systemYellowColor] colorWithAlphaComponent:0.2];
    card.layer.cornerRadius = 10;
    UILabel *status = [self labelWithText:@"" style:UIFontTextStyleCaption1];
    status.textColor = [UIColor secondaryLabelColor];
    status.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:button];
    [card addSubview:status];
    [NSLayoutConstraint activateConstraints:@[
        [button.topAnchor constraintEqualToAnchor:card.topAnchor constant:12],
        [button.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:12],
        [button.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-12],
        [status.topAnchor constraintEqualToAnchor:button.bottomAnchor constant:12],
        [status.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:12],
        [status.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-12],
        [status.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-12],
    ]];
    [self.stackView addArrangedSubview:card];
    return status;
}

#pragma mark - Rendering

- (UIFont *)selectedFont
{
    switch (self.fontControl.selectedSegmentIndex) {
        case 1:
            return [UIFont boldSystemFontOfSize:15];
        case 2: {
            UIFontDescriptor *serif = [[UIFont systemFontOfSize:16].fontDescriptor fontDescriptorWithDesign:UIFontDescriptorSystemDesignSerif];
            return [UIFont fontWithDescriptor:[serif fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitItalic] size:16];
        }
        case 3:
            return [UIFont monospacedSystemFontOfSize:14 weight:UIFontWeightRegular];
        case 4:
            return [UIFont fontWithName:@"Avenir-Medium" size:15] ?: [UIFont systemFontOfSize:15];
        default:
            return [UIFont systemFontOfSize:15];
    }
}

- (UIColor *)selectedColor
{
    switch (self.colorControl.selectedSegmentIndex) {
        case 1:
            return [UIColor systemIndigoColor];
        case 2:
            return [UIColor labelColor];
        default:
            return [UIColor grayColor];
    }
}

- (void)reload
{
    PromoFlagSimulator.simulation = (PromoFlagSimulation)self.responseControl.selectedSegmentIndex;
    [AffirmConfiguration sharedInstance].useLegacyNativeRendering = self.optOutSwitch.isOn;
    self.nativeAPIStatus.text = @"Loading…";
    self.explicitHTMLStatus.text = @"Loading…";

    [self.nativeAPIButton configureWithAmount:self.amount
                               affirmLogoType:AffirmLogoTypeName
                                  affirmColor:AffirmColorTypeBlue
                                         font:[self selectedFont]
                                    textColor:[self selectedColor]];
    [self.explicitHTMLButton configureByHtmlStylingWithAmount:self.amount
                                               affirmLogoType:AffirmLogoTypeName
                                                  affirmColor:AffirmColorTypeBlue];
}

- (void)renderDidFinish:(NSNotification *)notification
{
    UILabel *status = notification.object == self.nativeAPIButton ? self.nativeAPIStatus
        : notification.object == self.explicitHTMLButton ? self.explicitHTMLStatus
        : nil;
    NSObject *operation = notification.userInfo[@"operation"];
    NSString *state = [operation valueForKey:@"terminalState"];
    // T9: a newer configure call replaced this render; its own result follows.
    if (status == nil || [state isEqualToString:@"T9"]) {
        return;
    }
    AffirmPromotionalButton *button = notification.object;
    NSMutableArray<NSString *> *lines = [NSMutableArray arrayWithObject:
        [NSString stringWithFormat:@"Shown as: %@ (%@)", [self describeState:state], state]];
    NSString *decision = [operation valueForKey:@"decisionReason"];
    if (decision) {
        [lines addObject:[NSString stringWithFormat:@"Decision: %@", decision]];
    }
    NSString *fallback = [operation valueForKey:@"fallbackReason"] ?: [operation valueForKey:@"reason"];
    if (fallback) {
        [lines addObject:[NSString stringWithFormat:@"Reason: %@", fallback]];
    }
    if (!button.hidden) {
        [lines addObject:[NSString stringWithFormat:@"VoiceOver: \"%@\" (button)", button.accessibilityLabel ?: @""]];
    }
    status.text = [lines componentsJoinedByString:@"\n"];
}

- (NSString *)describeState:(NSString *)state
{
    NSDictionary<NSString *, NSString *> *descriptions = @{
        @"T1": @"native text",
        @"T2": @"HTML",
        @"T3": @"native text, after the HTML failed",
        @"T4": @"hidden, request failed",
        @"T5": @"hidden, HTML failed",
        @"T6": @"hidden, HTML failed and no native text",
        @"T7": @"hidden, no content",
        @"T8": @"hidden, native text failed",
    };
    return descriptions[state] ?: @"unknown";
}

#pragma mark - Affirm prequal delegate

- (void)webViewController:(nullable AffirmBaseWebViewController *)webViewController didFailWithError:(NSError *)error
{
    NSLog(@"Prequal failed with error: %@", error.userInfo);
    [webViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
