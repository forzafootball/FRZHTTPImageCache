//
//  FRZImageCacheManager.h
//  Forza Football
//
//  Created by Joel Ekström on 2017-03-03.
//  Copyright © 2017 FootballAddicts. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FRZImageCacheEntry.h"

NS_ASSUME_NONNULL_BEGIN

@interface FRZImageCacheManager : NSObject

+ (instancetype)sharedInstance;

- (nullable FRZImageCacheEntry *)fetchImageForURL:(NSURL *)URL;
- (void)cacheImage:(nullable UIImage *)image forURLResponse:(NSHTTPURLResponse *)response;

@end

NS_ASSUME_NONNULL_END
