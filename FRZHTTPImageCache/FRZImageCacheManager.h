//
//  FRZImageCacheManager.h
//  Forza Football
//
//  Created by Joel Ekström on 2017-03-03.
//  Copyright © 2017 FootballAddicts. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FRZImageCacheEntry.h"
#import "FRZHTTPImageCache.h"

NS_ASSUME_NONNULL_BEGIN

@interface FRZImageCacheManager : NSObject

+ (instancetype)sharedInstance;
+ (void)setSharedInstance:(FRZImageCacheManager *)manager;

- (instancetype)initWithOptions:(FRZHTTPImageCacheOptions *)options;

- (nullable FRZImageCacheEntry *)fetchImageForURL:(NSURL *)URL;
- (void)cacheImage:(nullable UIImage *)image forURLResponse:(NSHTTPURLResponse *)response;

- (nullable FRZImageCacheEntry *)memoryCachedImageForURL:(NSURL *)URL;

@end

NS_ASSUME_NONNULL_END
