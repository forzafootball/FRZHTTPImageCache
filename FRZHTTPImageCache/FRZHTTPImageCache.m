//
//  FRZHTTPImageCache.m
//  FRZHTTPImageCache
//
//  Created by Joel Ekström on 2017-08-15.
//  Copyright © 2017 Football Addicts AB. All rights reserved.
//

#import "FRZHTTPImageCache.h"
#import "FRZImageCacheManager.h"

@implementation FRZHTTPImageCache

static id<FRZHTTPImageCacheLogging> sharedLogger;

+ (id<FRZHTTPImageCacheLogging>)logger
{
    return sharedLogger;
}

+ (void)setLogger:(id<FRZHTTPImageCacheLogging>)logger
{
    sharedLogger = logger;
}

+ (void)initializeWithOptions:(FRZHTTPImageCacheOptions *)options
{
    [FRZImageCacheManager setSharedInstance:[[FRZImageCacheManager alloc] initWithOptions:options]];
}

@end
