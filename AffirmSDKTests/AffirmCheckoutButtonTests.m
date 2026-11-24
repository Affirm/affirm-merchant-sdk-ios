//
//  AffirmCheckoutButtonTests.m
//  AffirmSDKTests
//
//  Copyright © 2026 Affirm, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "../AffirmSDK/AffirmCheckoutButton.h"
#import "../AffirmSDK/AffirmPromotionalButton.h"

@interface AffirmCheckoutButton (Testing)

@property (nonatomic, strong, readonly) UILabel *titleLabel;
- (NSDictionary *)clickTrackingParameters;
- (void)trackClick;

@end

@interface AffirmRecordingCheckoutButton : AffirmCheckoutButton

@property (nonatomic, strong) NSMutableArray<NSString *> *events;

@end

@implementation AffirmRecordingCheckoutButton

// Test bundles have no UIApplication to deliver actions, so call each target in the order UIControl sends them.
- (void)sendAction:(SEL)action to:(id)target forEvent:(UIEvent *)event
{
    ((void (*)(id, SEL))[target methodForSelector:action])(target, action);
}

- (void)trackClick
{
    [self.events addObject:@"tracked"];
}

- (void)merchantTapped
{
    [self.events addObject:@"merchant"];
}

@end

@interface AffirmCheckoutButtonTests : XCTestCase
@end

@implementation AffirmCheckoutButtonTests

- (AffirmCheckoutButton *)button
{
    return [[AffirmCheckoutButton alloc] initWithPageType:AffirmPageTypeProduct frame:CGRectMake(0, 0, 320, 48)];
}

- (UIColor *)colorWithRGB:(uint32_t)rgb
{
    return [UIColor colorWithRed:((rgb >> 16) & 0xFF) / 255.0 green:((rgb >> 8) & 0xFF) / 255.0 blue:(rgb & 0xFF) / 255.0 alpha:1.0];
}

- (NSArray<NSTextAttachment *> *)logosInButton:(AffirmCheckoutButton *)button
{
    NSMutableArray *logos = [NSMutableArray array];
    NSAttributedString *title = button.titleLabel.attributedText;
    [title enumerateAttribute:NSAttachmentAttributeName inRange:NSMakeRange(0, title.length) options:0 usingBlock:^(id value, NSRange range, BOOL *stop) {
        if (value) {
            [logos addObject:value];
        }
    }];
    return logos;
}

- (UIColor *)textColorInButton:(AffirmCheckoutButton *)button
{
    return [button.titleLabel.attributedText attribute:NSForegroundColorAttributeName atIndex:0 effectiveRange:nil];
}

- (void)testDefaults
{
    AffirmCheckoutButton *button = [self button];

    XCTAssertEqual(button.pageType, AffirmPageTypeProduct);
    XCTAssertEqual(button.size, AffirmCheckoutButtonSizeMedium);
    XCTAssertEqual(button.theme, AffirmCheckoutButtonThemeDark);
    XCTAssertEqual(button.shape, AffirmCheckoutButtonShapePill);
    XCTAssertEqual(button.buttonText, AffirmCheckoutButtonTextTypeBuyNow);
    XCTAssertFalse(button.fullWidth);
    XCTAssertTrue(button.enabled);
    XCTAssertEqualObjects(button.titleLabel.attributedText.string, @"Buy now with \uFFFC");
}

- (void)testFullInitializer
{
    AffirmCheckoutButton *button = [[AffirmCheckoutButton alloc] initWithPageType:AffirmPageTypeCart
                                                                             size:AffirmCheckoutButtonSizeLarge
                                                                            theme:AffirmCheckoutButtonThemeLight
                                                                            shape:AffirmCheckoutButtonShapeRounded
                                                                       buttonText:AffirmCheckoutButtonTextTypeLogoOnly
                                                                        fullWidth:YES
                                                                            frame:CGRectZero];

    XCTAssertEqual(button.pageType, AffirmPageTypeCart);
    XCTAssertEqual(button.size, AffirmCheckoutButtonSizeLarge);
    XCTAssertEqual(button.theme, AffirmCheckoutButtonThemeLight);
    XCTAssertEqual(button.shape, AffirmCheckoutButtonShapeRounded);
    XCTAssertEqual(button.buttonText, AffirmCheckoutButtonTextTypeLogoOnly);
    XCTAssertTrue(button.fullWidth);
    XCTAssertEqualObjects(button.titleLabel.attributedText.string, @"\uFFFC");
}

- (void)testInitWithCoderUsesTheDefaults
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 48)];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:view requiringSecureCoding:NO error:nil];
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingFromData:data error:nil];
    unarchiver.requiresSecureCoding = NO;
    [unarchiver setClass:[AffirmCheckoutButton class] forClassName:@"UIView"];
    AffirmCheckoutButton *button = [unarchiver decodeObjectOfClass:[AffirmCheckoutButton class] forKey:NSKeyedArchiveRootObjectKey];

    XCTAssertTrue([button isKindOfClass:[AffirmCheckoutButton class]]);
    XCTAssertEqual(button.pageType, AffirmPageTypeNone);
    XCTAssertEqual(button.size, AffirmCheckoutButtonSizeMedium);
    XCTAssertEqual(button.shape, AffirmCheckoutButtonShapePill);
    XCTAssertEqualObjects(button.titleLabel.attributedText.string, @"Buy now with \uFFFC");
    XCTAssertEqualObjects(button.backgroundColor, [self colorWithRGB:0x000049]);
}

- (void)testSizes
{
    NSArray *expected = @[
        @[@(AffirmCheckoutButtonSizeSmall), @44, @16, @16],
        @[@(AffirmCheckoutButtonSizeMedium), @48, @18, @24],
        @[@(AffirmCheckoutButtonSizeLarge), @64, @20, @28],
    ];
    for (NSArray *row in expected) {
        AffirmCheckoutButton *button = [self button];
        button.size = [row[0] integerValue];
        button.frame = CGRectMake(0, 0, 400, button.intrinsicContentSize.height);
        [button layoutIfNeeded];

        XCTAssertEqual(button.intrinsicContentSize.height, [row[1] doubleValue]);
        XCTAssertEqual([button sizeThatFits:CGSizeMake(400, 400)].height, [row[1] doubleValue]);
        XCTAssertEqual(button.titleLabel.font.pointSize, [row[2] doubleValue]);
        XCTAssertEqual(CGRectGetMinX(button.titleLabel.frame), [row[3] doubleValue]);
        XCTAssertEqual(400 - CGRectGetMaxX(button.titleLabel.frame), [row[3] doubleValue]);
        XCTAssertEqual([[button.titleLabel.attributedText attribute:NSFontAttributeName atIndex:0 effectiveRange:nil] pointSize], [row[2] doubleValue]);
    }
}

- (void)testThemes
{
    AffirmCheckoutButton *button = [self button];
    XCTAssertEqualObjects(button.backgroundColor, [self colorWithRGB:0x000049]);
    XCTAssertEqualObjects([self textColorInButton:button], [self colorWithRGB:0xF7F7F8]);
    XCTAssertEqualObjects(UIImagePNGRepresentation([self logosInButton:button].firstObject.image),
                          UIImagePNGRepresentation([AffirmPromotionalButton getAffirmDisplayForLogoType:AffirmLogoTypeName colorType:AffirmColorTypeWhite]));
    XCTAssertEqual(button.layer.borderWidth, 0);

    button.theme = AffirmCheckoutButtonThemeLight;
    XCTAssertEqualObjects(button.backgroundColor, [self colorWithRGB:0xFFFFFF]);
    XCTAssertEqualObjects([self textColorInButton:button], [self colorWithRGB:0x0C0C14]);
    XCTAssertEqualObjects(UIImagePNGRepresentation([self logosInButton:button].firstObject.image),
                          UIImagePNGRepresentation([AffirmPromotionalButton getAffirmDisplayForLogoType:AffirmLogoTypeName colorType:AffirmColorTypeBlueBlack]));
    XCTAssertEqual(button.layer.borderWidth, 0);
}

- (void)testShapes
{
    AffirmCheckoutButton *button = [self button];
    button.size = AffirmCheckoutButtonSizeLarge;
    button.frame = CGRectMake(0, 0, 320, 64);

    button.shape = AffirmCheckoutButtonShapeSharp;
    [button layoutIfNeeded];
    XCTAssertEqual(button.layer.cornerRadius, 0);

    button.shape = AffirmCheckoutButtonShapeRounded;
    [button layoutIfNeeded];
    XCTAssertEqual(button.layer.cornerRadius, 8);

    button.shape = AffirmCheckoutButtonShapePill;
    [button layoutIfNeeded];
    XCTAssertEqual(button.layer.cornerRadius, 32);
}

- (void)testTextTypes
{
    AffirmCheckoutButton *button = [self button];
    XCTAssertEqualObjects(button.titleLabel.attributedText.string, @"Buy now with \uFFFC");
    XCTAssertEqualObjects(button.accessibilityLabel, @"Buy now with Affirm");

    button.buttonText = AffirmCheckoutButtonTextTypeCheckout;
    XCTAssertEqualObjects(button.titleLabel.attributedText.string, @"Checkout with \uFFFC");
    XCTAssertEqualObjects(button.accessibilityLabel, @"Checkout with Affirm");

    button.buttonText = AffirmCheckoutButtonTextTypeLogoOnly;
    XCTAssertEqualObjects(button.titleLabel.attributedText.string, @"\uFFFC");
    XCTAssertEqualObjects(button.accessibilityLabel, @"Buy now with Affirm");
}

- (void)testAccessibilityLabelFunction
{
    XCTAssertEqualObjects(AffirmCheckoutButtonAccessibilityLabel(AffirmCheckoutButtonTextTypeBuyNow), @"Buy now with Affirm");
    XCTAssertEqualObjects(AffirmCheckoutButtonAccessibilityLabel(AffirmCheckoutButtonTextTypeCheckout), @"Checkout with Affirm");
    XCTAssertEqualObjects(AffirmCheckoutButtonAccessibilityLabel(AffirmCheckoutButtonTextTypeLogoOnly), @"Buy now with Affirm");
}

- (void)testAccessibilityElement
{
    AffirmCheckoutButton *button = [self button];
    XCTAssertTrue(button.isAccessibilityElement);
    XCTAssertFalse(button.titleLabel.isAccessibilityElement);
    XCTAssertTrue(button.accessibilityTraits & UIAccessibilityTraitButton);
    XCTAssertFalse(button.accessibilityTraits & UIAccessibilityTraitNotEnabled);

    button.enabled = NO;
    XCTAssertTrue(button.accessibilityTraits & UIAccessibilityTraitButton);
    XCTAssertTrue(button.accessibilityTraits & UIAccessibilityTraitNotEnabled);
}

- (void)testLogoIsSizedToTheFont
{
    AffirmCheckoutButton *button = [self button];
    for (NSNumber *size in @[@(AffirmCheckoutButtonSizeSmall), @(AffirmCheckoutButtonSizeMedium), @(AffirmCheckoutButtonSizeLarge)]) {
        button.size = size.integerValue;
        NSTextAttachment *logo = [self logosInButton:button].firstObject;
        XCTAssertEqualWithAccuracy(CGRectGetHeight(logo.bounds), button.titleLabel.font.pointSize, 0.01);
        XCTAssertEqualWithAccuracy(CGRectGetWidth(logo.bounds) / CGRectGetHeight(logo.bounds), logo.image.size.width / logo.image.size.height, 0.01);
    }
}

- (void)testLogoNextToTextSitsOnTheBaseline
{
    AffirmCheckoutButton *button = [self button];
    XCTAssertEqual(CGRectGetMinY([self logosInButton:button].firstObject.bounds), 0);
}

- (void)testLogoOnlyIsCenteredInTheLine
{
    AffirmCheckoutButton *button = [self button];
    button.buttonText = AffirmCheckoutButtonTextTypeLogoOnly;
    UIFont *font = button.titleLabel.font;
    CGRect bounds = [self logosInButton:button].firstObject.bounds;

    XCTAssertEqualWithAccuracy(CGRectGetMidY(bounds), (font.ascender + font.descender) / 2.0, 0.01);
}

- (void)testFullWidth
{
    AffirmCheckoutButton *button = [self button];
    CGFloat contentWidth = button.intrinsicContentSize.width;
    XCTAssertGreaterThan(contentWidth, 2 * 24);
    XCTAssertEqual([button sizeThatFits:CGSizeMake(1000, 1000)].width, contentWidth);

    button.fullWidth = YES;
    XCTAssertEqual(button.intrinsicContentSize.width, UIViewNoIntrinsicMetric);
    XCTAssertEqual([button sizeThatFits:CGSizeMake(1000, 1000)].width, 1000);
}

- (void)testFullWidthStretchesInAutoLayout
{
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 375, 200)];
    AffirmCheckoutButton *button = [self button];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [container addSubview:button];
    [NSLayoutConstraint activateConstraints:@[
        [button.leadingAnchor constraintGreaterThanOrEqualToAnchor:container.leadingAnchor],
        [button.trailingAnchor constraintLessThanOrEqualToAnchor:container.trailingAnchor],
        [button.centerXAnchor constraintEqualToAnchor:container.centerXAnchor],
        [button.topAnchor constraintEqualToAnchor:container.topAnchor],
    ]];
    NSLayoutConstraint *stretch = [button.widthAnchor constraintEqualToAnchor:container.widthAnchor];
    stretch.priority = UILayoutPriorityDefaultLow - 1;
    stretch.active = YES;

    [container layoutIfNeeded];
    XCTAssertLessThan(CGRectGetWidth(button.frame), 375);
    XCTAssertEqual(CGRectGetHeight(button.frame), 48);

    button.fullWidth = YES;
    [container layoutIfNeeded];
    XCTAssertEqual(CGRectGetWidth(button.frame), 375);
    XCTAssertEqual(CGRectGetHeight(button.frame), 48);
}

- (void)testEveryCombinationRenders
{
    AffirmCheckoutButton *button = [self button];
    for (NSInteger size = AffirmCheckoutButtonSizeSmall; size <= AffirmCheckoutButtonSizeLarge; size++) {
        for (NSInteger theme = AffirmCheckoutButtonThemeDark; theme <= AffirmCheckoutButtonThemeLight; theme++) {
            for (NSInteger shape = AffirmCheckoutButtonShapeSharp; shape <= AffirmCheckoutButtonShapeRounded; shape++) {
                for (NSInteger text = AffirmCheckoutButtonTextTypeBuyNow; text <= AffirmCheckoutButtonTextTypeLogoOnly; text++) {
                    button.size = size;
                    button.theme = theme;
                    button.shape = shape;
                    button.buttonText = text;
                    CGSize fitted = [button sizeThatFits:CGSizeMake(1000, 1000)];
                    button.frame = CGRectMake(0, 0, fitted.width, fitted.height);
                    [button layoutIfNeeded];

                    XCTAssertGreaterThanOrEqual(CGRectGetHeight(button.frame), 44);
                    XCTAssertEqual([self logosInButton:button].count, 1);
                    XCTAssertNotNil([self logosInButton:button].firstObject.image);
                    XCTAssertLessThanOrEqual(ceil(button.titleLabel.intrinsicContentSize.width), ceil(CGRectGetWidth(button.titleLabel.bounds)) + 1);
                }
            }
        }
    }
}

- (void)testShrinksWhenOneLineIsTooNarrow
{
    AffirmCheckoutButton *button = [self button];
    button.size = AffirmCheckoutButtonSizeLarge;
    button.buttonText = AffirmCheckoutButtonTextTypeCheckout;

    button.frame = CGRectMake(0, 0, 2 * 28 + 60, 64);
    [button layoutIfNeeded];
    XCTAssertLessThan(button.titleLabel.font.pointSize, 20);
    XCTAssertGreaterThanOrEqual(button.titleLabel.font.pointSize, 1);
    XCTAssertLessThanOrEqual([button.titleLabel.attributedText boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin context:nil].size.width, 60);
    XCTAssertEqual(button.intrinsicContentSize.height, 64);

    button.frame = CGRectMake(0, 0, 1000, 64);
    [button layoutIfNeeded];
    XCTAssertEqual(button.titleLabel.font.pointSize, 20);
}

- (void)testDisabledAndHighlightedFade
{
    AffirmCheckoutButton *button = [self button];
    XCTAssertEqual(button.alpha, 1);

    button.highlighted = YES;
    XCTAssertEqualWithAccuracy(button.alpha, 0.8, 0.001);
    button.highlighted = NO;
    XCTAssertEqual(button.alpha, 1);

    button.enabled = NO;
    XCTAssertEqualWithAccuracy(button.alpha, 0.38, 0.001);
    button.enabled = YES;
    XCTAssertEqual(button.alpha, 1);
}

- (void)testTouchUpInsideTracksBeforeTheMerchantTarget
{
    AffirmRecordingCheckoutButton *button = [[AffirmRecordingCheckoutButton alloc] initWithPageType:AffirmPageTypeProduct frame:CGRectMake(0, 0, 320, 48)];
    button.events = [NSMutableArray array];
    [button addTarget:button action:@selector(merchantTapped) forControlEvents:UIControlEventTouchUpInside];

    [button sendActionsForControlEvents:UIControlEventTouchUpInside];

    XCTAssertEqualObjects(button.events, (@[@"tracked", @"merchant"]));
}

- (void)testClickTrackingParameters
{
    AffirmCheckoutButton *button = [self button];
    XCTAssertEqualObjects([button clickTrackingParameters], (@{@"page_type": @"product", @"button_size": @"medium", @"button_theme": @"dark", @"button_shape": @"pill", @"button_text": @"buy-now"}));

    button.pageType = AffirmPageTypeNone;
    button.size = AffirmCheckoutButtonSizeSmall;
    button.theme = AffirmCheckoutButtonThemeLight;
    button.shape = AffirmCheckoutButtonShapeSharp;
    button.buttonText = AffirmCheckoutButtonTextTypeLogoOnly;
    XCTAssertEqualObjects([button clickTrackingParameters], (@{@"page_type": @"", @"button_size": @"small", @"button_theme": @"light", @"button_shape": @"sharp", @"button_text": @"logo-only"}));

    button.pageType = AffirmPageTypeCart;
    button.size = AffirmCheckoutButtonSizeLarge;
    button.shape = AffirmCheckoutButtonShapeRounded;
    button.buttonText = AffirmCheckoutButtonTextTypeCheckout;
    XCTAssertEqualObjects([button clickTrackingParameters], (@{@"page_type": @"cart", @"button_size": @"large", @"button_theme": @"light", @"button_shape": @"rounded", @"button_text": @"checkout"}));
}

@end
