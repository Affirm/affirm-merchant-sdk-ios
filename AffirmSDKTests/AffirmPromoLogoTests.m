//
//  AffirmPromoLogoTests.m
//  AffirmSDKTests
//
//  Tests for the promo logo replacement logic.
//  Verifies that only {affirm_logo} placeholders are replaced with logo images,
//  and that plain-text "Affirm" in promo messages is preserved as text.
//

#import <XCTest/XCTest.h>
#import "../AffirmSDK/AffirmConfiguration.h"
#import "../AffirmSDK/AffirmRequest.h"
#import "../AffirmSDK/AffirmPromotionalButton.h"

@interface AffirmPromoLogoTests : XCTestCase

@end

@implementation AffirmPromoLogoTests

- (void)setUp
{
    [[AffirmConfiguration sharedInstance] configureWithPublicKey:@"PKNCHBIVYOT8JSOZ" environment:AffirmEnvironmentSandbox];
}

#pragma mark - AffirmPromoResponse parsing tests

- (void)testPromoResponsePreservesAffirmLogoPlaceholder
{
    // Simulate a JSON response where ala contains {affirm_logo}
    NSDictionary *json = @{
        @"promo": @{
            @"ala": @"Pay over time with {affirm_logo}",
            @"html_ala": [NSNull null],
            @"config": @{@"promo_style": @"fast"}
        }
    };
    NSData *data = [NSJSONSerialization dataWithJSONObject:json options:0 error:nil];
    AffirmResponse *response = [AffirmPromoResponse parse:data];

    XCTAssertTrue([response isKindOfClass:[AffirmPromoResponse class]]);
    AffirmPromoResponse *promoResponse = (AffirmPromoResponse *)response;

    // The {affirm_logo} placeholder should be preserved, NOT replaced with "Affirm"
    XCTAssertTrue([promoResponse.ala containsString:@"{affirm_logo}"],
                  @"Expected {affirm_logo} to be preserved in ala string, got: %@", promoResponse.ala);
    XCTAssertEqualObjects(promoResponse.ala, @"Pay over time with {affirm_logo}");
}

- (void)testPromoResponsePreservesPlainTextAffirm
{
    // Simulate a JSON response where ala contains both {affirm_logo} and plain "Affirm"
    NSDictionary *json = @{
        @"promo": @{
            @"ala": @"Pay with {affirm_logo}. Affirm is a form of credit.",
            @"html_ala": [NSNull null],
            @"config": @{@"promo_style": @"fast"}
        }
    };
    NSData *data = [NSJSONSerialization dataWithJSONObject:json options:0 error:nil];
    AffirmResponse *response = [AffirmPromoResponse parse:data];

    XCTAssertTrue([response isKindOfClass:[AffirmPromoResponse class]]);
    AffirmPromoResponse *promoResponse = (AffirmPromoResponse *)response;

    // Both {affirm_logo} AND plain "Affirm" should remain in the string
    XCTAssertTrue([promoResponse.ala containsString:@"{affirm_logo}"],
                  @"Expected {affirm_logo} to be preserved");
    XCTAssertTrue([promoResponse.ala containsString:@"Affirm is a form of credit"],
                  @"Expected plain text 'Affirm' to be preserved");
    XCTAssertEqualObjects(promoResponse.ala, @"Pay with {affirm_logo}. Affirm is a form of credit.");
}

#pragma mark - appendLogo replacement tests

- (void)testAppendLogoReplacesOnlyPlaceholder
{
    // Text with both {affirm_logo} placeholder and plain "Affirm"
    NSString *text = @"Pay with {affirm_logo}. Affirm is a form of credit.";
    UIFont *font = [UIFont systemFontOfSize:15];
    UIColor *color = [UIColor blackColor];

    // Create a simple 10x10 test image
    UIGraphicsBeginImageContext(CGSizeMake(10, 10));
    UIImage *logo = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    NSAttributedString *result = [AffirmPromotionalButton appendLogo:logo
                                                              toText:text
                                                                font:font
                                                           textColor:color
                                                            logoType:AffirmLogoTypeName];

    NSString *resultString = result.string;

    // The placeholder should have been replaced (it won't contain {affirm_logo} anymore)
    XCTAssertFalse([resultString containsString:@"{affirm_logo}"],
                   @"Placeholder {affirm_logo} should have been replaced with logo image");

    // Plain text "Affirm" should still be present
    XCTAssertTrue([resultString containsString:@"Affirm"],
                  @"Plain text 'Affirm' should remain as text, got: %@", resultString);
}

- (void)testAppendLogoWithNoPlaceholderPreservesText
{
    // Text that has plain "Affirm" but no {affirm_logo} placeholder
    NSString *text = @"Affirm is great. Use Affirm today.";
    UIFont *font = [UIFont systemFontOfSize:15];
    UIColor *color = [UIColor blackColor];

    UIGraphicsBeginImageContext(CGSizeMake(10, 10));
    UIImage *logo = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    NSAttributedString *result = [AffirmPromotionalButton appendLogo:logo
                                                              toText:text
                                                                font:font
                                                           textColor:color
                                                            logoType:AffirmLogoTypeName];

    NSString *resultString = result.string;

    // Both instances of "Affirm" should remain as plain text since there's no placeholder
    XCTAssertTrue([resultString containsString:@"Affirm is great"],
                  @"Plain text should be preserved when no placeholder is present");
    XCTAssertTrue([resultString containsString:@"Use Affirm today"],
                  @"All plain text 'Affirm' instances should be preserved");
}

- (void)testAppendLogoWithNilLogoPreservesAllText
{
    NSString *text = @"Pay with {affirm_logo}. Affirm is great.";
    UIFont *font = [UIFont systemFontOfSize:15];
    UIColor *color = [UIColor blackColor];

    // When logo is nil, the method should return text as-is (no replacement)
    NSAttributedString *result = [AffirmPromotionalButton appendLogo:nil
                                                              toText:text
                                                                font:font
                                                           textColor:color
                                                            logoType:AffirmLogoTypeName];

    NSString *resultString = result.string;

    // Both placeholder and plain text should remain since there's no logo to substitute
    XCTAssertTrue([resultString containsString:@"{affirm_logo}"],
                  @"Placeholder should remain when logo is nil");
    XCTAssertTrue([resultString containsString:@"Affirm is great"],
                  @"Plain text should remain when logo is nil");
}

- (void)testAppendLogoReplacesMultiplePlaceholders
{
    // Edge case: multiple {affirm_logo} placeholders
    NSString *text = @"Use {affirm_logo} now. {affirm_logo} offers flexible pay.";
    UIFont *font = [UIFont systemFontOfSize:15];
    UIColor *color = [UIColor blackColor];

    UIGraphicsBeginImageContext(CGSizeMake(10, 10));
    UIImage *logo = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    NSAttributedString *result = [AffirmPromotionalButton appendLogo:logo
                                                              toText:text
                                                                font:font
                                                           textColor:color
                                                            logoType:AffirmLogoTypeName];

    NSString *resultString = result.string;

    // All placeholders should have been replaced
    XCTAssertFalse([resultString containsString:@"{affirm_logo}"],
                   @"All {affirm_logo} placeholders should have been replaced");
}

@end
