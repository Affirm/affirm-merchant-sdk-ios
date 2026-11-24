//
//  AffirmExpressCheckoutTests.m
//  AffirmSDKTests
//
//  Copyright © 2026 Affirm, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "../AffirmSDK/AffirmConfiguration.h"
#import "../AffirmSDK/AffirmCheckout.h"
#import "../AffirmSDK/AffirmCheckoutDelegate.h"
#import "../AffirmSDK/AffirmCheckoutViewController.h"
#import "../AffirmSDK/AffirmItem.h"
#import "../AffirmSDK/AffirmShippingDetail.h"
#import "../AffirmSDK/AffirmBillingDetail.h"
#import "../AffirmSDK/AffirmRequest.h"
#import "../AffirmSDK/AffirmClient.h"
#import "../AffirmSDK/AffirmUtils.h"

static NSString *const CallbackURL = @"https://merchant.com/shipping-and-totals";

@interface AffirmExpressCheckoutTestDelegate : NSObject <AffirmCheckoutDelegate>
@end

@implementation AffirmExpressCheckoutTestDelegate

- (void)checkout:(AffirmCheckoutViewController *)checkoutViewController completedWithToken:(NSString *)checkoutToken {}
- (void)vcnCheckout:(UIViewController *)checkoutViewController completedWithCreditCard:(AffirmCreditCard *)creditCard {}
- (void)checkoutCancelled:(UIViewController *)checkoutViewController {}
- (void)checkout:(AffirmCheckoutViewController *)checkoutViewController didFailWithError:(NSError *)error {}

@end

@interface AffirmExpressCheckoutTests : XCTestCase

@property (nonatomic, strong) AffirmItem *item;
@property (nonatomic, strong) AffirmShippingDetail *shipping;

@end

@implementation AffirmExpressCheckoutTests

- (void)setUp
{
    [self configureWithCountryCode:@"USA" locale:@"en_US" currency:@"USD"];
    _item = [AffirmItem itemWithName:@"Affirm Test Item" SKU:@"test_item" unitPrice:[NSDecimalNumber decimalNumberWithString:@"15.00"] quantity:2 URL:[NSURL URLWithString:@"http://sandbox.affirm.com/item"]];
    _shipping = [AffirmShippingDetail shippingDetailWithName:@"Test Tester" addressWithLine1:@"325 Pacific Ave." line2:@"" city:@"San Francisco" state:@"CA" zipCode:@"94111" countryCode:@"USA"];
}

- (void)tearDown
{
    [self configureWithCountryCode:@"USA" locale:@"en_US" currency:@"USD"];
}

- (void)configureWithCountryCode:(NSString *)countryCode locale:(NSString *)locale currency:(NSString *)currency
{
    [[AffirmConfiguration sharedInstance] configureWithPublicKey:@"Y8CQXFF044903JC0"
                                                     environment:AffirmEnvironmentSandbox
                                                          locale:locale
                                                     countryCode:countryCode
                                                        currency:currency
                                                    merchantName:@"Affirm Example"];
}

- (AffirmCheckout *)expressCheckout
{
    return [AffirmCheckout expressCheckoutWithItems:@[self.item]
                                            orderId:@"order-123"
                       shippingAndTotalsCallbackURL:CallbackURL
                                           metadata:@{@"subtotal": @"3000"}];
}

- (AffirmCheckout *)standardCheckout
{
    AffirmCheckout *checkout = [AffirmCheckout checkoutWithItems:@[self.item]
                                                        shipping:self.shipping
                                                       taxAmount:[NSDecimalNumber decimalNumberWithString:@"5.00"]
                                                  shippingAmount:[NSDecimalNumber decimalNumberWithString:@"7.00"]];
    return checkout;
}

- (NSDictionary *)parametersForCheckout:(AffirmCheckout *)checkout
{
    return [self requestForCheckout:checkout].parameters;
}

- (AffirmCheckoutRequest *)requestForCheckout:(AffirmCheckout *)checkout
{
    return [[AffirmCheckoutRequest alloc] initWithPublicKey:[AffirmConfiguration sharedInstance].publicKey
                                                   checkout:checkout
                                                     useVCN:NO
                                             cardAuthWindow:0];
}

- (NSString *)exceptionReasonForBlock:(void (^)(void))block
{
    @try {
        block();
    } @catch (NSException *exception) {
        return exception.reason;
    }
    return nil;
}

#pragma mark - Payload

- (void)testExpressCheckoutDefaults
{
    AffirmCheckout *checkout = [self expressCheckout];
    XCTAssertTrue(checkout.isExpressCheckout);
    XCTAssertEqualObjects(checkout.orderId, @"order-123");
    XCTAssertEqualObjects(checkout.shippingAndTotalsCallbackURL, CallbackURL);
    XCTAssertNil(checkout.shipping);

    AffirmCheckout *standard = [self standardCheckout];
    XCTAssertFalse(standard.isExpressCheckout);
    XCTAssertNil(standard.shippingAndTotalsCallbackURL);
}

- (void)testExpressPayloadFlagsExpressAndOmitsAmountsAndShipping
{
    NSDictionary *json = [[self expressCheckout] toJSONDictionary];

    XCTAssertEqualObjects(json[@"meta"], (@{@"locale": @"en_US", @"is_express_checkout": @YES}));
    XCTAssertNil(json[@"total"]);
    XCTAssertNil(json[@"tax_amount"]);
    XCTAssertNil(json[@"shipping_amount"]);
    XCTAssertNil(json[@"shipping"]);
    XCTAssertEqualObjects(json[@"order_id"], @"order-123");
    XCTAssertEqualObjects(json[@"metadata"], @{@"subtotal": @"3000"});
    XCTAssertNotNil(json[@"items"][@"test_item"]);
}

- (void)testExpressPayloadDropsShippingEvenWhenSet
{
    AffirmCheckout *checkout = [[AffirmCheckout alloc] initWithItems:@[self.item]
                                                            shipping:self.shipping
                                                           taxAmount:[NSDecimalNumber decimalNumberWithString:@"5.00"]
                                                      shippingAmount:[NSDecimalNumber decimalNumberWithString:@"7.00"]
                                                           discounts:nil
                                                            metadata:@{@"subtotal": @"3000"}
                                                    financingProgram:nil
                                                             orderId:@"order-123"];
    checkout.totalAmount = [NSDecimalNumber decimalNumberWithString:@"42.00"];
    checkout.isExpressCheckout = YES;
    checkout.shippingAndTotalsCallbackURL = CallbackURL;

    NSDictionary *json = [checkout toJSONDictionary];
    XCTAssertNil(json[@"total"]);
    XCTAssertNil(json[@"tax_amount"]);
    XCTAssertNil(json[@"shipping_amount"]);
    XCTAssertNil(json[@"shipping"]);
}

- (void)testExpressPayloadKeepsBilling
{
    AffirmCheckout *checkout = [self expressCheckout];
    checkout.billing = [AffirmBillingDetail billingDetailWithName:@"Test Tester" email:nil phoneNumber:nil addressWithLine1:@"325 Pacific Ave." line2:@"" city:@"San Francisco" state:@"CA" zipCode:@"94111" countryCode:@"USA"];

    XCTAssertNotNil([checkout toJSONDictionary][@"billing"]);
}

- (void)testCallbackURLIsSentOnTheMerchant
{
    NSDictionary *parameters = [self parametersForCheckout:[self expressCheckout]];

    XCTAssertEqualObjects(parameters[@"merchant"][@"merchant_shipping_and_totals_callback_url"], CallbackURL);
    XCTAssertNil(parameters[@"merchant_shipping_and_totals_callback_url"]);
    XCTAssertEqualObjects(parameters[@"merchant"][@"user_confirmation_url"], @"affirm://checkout/confirmed");
    XCTAssertEqualObjects(parameters[@"merchant"][@"user_cancel_url"], @"affirm://checkout/cancelled");
    XCTAssertEqualObjects(parameters[@"metadata"][@"subtotal"], @"3000");
    XCTAssertEqualObjects(parameters[@"metadata"][@"platform_type"], @"Affirm iOS SDK");
}

- (void)testCopyKeepsExpressFields
{
    AffirmCheckout *copy = [[self expressCheckout] copy];
    XCTAssertTrue(copy.isExpressCheckout);
    XCTAssertEqualObjects(copy.shippingAndTotalsCallbackURL, CallbackURL);

    AffirmCheckout *standardCopy = [[self standardCheckout] copy];
    XCTAssertFalse(standardCopy.isExpressCheckout);
    XCTAssertNil(standardCopy.shippingAndTotalsCallbackURL);
}

#pragma mark - Required fields

- (void)testExpressRequiresOrderId
{
    NSString *reason = [self exceptionReasonForBlock:^{
        [AffirmCheckout expressCheckoutWithItems:@[self.item] orderId:@"" shippingAndTotalsCallbackURL:CallbackURL metadata:@{@"subtotal": @"3000"}];
    }];
    XCTAssertEqualObjects(reason, @"Express Checkout requires orderId");

    AffirmCheckout *checkout = [[AffirmCheckout alloc] initWithItems:@[self.item] shipping:nil taxAmount:[NSDecimalNumber zero] shippingAmount:[NSDecimalNumber zero] discounts:nil metadata:@{@"subtotal": @"3000"} financingProgram:nil];
    checkout.isExpressCheckout = YES;
    checkout.shippingAndTotalsCallbackURL = CallbackURL;
    XCTAssertEqualObjects([self exceptionReasonForBlock:^{ [checkout toJSONDictionary]; }], @"Express Checkout requires orderId");
}

- (void)testExpressRequiresCallbackURL
{
    NSString *reason = [self exceptionReasonForBlock:^{
        [AffirmCheckout expressCheckoutWithItems:@[self.item] orderId:@"order-123" shippingAndTotalsCallbackURL:@"" metadata:@{@"subtotal": @"3000"}];
    }];
    XCTAssertEqualObjects(reason, @"Express Checkout requires shippingAndTotalsCallbackURL");

    AffirmCheckout *checkout = [self expressCheckout];
    checkout.shippingAndTotalsCallbackURL = nil;
    XCTAssertEqualObjects([self exceptionReasonForBlock:^{ [checkout toJSONDictionary]; }], @"Express Checkout requires shippingAndTotalsCallbackURL");
}

- (void)testExpressRequiresItems
{
    NSString *reason = [self exceptionReasonForBlock:^{
        [AffirmCheckout expressCheckoutWithItems:@[] orderId:@"order-123" shippingAndTotalsCallbackURL:CallbackURL metadata:@{@"subtotal": @"3000"}];
    }];
    XCTAssertEqualObjects(reason, @"Express Checkout requires items");
}

- (void)testExpressRequiresSubtotal
{
    for (NSDictionary *metadata in @[@{}, @{@"subtotal": @""}, @{@"subtotal": [NSNull null]}, @{@"entity_name": @"internal-sub_brand-name"}]) {
        NSString *reason = [self exceptionReasonForBlock:^{
            [AffirmCheckout expressCheckoutWithItems:@[self.item] orderId:@"order-123" shippingAndTotalsCallbackURL:CallbackURL metadata:metadata];
        }];
        XCTAssertEqualObjects(reason, @"Express Checkout requires metadata[\"subtotal\"]", @"metadata: %@", metadata);
    }

    XCTAssertNil([self exceptionReasonForBlock:^{
        [AffirmCheckout expressCheckoutWithItems:@[self.item] orderId:@"order-123" shippingAndTotalsCallbackURL:CallbackURL metadata:@{@"subtotal": @3000}];
    }]);
}

- (void)testExpressReportsAllMissingFields
{
    NSString *reason = [self exceptionReasonForBlock:^{
        [AffirmCheckout expressCheckoutWithItems:@[] orderId:@"" shippingAndTotalsCallbackURL:@"" metadata:@{}];
    }];
    XCTAssertEqualObjects(reason, @"Express Checkout requires orderId, shippingAndTotalsCallbackURL, items, metadata[\"subtotal\"]");
}

- (void)testExpressDoesNotSupportVCN
{
    AffirmExpressCheckoutTestDelegate *delegate = [AffirmExpressCheckoutTestDelegate new];
    NSString *reason = [self exceptionReasonForBlock:^{
        (void)[[AffirmCheckoutViewController alloc] initWithDelegate:delegate checkout:[self expressCheckout] useVCN:YES getReasonCodes:NO];
    }];
    XCTAssertEqualObjects(reason, @"Express Checkout does not support VCN checkout");

    XCTAssertNil([self exceptionReasonForBlock:^{
        (void)[[AffirmCheckoutViewController alloc] initWithDelegate:delegate checkout:[self expressCheckout] useVCN:NO getReasonCodes:NO];
        (void)[[AffirmCheckoutViewController alloc] initWithDelegate:delegate checkout:[self standardCheckout] useVCN:YES getReasonCodes:NO];
    }]);
}

#pragma mark - Standard checkout is unchanged

- (void)testStandardPayloadIsUnchanged
{
    NSDictionary *json = [[self standardCheckout] toJSONDictionary];

    XCTAssertEqualObjects(json[@"meta"], @{@"locale": @"en_US"});
    XCTAssertEqualObjects(json[@"total"], @4200);
    XCTAssertEqualObjects(json[@"tax_amount"], @500);
    XCTAssertEqualObjects(json[@"shipping_amount"], @700);
    XCTAssertNotNil(json[@"shipping"]);
}

- (void)testStandardCheckoutStillRequiresShipping
{
    AffirmCheckout *checkout = [AffirmCheckout checkoutWithItems:@[self.item] shipping:nil taxAmount:[NSDecimalNumber zero] shippingAmount:[NSDecimalNumber zero]];
    XCTAssertEqualObjects([self exceptionReasonForBlock:^{ [checkout toJSONDictionary]; }], @"Shipping addresses are required when sendShippingAddress is true.");
}

- (void)testStandardCheckoutIgnoresCallbackURL
{
    AffirmCheckout *checkout = [self standardCheckout];
    checkout.shippingAndTotalsCallbackURL = CallbackURL;

    AffirmCheckoutRequest *request = [self requestForCheckout:checkout];
    XCTAssertEqualObjects(request.path, @"/api/v2/checkout/");
    XCTAssertNil(request.parameters[@"checkout"][@"merchant"][@"merchant_shipping_and_totals_callback_url"]);
    XCTAssertNil(request.parameters[@"checkout"][@"meta"][@"is_express_checkout"]);
}

#pragma mark - Endpoint

- (void)testExpressCheckoutUsesCheckoutBFF
{
    AffirmCheckoutRequest *request = [self requestForCheckout:[self expressCheckout]];

    XCTAssertEqualObjects(request.path, @"/api/checkout-bff/v1/create-checkout");
    XCTAssertEqual(request.method, AffirmHTTPMethodPOST);
    XCTAssertEqualObjects(request.headers[@"country-code"], @"USA");

    NSDictionary *parameters = request.parameters;
    XCTAssertNil(parameters[@"checkout"]);
    XCTAssertEqualObjects(parameters[@"country_code"], @"USA");
    XCTAssertEqualObjects(parameters[@"api_version"], @"v2");
    XCTAssertEqualObjects(parameters[@"order_id"], @"order-123");
    XCTAssertEqualObjects(parameters[@"meta"][@"is_express_checkout"], @YES);
    XCTAssertNotNil(parameters[@"items"]);
    XCTAssertNotNil(parameters[@"merchant"]);
    XCTAssertTrue([NSJSONSerialization isValidJSONObject:parameters]);
}

- (void)testExpressCountryCodeComesFromConfiguration
{
    [self configureWithCountryCode:@"CAN" locale:@"en_CA" currency:@"CAD"];

    XCTAssertEqualObjects([self parametersForCheckout:[self expressCheckout]][@"country_code"], @"CAN");
}

- (void)testStandardCheckoutUsesLegacyEndpoint
{
    AffirmCheckoutRequest *request = [self requestForCheckout:[self standardCheckout]];

    XCTAssertEqualObjects(request.path, @"/api/v2/checkout/");
    NSDictionary *parameters = request.parameters;
    XCTAssertEqualObjects(parameters.allKeys, @[@"checkout"]);
    XCTAssertNil(parameters[@"checkout"][@"country_code"]);
    XCTAssertEqualObjects(parameters[@"checkout"][@"total"], @4200);
}

#pragma mark - Responses

- (void)testCheckoutBFFResponseParsesTheRedirectURL
{
    NSString *json = @"{\"checkout_id\":\"TEST\",\"redirect_url\":\"https://sandbox.affirm.com/products/checkout?checkout_ari=TEST\"}";
    AffirmResponse *response = [AffirmCheckoutResponse parse:[json dataUsingEncoding:NSUTF8StringEncoding]];

    XCTAssertTrue([response isKindOfClass:[AffirmCheckoutResponse class]]);
    XCTAssertEqualObjects(((AffirmCheckoutResponse *)response).redirectURL.absoluteString, @"https://sandbox.affirm.com/products/checkout?checkout_ari=TEST");
}

- (void)testCheckoutBFFError
{
    NSString *json = @"{\"error\":{\"errorCode\":\"INVALID_SUBTOTAL\",\"message\":\"Subtotal is invalid\"},\"status_code\":400}";
    AffirmResponse *response = [AffirmCheckoutResponse parseError:[json dataUsingEncoding:NSUTF8StringEncoding]];

    XCTAssertTrue([response isKindOfClass:[AffirmErrorResponse class]]);
    AffirmErrorResponse *error = (AffirmErrorResponse *)response;
    XCTAssertEqualObjects(error.code, @"INVALID_SUBTOTAL");
    XCTAssertEqualObjects(error.message, @"Subtotal is invalid");
    XCTAssertEqualObjects(error.statusCode, @400);
}

- (void)testCheckoutBFFErrorWithoutMessage
{
    NSString *json = @"{\"error\":{\"errorCode\":\"INTERNAL_SERVER_ERROR\"}}";
    AffirmErrorResponse *error = (AffirmErrorResponse *)[AffirmCheckoutResponse parseError:[json dataUsingEncoding:NSUTF8StringEncoding]];

    XCTAssertEqualObjects(error.code, @"INTERNAL_SERVER_ERROR");
    XCTAssertEqualObjects(error.message, @"");
    XCTAssertEqualObjects([error.dictionary convertToNSErrorWithCode:@500].localizedDescription, @"INTERNAL_SERVER_ERROR");
}

- (void)testErrorDescriptionPrefersTheMessage
{
    NSString *json = @"{\"error\":{\"errorCode\":\"INVALID_SUBTOTAL\",\"message\":\"Subtotal is invalid\"}}";
    AffirmErrorResponse *error = (AffirmErrorResponse *)[AffirmCheckoutResponse parseError:[json dataUsingEncoding:NSUTF8StringEncoding]];

    XCTAssertEqualObjects([error.dictionary convertToNSErrorWithCode:@400].localizedDescription, @"Subtotal is invalid");
}

- (void)testLegacyErrorIsUnchanged
{
    for (NSString *json in @[
        @"{\"message\":\"Invalid field\",\"code\":\"invalid_field\",\"type\":\"invalid_request\",\"field\":\"total\",\"status_code\":400}",
        @"{\"error\":\"Something went wrong\",\"message\":\"Invalid field\",\"code\":\"invalid_field\",\"type\":\"invalid_request\",\"field\":\"total\",\"status_code\":400}",
        @"{\"error\":{\"message\":\"Nested\"},\"message\":\"Invalid field\",\"code\":\"invalid_field\",\"type\":\"invalid_request\",\"field\":\"total\",\"status_code\":400}"
    ]) {
        AffirmErrorResponse *error = (AffirmErrorResponse *)[AffirmCheckoutResponse parseError:[json dataUsingEncoding:NSUTF8StringEncoding]];
        XCTAssertEqualObjects(error.code, @"invalid_field", @"%@", json);
        XCTAssertEqualObjects(error.message, @"Invalid field", @"%@", json);
        XCTAssertEqualObjects(error.type, @"invalid_request", @"%@", json);
        XCTAssertEqualObjects(error.field, @"total", @"%@", json);
        XCTAssertEqualObjects(error.statusCode, @400, @"%@", json);
    }
}
@end
