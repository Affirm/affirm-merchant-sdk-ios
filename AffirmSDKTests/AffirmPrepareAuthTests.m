//
//  AffirmPrepareAuthTests.m
//  AffirmSDKTests
//

#import <XCTest/XCTest.h>
#import <CommonCrypto/CommonDigest.h>
#import "../AffirmSDK/AffirmPrepareAuth.h"

@interface AffirmPrepareAuth (Testing)
+ (nullable NSString *)consumeStoredCodeVerifier;
+ (NSString *)codeChallengeForVerifier:(NSString *)verifier;
+ (void)setRandomBytesHandler:(nullable BOOL (^)(size_t count, uint8_t *bytes))handler;
@end

@interface AffirmPrepareAuthTests : XCTestCase
@end

@implementation AffirmPrepareAuthTests

- (void)setUp
{
    self.continueAfterFailure = NO;
    [AffirmPrepareAuth setRandomBytesHandler:nil];
    [AffirmPrepareAuth consumeStoredCodeVerifier];
}

- (void)tearDown
{
    [AffirmPrepareAuth setRandomBytesHandler:nil];
    [AffirmPrepareAuth consumeStoredCodeVerifier];
}

- (AffirmPrepareAuthResult *)prepareAuth
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"prepareAuth completion"];
    __block AffirmPrepareAuthResult *result;
    [AffirmPrepareAuth prepareAuthWithCompletion:^(AffirmPrepareAuthResult *value) {
        XCTAssertTrue(NSThread.isMainThread);
        result = value;
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:2 handler:nil];
    return result;
}

- (void)assertBase64URLWithoutPadding:(NSString *)value length:(NSUInteger)length
{
    XCTAssertEqual(value.length, length);
    NSCharacterSet *allowed = [NSCharacterSet characterSetWithCharactersInString:
                               @"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"];
    XCTAssertEqual([value rangeOfCharacterFromSet:allowed.invertedSet].location, NSNotFound, @"%@", value);
}

- (void)testReturnsPendingWithACodeChallenge
{
    AffirmPrepareAuthResult *result = [self prepareAuth];
    XCTAssertEqual(result.status, AffirmPrepareAuthStatusPending);
    // A SHA-256 hash is 32 bytes, 43 base64url characters without padding.
    [self assertBase64URLWithoutPadding:result.codeChallenge length:43];
}

- (void)testRepeatedCallsReturnTheSameChallengeUntilConsumed
{
    NSString *first = [self prepareAuth].codeChallenge;
    XCTAssertEqualObjects([self prepareAuth].codeChallenge, first);

    [AffirmPrepareAuth consumeStoredCodeVerifier];
    NSString *next = [self prepareAuth].codeChallenge;
    XCTAssertNotNil(next);
    XCTAssertNotEqualObjects(next, first);
}

- (void)testConsumedVerifierMatchesTheChallengeAndIsSingleUse
{
    NSString *challenge = [self prepareAuth].codeChallenge;
    NSString *verifier = [AffirmPrepareAuth consumeStoredCodeVerifier];

    // 32 random bytes are 43 base64url characters without padding.
    [self assertBase64URLWithoutPadding:verifier length:43];
    NSData *input = [verifier dataUsingEncoding:NSASCIIStringEncoding];
    uint8_t digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(input.bytes, (CC_LONG)input.length, digest);
    NSString *hash = [[[[[NSData dataWithBytes:digest length:sizeof(digest)] base64EncodedStringWithOptions:0]
                        stringByReplacingOccurrencesOfString:@"+" withString:@"-"]
                       stringByReplacingOccurrencesOfString:@"/" withString:@"_"]
                      stringByReplacingOccurrencesOfString:@"=" withString:@""];
    XCTAssertEqualObjects(hash, challenge);

    XCTAssertNil([AffirmPrepareAuth consumeStoredCodeVerifier]);
}

- (void)testConsumeWithoutPrepareReturnsNil
{
    XCTAssertNil([AffirmPrepareAuth consumeStoredCodeVerifier]);
}

- (void)testChallengeMatchesTheRFC7636Example
{
    // RFC 7636, Appendix B.
    XCTAssertEqualObjects([AffirmPrepareAuth codeChallengeForVerifier:@"dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"],
                          @"E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM");
}

- (void)testReturnsUnavailableWhenRandomBytesFail
{
    [AffirmPrepareAuth setRandomBytesHandler:^BOOL(size_t count, uint8_t *bytes) {
        return NO;
    }];
    AffirmPrepareAuthResult *result = [self prepareAuth];
    XCTAssertEqual(result.status, AffirmPrepareAuthStatusUnavailable);
    XCTAssertNil(result.codeChallenge);
    XCTAssertNil([AffirmPrepareAuth consumeStoredCodeVerifier], @"a failed call should store nothing");

    [AffirmPrepareAuth setRandomBytesHandler:nil];
    XCTAssertEqual([self prepareAuth].status, AffirmPrepareAuthStatusPending, @"a later call should still work");
}

- (void)testConcurrentCallsShareOneChallenge
{
    NSMutableSet<NSString *> *challenges = [NSMutableSet set];
    NSInteger count = 20;
    NSMutableArray<XCTestExpectation *> *expectations = [NSMutableArray array];
    for (NSInteger i = 0; i < count; i++) {
        XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"call %ld", (long)i]];
        [expectations addObject:expectation];
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
            [AffirmPrepareAuth prepareAuthWithCompletion:^(AffirmPrepareAuthResult *result) {
                [challenges addObject:result.codeChallenge];
                [expectation fulfill];
            }];
        });
    }
    [self waitForExpectations:expectations timeout:5];
    XCTAssertEqual(challenges.count, 1);
}

@end
