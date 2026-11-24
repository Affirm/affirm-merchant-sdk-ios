//
//  AffirmCheckoutButton.m
//  AffirmSDK
//
//  Copyright © 2026 Affirm, Inc. All rights reserved.
//

#import "AffirmCheckoutButton.h"
#import "AffirmPromotionalButton.h"
#import "AffirmConfiguration.h"
#import "AffirmLogger.h"

static const CGFloat AffirmCheckoutButtonRoundedCornerRadius = 8.0;
static const CGFloat AffirmCheckoutButtonHighlightedAlpha = 0.8;
static const CGFloat AffirmCheckoutButtonDisabledAlpha = 0.38;

static UIColor * AffirmCheckoutButtonColor(uint32_t rgb)
{
    return [UIColor colorWithRed:((rgb >> 16) & 0xFF) / 255.0
                           green:((rgb >> 8) & 0xFF) / 255.0
                            blue:(rgb & 0xFF) / 255.0
                           alpha:1.0];
}

@interface AffirmCheckoutButton ()

@property (nonatomic, strong) UILabel *titleLabel;
/// The font size from the spec; layout shrinks the title below it when one line is too narrow.
@property (nonatomic) CGFloat styledFontSize;
@property (nonatomic) CGFloat fittedFontSize;

@end

@implementation AffirmCheckoutButton

- (instancetype)initWithPageType:(AffirmPageType)pageType
                           frame:(CGRect)frame
{
    return [self initWithPageType:pageType
                             size:AffirmCheckoutButtonSizeMedium
                            theme:AffirmCheckoutButtonThemeDark
                            shape:AffirmCheckoutButtonShapePill
                       buttonText:AffirmCheckoutButtonTextTypeBuyNow
                        fullWidth:NO
                            frame:frame];
}

- (instancetype)initWithPageType:(AffirmPageType)pageType
                            size:(AffirmCheckoutButtonSize)size
                           theme:(AffirmCheckoutButtonTheme)theme
                           shape:(AffirmCheckoutButtonShape)shape
                      buttonText:(AffirmCheckoutButtonTextType)buttonText
                       fullWidth:(BOOL)fullWidth
                           frame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        _pageType = pageType;
        _size = size;
        _theme = theme;
        _shape = shape;
        _buttonText = buttonText;
        _fullWidth = fullWidth;
        [self setup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    if (self = [super initWithCoder:coder]) {
        _pageType = AffirmPageTypeNone;
        _size = AffirmCheckoutButtonSizeMedium;
        _theme = AffirmCheckoutButtonThemeDark;
        _shape = AffirmCheckoutButtonShapePill;
        _buttonText = AffirmCheckoutButtonTextTypeBuyNow;
        _fullWidth = NO;
        [self setup];
    }
    return self;
}

- (void)setup
{
    self.titleLabel = [[UILabel alloc] initWithFrame:self.bounds];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.numberOfLines = 1;
    self.titleLabel.userInteractionEnabled = NO;
    self.titleLabel.isAccessibilityElement = NO;
    [self addSubview:self.titleLabel];

    self.isAccessibilityElement = YES;
    [self setContentHuggingPriority:UILayoutPriorityRequired - 1 forAxis:UILayoutConstraintAxisVertical];
    [self setContentCompressionResistancePriority:UILayoutPriorityRequired - 1 forAxis:UILayoutConstraintAxisVertical];

    // Added first, so the click is tracked before the merchant's targets start checkout.
    [self addTarget:self action:@selector(trackClick) forControlEvents:UIControlEventTouchUpInside];

    [self applyStyle];
}

#pragma mark - Properties

- (void)setSize:(AffirmCheckoutButtonSize)size
{
    _size = size;
    [self applyStyle];
}

- (void)setTheme:(AffirmCheckoutButtonTheme)theme
{
    _theme = theme;
    [self applyStyle];
}

- (void)setShape:(AffirmCheckoutButtonShape)shape
{
    _shape = shape;
    [self setNeedsLayout];
}

- (void)setButtonText:(AffirmCheckoutButtonTextType)buttonText
{
    _buttonText = buttonText;
    [self applyStyle];
}

- (void)setFullWidth:(BOOL)fullWidth
{
    _fullWidth = fullWidth;
    [self invalidateSize];
}

- (void)setEnabled:(BOOL)enabled
{
    [super setEnabled:enabled];
    [self updateAlpha];
}

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    [self updateAlpha];
}

#pragma mark - Style

- (CGFloat)buttonHeight
{
    switch (self.size) {
        case AffirmCheckoutButtonSizeSmall:
            return 44.0;
        case AffirmCheckoutButtonSizeLarge:
            return 64.0;
        case AffirmCheckoutButtonSizeMedium:
        default:
            return 48.0;
    }
}

- (CGFloat)fontSize
{
    switch (self.size) {
        case AffirmCheckoutButtonSizeSmall:
            return 16.0;
        case AffirmCheckoutButtonSizeLarge:
            return 20.0;
        case AffirmCheckoutButtonSizeMedium:
        default:
            return 18.0;
    }
}

- (CGFloat)horizontalPadding
{
    switch (self.size) {
        case AffirmCheckoutButtonSizeSmall:
            return 16.0;
        case AffirmCheckoutButtonSizeLarge:
            return 28.0;
        case AffirmCheckoutButtonSizeMedium:
        default:
            return 24.0;
    }
}

- (UIColor *)fillColor
{
    return AffirmCheckoutButtonColor(self.theme == AffirmCheckoutButtonThemeLight ? AFFIRM_CHECKOUT_BUTTON_LIGHT_FILL_COLOR : AFFIRM_CHECKOUT_BUTTON_DARK_FILL_COLOR);
}

- (UIColor *)textColor
{
    return AffirmCheckoutButtonColor(self.theme == AffirmCheckoutButtonThemeLight ? AFFIRM_CHECKOUT_BUTTON_LIGHT_TEXT_COLOR : AFFIRM_CHECKOUT_BUTTON_DARK_TEXT_COLOR);
}

- (AffirmColorType)logoColor
{
    return self.theme == AffirmCheckoutButtonThemeLight ? AffirmColorTypeBlueBlack : AffirmColorTypeWhite;
}

- (NSString *)text
{
    switch (self.buttonText) {
        case AffirmCheckoutButtonTextTypeCheckout:
            return @"Checkout with Affirm";
        case AffirmCheckoutButtonTextTypeLogoOnly:
            return @"Affirm";
        case AffirmCheckoutButtonTextTypeBuyNow:
        default:
            return @"Buy now with Affirm";
    }
}

- (UIFont *)fontOfSize:(CGFloat)fontSize
{
    return [UIFont systemFontOfSize:fontSize weight:UIFontWeightSemibold];
}

/// "Affirm" in the text is replaced with the logo, sized to the font.
- (NSAttributedString *)titleWithFontSize:(CGFloat)fontSize
{
    UIFont *font = [self fontOfSize:fontSize];
    UIImage *logo = [AffirmPromotionalButton getAffirmDisplayForLogoType:AffirmLogoTypeName
                                                               colorType:self.logoColor];
    NSAttributedString *title = [AffirmPromotionalButton appendLogo:logo
                                                             toText:self.text
                                                               font:font
                                                          textColor:self.textColor
                                                           logoType:AffirmLogoTypeName];
    if (self.buttonText != AffirmCheckoutButtonTextTypeLogoOnly) {
        return title;
    }
    // Alone, a logo on the baseline sits above the center by the font's descent; center it in the line.
    NSMutableAttributedString *centered = [title mutableCopy];
    [centered enumerateAttribute:NSAttachmentAttributeName
                         inRange:NSMakeRange(0, centered.length)
                         options:0
                      usingBlock:^(NSTextAttachment *attachment, NSRange range, BOOL *stop) {
        if (attachment) {
            CGRect bounds = attachment.bounds;
            bounds.origin.y = (font.ascender + font.descender - CGRectGetHeight(bounds)) / 2.0;
            attachment.bounds = bounds;
        }
    }];
    [centered addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, centered.length)];
    return centered;
}

- (CGFloat)widthOfTitle:(NSAttributedString *)title
{
    return ceil([title boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)
                                    options:NSStringDrawingUsesLineFragmentOrigin
                                    context:nil].size.width);
}

- (void)applyStyle
{
    self.styledFontSize = self.fontSize;
    self.fittedFontSize = self.styledFontSize;
    self.titleLabel.font = [self fontOfSize:self.styledFontSize];
    self.titleLabel.attributedText = [self titleWithFontSize:self.styledFontSize];
    self.backgroundColor = self.fillColor;
    self.layer.borderWidth = 0;
    self.accessibilityLabel = AffirmCheckoutButtonAccessibilityLabel(self.buttonText);
    [self updateAlpha];
    [self invalidateSize];
}

- (void)invalidateSize
{
    [self invalidateIntrinsicContentSize];
    [self setNeedsLayout];
    // A new intrinsic size alone does not always mark the superview for layout.
    [self.superview setNeedsLayout];
}

- (void)updateAlpha
{
    if (!self.enabled) {
        self.alpha = AffirmCheckoutButtonDisabledAlpha;
    } else {
        self.alpha = self.highlighted ? AffirmCheckoutButtonHighlightedAlpha : 1.0;
    }
}

#pragma mark - Layout

- (CGSize)intrinsicContentSize
{
    CGFloat width = self.fullWidth ? UIViewNoIntrinsicMetric : [self widthOfTitle:[self titleWithFontSize:self.styledFontSize]] + 2 * self.horizontalPadding;
    return CGSizeMake(width, self.buttonHeight);
}

- (CGSize)sizeThatFits:(CGSize)size
{
    CGSize intrinsicSize = self.intrinsicContentSize;
    CGFloat width = self.fullWidth ? size.width : intrinsicSize.width;
    return CGSizeMake(width, intrinsicSize.height);
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    switch (self.shape) {
        case AffirmCheckoutButtonShapeSharp:
            self.layer.cornerRadius = 0;
            break;
        case AffirmCheckoutButtonShapeRounded:
            self.layer.cornerRadius = AffirmCheckoutButtonRoundedCornerRadius;
            break;
        case AffirmCheckoutButtonShapePill:
        default:
            self.layer.cornerRadius = CGRectGetHeight(self.bounds) / 2.0;
            break;
    }

    CGFloat padding = self.horizontalPadding;
    self.titleLabel.frame = CGRectMake(padding, 0, MAX(0, CGRectGetWidth(self.bounds) - 2 * padding), CGRectGetHeight(self.bounds));
    [self fitTitleToWidth:CGRectGetWidth(self.titleLabel.bounds)];
}

/// Large text can be wider than the button. Rather than truncating, shrink the text and logo until they fit on one line.
- (void)fitTitleToWidth:(CGFloat)availableWidth
{
    CGFloat fittedSize = self.styledFontSize;
    CGFloat styledWidth = [self widthOfTitle:[self titleWithFontSize:fittedSize]];
    if (styledWidth > availableWidth && availableWidth > 0) {
        fittedSize = floor(self.styledFontSize * availableWidth / styledWidth);
        while (fittedSize > 1 && [self widthOfTitle:[self titleWithFontSize:fittedSize]] > availableWidth) {
            fittedSize--;
        }
    }
    if (fittedSize != self.fittedFontSize) {
        self.fittedFontSize = fittedSize;
        self.titleLabel.font = [self fontOfSize:fittedSize];
        self.titleLabel.attributedText = [self titleWithFontSize:fittedSize];
    }
}

#pragma mark - Accessibility

- (UIAccessibilityTraits)accessibilityTraits
{
    UIAccessibilityTraits traits = [super accessibilityTraits] | UIAccessibilityTraitButton;
    if (!self.enabled) {
        traits |= UIAccessibilityTraitNotEnabled;
    }
    return traits;
}

#pragma mark - Tracking

- (void)trackClick
{
    // Tracking reads the SDK configuration; the button can be shown before it is configured.
    if ([AffirmConfiguration sharedInstance].publicKey.length == 0) {
        return;
    }
    [[AffirmLogger sharedInstance] trackEvent:@"Checkout button clicked" parameters:[self clickTrackingParameters]];
}

/// The values Affirm.js reports, e.g. AffirmCheckoutButtonTextTypeBuyNow is "buy-now".
- (NSDictionary *)clickTrackingParameters
{
    NSString *size;
    switch (self.size) {
        case AffirmCheckoutButtonSizeSmall:
            size = @"small";
            break;
        case AffirmCheckoutButtonSizeLarge:
            size = @"large";
            break;
        case AffirmCheckoutButtonSizeMedium:
        default:
            size = @"medium";
            break;
    }
    NSString *shape;
    switch (self.shape) {
        case AffirmCheckoutButtonShapeSharp:
            shape = @"sharp";
            break;
        case AffirmCheckoutButtonShapeRounded:
            shape = @"rounded";
            break;
        case AffirmCheckoutButtonShapePill:
        default:
            shape = @"pill";
            break;
    }
    NSString *text;
    switch (self.buttonText) {
        case AffirmCheckoutButtonTextTypeCheckout:
            text = @"checkout";
            break;
        case AffirmCheckoutButtonTextTypeLogoOnly:
            text = @"logo-only";
            break;
        case AffirmCheckoutButtonTextTypeBuyNow:
        default:
            text = @"buy-now";
            break;
    }
    return @{
        @"page_type": FormatAffirmPageTypeString(self.pageType) ?: @"",
        @"button_size": size,
        @"button_theme": self.theme == AffirmCheckoutButtonThemeLight ? @"light" : @"dark",
        @"button_shape": shape,
        @"button_text": text
    };
}

@end
