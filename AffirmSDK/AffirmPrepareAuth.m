//
//  AffirmPrepareAuth.m
//  AffirmSDK
//
//  PKCE code challenge for Connected Accounts.
//

#import "AffirmPrepareAuth.h"
#import <CommonCrypto/CommonDigest.h>
#import <Security/Security.h>

static const size_t AffirmCodeVerifierByteCount = 32;

typedef BOOL (^AffirmRandomBytesHandler)(size_t count, uint8_t *bytes);

static NSString *AffirmStoredCodeVerifier;
static NSString *AffirmStoredCodeChallenge;
static AffirmRandomBytesHandler AffirmRandomBytes;

static NSString *AffirmBase64URLEncode(NSData *data)
{
    NSString *base64 = [data base64EncodedStringWithOptions:0];
    base64 = [base64 stringByReplacingOccurrencesOfString:@"+" withString:@"-"];
    base64 = [base64 stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    return [base64 stringByReplacingOccurrencesOfString:@"=" withString:@""];
}

@implementation AffirmPrepareAuthResult

- (instancetype)initWithStatus:(AffirmPrepareAuthStatus)status codeChallenge:(nullable NSString *)codeChallenge
{
    if (self = [super init]) {
        _status = status;
        _codeChallenge = [codeChallenge copy];
    }
    return self;
}

@end

@implementation AffirmPrepareAuth

+ (void)prepareAuthWithCompletion:(void (^)(AffirmPrepareAuthResult *result))completion
{
    AffirmPrepareAuthResult *result = [self prepareAuth];
    if (completion) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(result);
        });
    }
}

+ (AffirmPrepareAuthResult *)prepareAuth
{
    @synchronized (self) {
        if (AffirmStoredCodeVerifier && AffirmStoredCodeChallenge) {
            return [[AffirmPrepareAuthResult alloc] initWithStatus:AffirmPrepareAuthStatusPending
                                                     codeChallenge:AffirmStoredCodeChallenge];
        }
        NSMutableData *bytes = [NSMutableData dataWithLength:AffirmCodeVerifierByteCount];
        BOOL generated = AffirmRandomBytes
            ? AffirmRandomBytes(bytes.length, bytes.mutableBytes)
            : SecRandomCopyBytes(kSecRandomDefault, bytes.length, bytes.mutableBytes) == errSecSuccess;
        if (!generated) {
            return [[AffirmPrepareAuthResult alloc] initWithStatus:AffirmPrepareAuthStatusUnavailable codeChallenge:nil];
        }
        AffirmStoredCodeVerifier = AffirmBase64URLEncode(bytes);
        AffirmStoredCodeChallenge = [self codeChallengeForVerifier:AffirmStoredCodeVerifier];
        return [[AffirmPrepareAuthResult alloc] initWithStatus:AffirmPrepareAuthStatusPending
                                                 codeChallenge:AffirmStoredCodeChallenge];
    }
}

// Internal. Not in a header: CocoaPods makes every header in AffirmSDK/ public, and merchants must
// never get the verifier. Callers declare it in a category.
+ (nullable NSString *)consumeStoredCodeVerifier
{
    @synchronized (self) {
        NSString *verifier = AffirmStoredCodeVerifier;
        AffirmStoredCodeVerifier = nil;
        AffirmStoredCodeChallenge = nil;
        return verifier;
    }
}

+ (NSString *)codeChallengeForVerifier:(NSString *)verifier
{
    NSData *input = [verifier dataUsingEncoding:NSASCIIStringEncoding];
    uint8_t digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(input.bytes, (CC_LONG)input.length, digest);
    return AffirmBase64URLEncode([NSData dataWithBytes:digest length:sizeof(digest)]);
}

// Internal, for tests: replaces the random source. Nil restores SecRandomCopyBytes.
+ (void)setRandomBytesHandler:(nullable AffirmRandomBytesHandler)handler
{
    @synchronized (self) {
        AffirmRandomBytes = [handler copy];
    }
}

@end
