//
//  AffirmPrepareAuth.h
//  AffirmSDK
//
//  PKCE code challenge for Connected Accounts.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, AffirmPrepareAuthStatus) {
    /// A code challenge is ready. Send it to your server to get a session code.
    AffirmPrepareAuthStatusPending,
    /// No code challenge could be made. Check out without a session code.
    AffirmPrepareAuthStatusUnavailable,
};

@interface AffirmPrepareAuthResult : NSObject

/**
 Whether a code challenge is available.
 */
@property (nonatomic, readonly) AffirmPrepareAuthStatus status;

/**
 The PKCE code challenge, base64url-encoded. Nil when the status is unavailable.
 */
@property (nonatomic, copy, nullable, readonly) NSString *codeChallenge;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

/**
 Prepares the PKCE code challenge for a Connected Accounts accelerated checkout.

 The SDK keeps the matching code verifier and adds it to the next checkout that has a session code.
 The verifier is never exposed. A challenge can be used for one checkout only; call this again for
 each checkout.
 */
@interface AffirmPrepareAuth : NSObject

/**
 Returns the code challenge to send to your server, which exchanges it for a session code.

 Until a checkout uses it, repeated calls return the same challenge. If the result is unavailable,
 proceed with a standard checkout without a session code.

 @param completion Called on the main queue with the result.
 */
+ (void)prepareAuthWithCompletion:(void (^)(AffirmPrepareAuthResult *result))completion
NS_SWIFT_NAME(prepareAuth(completion:));

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
