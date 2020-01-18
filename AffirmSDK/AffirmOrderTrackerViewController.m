//
//  AffirmOrderTrackerViewController.m
//  AffirmSDK
//
//  Created by Victor Zhu on 2019/4/4.
//  Copyright © 2019 Affirm, Inc. All rights reserved.
//

#import "AffirmOrderTrackerViewController.h"
#import "AffirmOrder.h"
#import "AffirmProduct.h"
#import "AffirmConfiguration.h"
#import "AffirmConstants.h"
#import "AffirmUtils.h"
#import "AffirmActivityIndicatorView.h"

@interface AffirmOrderTrackerViewController ()

@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, copy, readwrite) AffirmOrder *order;
@property (nonatomic, copy, readwrite) NSArray <AffirmProduct *>*products;

@end

@implementation AffirmOrderTrackerViewController

- (instancetype)initWithOrder:(AffirmOrder *)order
                      product:(NSArray <AffirmProduct *>*)products
{
    [AffirmValidationUtils checkNotNil:order name:@"order"];
    [AffirmValidationUtils checkNotNil:products name:@"products"];

    if (self = [super initWithNibName:nil bundle:nil]) {
        _order = [order copy];
        _products = [[NSArray alloc] initWithArray:products copyItems:YES];
    }
    return self;
}

+ (void)trackOrder:(AffirmOrder *)order products:(NSArray <AffirmProduct *>*)products
{
    AffirmOrderTrackerViewController *trackerViewController = [[self alloc] initWithOrder:order product:products];
    [self loadView:trackerViewController.view];
}

+ (void)loadView:(UIView *)view
{
    UIWindow *window = [UIApplication sharedApplication].delegate.window;
    view.frame = window.bounds;
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [window insertSubview:view atIndex:0];
}

- (void)unloadView
{
    [self.view removeFromSuperview];
    self.view = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.hidden = YES;

    WKWebViewConfiguration *configuration = [WKWebViewConfiguration new];
    configuration.applicationNameForUserAgent = [NSString stringWithFormat:@"Affirm-iOS-SDK-%@", [AffirmConfiguration affirmSDKVersion]];
    WKWebView *webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:configuration];
    webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    webView.contentMode = UIViewContentModeScaleAspectFit;
    webView.multipleTouchEnabled = NO;
    [self.view addSubview:webView];
    self.webView = webView;

    NSString *jsURL = [AffirmConfiguration sharedInstance].jsURL;
    NSString *filePath = [[NSBundle resourceBundle] pathForResource:@"affirm_track_order_confirmed"
                                                             ofType:@"html"];
    __block NSString *rawContent = [NSString stringWithContentsOfFile:filePath
                                                             encoding:NSUTF8StringEncoding error:nil];
    NSString *orderString = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:self.order.toJSONDictionary
                                                                                           options:NSJSONWritingPrettyPrinted
                                                                                             error:nil]
                                                  encoding:NSUTF8StringEncoding];
    NSMutableArray *array = [NSMutableArray array];
    for (AffirmProduct *product in self.products) {
        [array addObject:product.toJSONDictionary];
    }
    NSString *productsString = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:array
                                                                                              options:NSJSONWritingPrettyPrinted
                                                                                                error:nil]
                                                     encoding:NSUTF8StringEncoding];

    [@{@"{{PUBLIC_KEY}}": [AffirmConfiguration sharedInstance].publicKey,
       @"{{JS_URL}}": jsURL,
       @"{{TRACK_ORDER_OBJECT}}": orderString,
       @"{{TRACK_PRODUCTS_OBJECT}}": productsString}
     enumerateKeysAndObjectsUsingBlock:^(NSString *  _Nonnull key, NSString *  _Nonnull obj, BOOL * _Nonnull stop) {
         rawContent = [rawContent stringByReplacingOccurrencesOfString:key
                                                            withString:obj
                                                               options:NSLiteralSearch
                                                                 range:[rawContent rangeOfString:key]];
     }];
    NSString *baseUrl = [NSString stringWithFormat:@"https://%@", [NSURL URLWithString:jsURL].host];
    [self.webView loadHTMLString:rawContent baseURL:[NSURL URLWithString:baseUrl]];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self unloadView];
    });
}

@end
