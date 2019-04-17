//
//  AffirmJSONifiable.h
//  AffirmSDK
//
//  Created by Paul on 3/18/19.
//  Copyright © 2019 Affirm, Inc. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

/**
 The AffirmJSONifiable protocol specifies that an object is JSONifiable.
 */
@protocol AffirmJSONifiable <NSObject>

/**
 Create a JSON dictionary from the current object.

 @return A JSON dictionary representing the current object.
 */
- (NSMutableDictionary *)toJSONDictionary;

@end

NS_ASSUME_NONNULL_END
