//
//  FRZHTTPImageCache.h
//  FRZHTTPImageCache
//
//  Created by Joel Ekström on 2017-05-08.
//  Copyright © 2017 Football Addicts AB. All rights reserved.
//

#import <UIKit/UIKit.h>

FOUNDATION_EXPORT double FRZHTTPImageCacheVersionNumber;
FOUNDATION_EXPORT const unsigned char FRZHTTPImageCacheVersionString[];

#import <FRZHTTPImageCache/FRZImageFetchOperation.h>
#import <FRZHTTPImageCache/FRZHTTPImageCacheLogging.h>
#import <FRZHTTPImageCache/UIImageView+FRZHTTPImageCache.h>
#import <FRZHTTPImageCache/FRZHTTPImageCacheOptions.h>

@interface FRZHTTPImageCache : NSObject

+ (void)initializeWithOptions:(nonnull FRZHTTPImageCacheOptions *)options;

@property (nullable, class, nonatomic, strong) id<FRZHTTPImageCacheLogging> logger;

@end
