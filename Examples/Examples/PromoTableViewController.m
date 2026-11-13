//
//  PromoTableViewController.m
//  Examples
//
//  Copyright © 2026 Affirm, Inc. All rights reserved.
//

#import "PromoTableViewController.h"
#import <AffirmSDK/AffirmSDK.h>
#import "PromoFlagSimulator.h"

// Internal SDK diagnostics, read here only to explain what the demo shows. Not a supported API.
static NSNotificationName const RenderDidFinishNotification = @"AffirmPromoRenderDidFinish";
static NSString *const PromoCellIdentifier = @"PromoCell";
static const NSInteger PromoRowCount = 100;

#pragma mark - Cell

@interface PromoTableCell : UITableViewCell

@property (nonatomic, readonly) NSInteger serial;
@property (nonatomic) NSInteger reuseCount;
@property (nonatomic, strong, readonly) AffirmPromotionalButton *promoButton;
@property (nonatomic, strong, readonly) UILabel *titleLabel;
@property (nonatomic, strong, readonly) UILabel *cellLabel;
@property (nonatomic, strong, readonly) UILabel *statusLabel;

@end

@implementation PromoTableCell

- (instancetype)initWithSerial:(NSInteger)serial presenter:(UIViewController<AffirmPrequalDelegate> *)presenter
{
    if (self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:PromoCellIdentifier]) {
        _serial = serial;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.clipsToBounds = YES;

        _titleLabel = [UILabel new];
        _titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
        _cellLabel = [UILabel new];
        _cellLabel.font = [UIFont monospacedDigitSystemFontOfSize:12 weight:UIFontWeightRegular];
        _cellLabel.textColor = [UIColor systemOrangeColor];
        _cellLabel.textAlignment = NSTextAlignmentRight;
        _statusLabel = [UILabel new];
        _statusLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
        _statusLabel.textColor = [UIColor secondaryLabelColor];
        // Created once with the cell; reuse configures this same button again.
        _promoButton = [[AffirmPromotionalButton alloc] initWithShowCTA:YES
                                                               pageType:AffirmPageTypeProduct
                                               presentingViewController:presenter
                                                                  frame:CGRectMake(0, 0, 315, 40)];

        for (UIView *view in @[_titleLabel, _cellLabel, _statusLabel, _promoButton]) {
            view.translatesAutoresizingMaskIntoConstraints = NO;
            [self.contentView addSubview:view];
        }
        UILayoutGuide *margins = self.contentView.layoutMarginsGuide;
        [NSLayoutConstraint activateConstraints:@[
            [_titleLabel.topAnchor constraintEqualToAnchor:margins.topAnchor],
            [_titleLabel.leadingAnchor constraintEqualToAnchor:margins.leadingAnchor],
            [_cellLabel.firstBaselineAnchor constraintEqualToAnchor:_titleLabel.firstBaselineAnchor],
            [_cellLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:_titleLabel.trailingAnchor constant:8],
            [_cellLabel.trailingAnchor constraintEqualToAnchor:margins.trailingAnchor],
            [_promoButton.topAnchor constraintEqualToAnchor:_titleLabel.bottomAnchor constant:6],
            [_promoButton.leadingAnchor constraintEqualToAnchor:margins.leadingAnchor],
            [_promoButton.trailingAnchor constraintEqualToAnchor:margins.trailingAnchor],
            [_statusLabel.topAnchor constraintEqualToAnchor:_promoButton.bottomAnchor constant:6],
            [_statusLabel.leadingAnchor constraintEqualToAnchor:margins.leadingAnchor],
            [_statusLabel.trailingAnchor constraintEqualToAnchor:margins.trailingAnchor],
            [_statusLabel.bottomAnchor constraintLessThanOrEqualToAnchor:margins.bottomAnchor],
        ]];
    }
    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.reuseCount += 1;
}

@end

#pragma mark - View controller

@interface PromoTableViewController () <UITableViewDataSource, AffirmPrequalDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UILabel *statsLabel;
@property (nonatomic, strong) NSNumberFormatter *currencyFormatter;
/// Promo button → its cell, to route render results to the row on screen.
@property (nonatomic, strong) NSMapTable<AffirmPromotionalButton *, PromoTableCell *> *cellsByButton;
@property (nonatomic) NSInteger createdCount;
@property (nonatomic) NSInteger reusedCount;
@property (nonatomic) NSInteger configureCount;
@property (nonatomic) NSInteger finishedCount;
@property (nonatomic) NSInteger supersededCount;

@end

@implementation PromoTableViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Promos in a table view";
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                           target:self
                                                                                           action:@selector(close)];
    self.cellsByButton = [NSMapTable weakToWeakObjectsMapTable];
    self.currencyFormatter = [NSNumberFormatter new];
    self.currencyFormatter.numberStyle = NSNumberFormatterCurrencyStyle;
    self.currencyFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US"];
    self.currencyFormatter.maximumFractionDigits = 0;

    UISegmentedControl *renderControl = [[UISegmentedControl alloc] initWithItems:@[@"Native", @"HTML (flag on)"]];
    renderControl.selectedSegmentIndex = 1;
    [renderControl addTarget:self action:@selector(renderModeChanged:) forControlEvents:UIControlEventValueChanged];

    self.statsLabel = [UILabel new];
    self.statsLabel.font = [UIFont monospacedDigitSystemFontOfSize:12 weight:UIFontWeightRegular];
    self.statsLabel.textColor = [UIColor secondaryLabelColor];
    self.statsLabel.numberOfLines = 0;

    UILabel *note = [UILabel new];
    note.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    note.textColor = [UIColor secondaryLabelColor];
    note.numberOfLines = 0;
    note.text = @"Each row has its own amount. Only the cells on screen exist; scrolling reuses them, and each reused cell configures its one promo button again. A render still in flight for the old row is superseded, and its late reply is ignored.";

    UIStackView *header = [[UIStackView alloc] initWithArrangedSubviews:@[renderControl, note, self.statsLabel]];
    header.axis = UILayoutConstraintAxisVertical;
    header.spacing = 8;
    header.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:header];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.dataSource = self;
    // A fixed height keeps scrolling steady while promos finish at different times.
    self.tableView.rowHeight = 132;
    [self.view addSubview:self.tableView];

    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [header.topAnchor constraintEqualToAnchor:safe.topAnchor constant:12],
        [header.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:20],
        [header.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-20],
        [self.tableView.topAnchor constraintEqualToAnchor:header.bottomAnchor constant:8],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(renderDidFinish:)
                                                 name:RenderDidFinishNotification
                                               object:nil];
    PromoFlagSimulator.simulation = PromoFlagSimulationFlagOn;
    [self updateStats];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if (self.isBeingDismissed || self.navigationController.isBeingDismissed) {
        PromoFlagSimulator.simulation = PromoFlagSimulationOff;
    }
}

- (void)close
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)renderModeChanged:(UISegmentedControl *)control
{
    PromoFlagSimulator.simulation = control.selectedSegmentIndex == 1 ? PromoFlagSimulationFlagOn : PromoFlagSimulationOff;
    [self.tableView reloadData];
}

- (NSDecimalNumber *)amountForRow:(NSInteger)row
{
    return [NSDecimalNumber decimalNumberWithMantissa:100 + row * 45 exponent:0 isNegative:NO];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return PromoRowCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PromoTableCell *cell = [tableView dequeueReusableCellWithIdentifier:PromoCellIdentifier];
    if (cell == nil) {
        self.createdCount += 1;
        cell = [[PromoTableCell alloc] initWithSerial:self.createdCount presenter:self];
        [self.cellsByButton setObject:cell forKey:cell.promoButton];
    } else {
        self.reusedCount += 1;
    }

    NSDecimalNumber *amount = [self amountForRow:indexPath.row];
    NSString *price = [self.currencyFormatter stringFromNumber:amount];
    cell.titleLabel.text = [NSString stringWithFormat:@"Row %ld · %@", (long)indexPath.row, price];
    cell.cellLabel.text = cell.reuseCount == 0
        ? [NSString stringWithFormat:@"cell #%ld · new", (long)cell.serial]
        : [NSString stringWithFormat:@"cell #%ld · reused %ld×", (long)cell.serial, (long)cell.reuseCount];
    cell.statusLabel.text = [NSString stringWithFormat:@"Loading %@…", price];

    self.configureCount += 1;
    [cell.promoButton configureWithAmount:amount
                           affirmLogoType:AffirmLogoTypeName
                              affirmColor:AffirmColorTypeBlue
                                     font:[UIFont systemFontOfSize:15]
                                textColor:[UIColor grayColor]];
    [self updateStats];
    return cell;
}

#pragma mark - Render results

- (void)renderDidFinish:(NSNotification *)notification
{
    PromoTableCell *cell = [self.cellsByButton objectForKey:notification.object];
    if (cell == nil) {
        return;
    }
    NSObject *operation = notification.userInfo[@"operation"];
    NSString *state = [operation valueForKey:@"terminalState"];
    if ([state isEqualToString:@"T9"]) {
        // The cell was reused before this render finished; the new row's render owns the button now.
        self.supersededCount += 1;
    } else {
        self.finishedCount += 1;
        NSDictionary<NSString *, NSString *> *shownAs = @{
            @"T1": @"native text", @"T2": @"HTML", @"T3": @"native text (HTML failed)",
        };
        NSString *shown = shownAs[state] ?: @"hidden";
        NSString *reason = [operation valueForKey:@"fallbackReason"] ?: [operation valueForKey:@"reason"];
        cell.statusLabel.text = reason
            ? [NSString stringWithFormat:@"Shown as %@ (%@), %@", shown, state, reason]
            : [NSString stringWithFormat:@"Shown as %@ (%@)", shown, state];
    }
    [self updateStats];
}

- (void)updateStats
{
    self.statsLabel.text = [NSString stringWithFormat:
        @"Cells created: %ld   Reused: %ld\nConfigure calls: %ld   Finished: %ld   Superseded: %ld",
        (long)self.createdCount, (long)self.reusedCount,
        (long)self.configureCount, (long)self.finishedCount, (long)self.supersededCount];
}

#pragma mark - Affirm prequal delegate

- (void)webViewController:(nullable AffirmBaseWebViewController *)webViewController didFailWithError:(NSError *)error
{
    NSLog(@"Prequal failed with error: %@", error.userInfo);
    [webViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
