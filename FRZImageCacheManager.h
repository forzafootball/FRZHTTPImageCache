//
//  FRZImageCacheManager.h
//  Forza Football
//
//  Created by Joel Ekström on 2017-03-03.
//  Copyright © 2017 FootballAddicts. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FRZCachedImage.h"

@interface FRZImageCacheManager : NSObject

+ (instancetype)sharedInstance;

- (FRZCachedImage *)cachedImageForURL:(NSURL *)URL;
- (void)cacheImage:(FRZCachedImage *)image;

@end
