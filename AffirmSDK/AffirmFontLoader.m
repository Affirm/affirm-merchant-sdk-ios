//
//  AffirmFontLoader.m
//  AffirmSDK
//
//  Created by Victor Zhu on 2020/9/24.
//  Copyright © 2020 Affirm, Inc. All rights reserved.
//

#import "AffirmFontLoader.h"
#import <CoreText/CoreText.h>
#import <UIKit/UIKit.h>
#import "AffirmConstants.h"
#import "AffirmUtils.h"

@implementation AffirmFontLoader

+ (void)loadFontIfNeeded
{
    if ([UIFont fontNamesForFamilyName:AffirmFontFamilyNameCalibre].count == 0) {
        NSBundle *bundle = [NSBundle resourceBundle];
        NSString *identifier = bundle.bundleIdentifier;

        NSArray *fonts = @[AffirmFontNameCalibreMedium, AffirmFontNameCalibreBold, AffirmFontNameCalibreSemibold, AffirmFontNameCalibreRegular, AffirmFontNameAlmaMonoBold];
        for (NSString *fontName in fonts) {
            NSURL *fontURL = nil;
            if ([identifier hasPrefix:@"org.cocoapods"]) {
                fontURL = [bundle URLForResource:fontName withExtension:@"otf" subdirectory:@"AffirmSDK.bundle"];
            } else {
                fontURL = [bundle URLForResource:fontName withExtension:@"otf"];
            }
            NSData *data = [NSData dataWithContentsOfURL:fontURL];
            CFErrorRef error;
            CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)data);
            CGFontRef font = CGFontCreateWithDataProvider(provider);
            if (!CTFontManagerRegisterGraphicsFont(font, &error)) {
                CFStringRef errorDescription = CFErrorCopyDescription(error);

                NSLog(@"Failed to load font: %@", errorDescription);
                CFRelease(errorDescription);
            }
            CGFontRelease(font);
            CGDataProviderRelease(provider);
        }
    }
}

@end
