//
//  FRZHTTPImageCacheOptions.m
//  FRZHTTPImageCache
//
//  Created by Joel Ekström on 2017-08-15.
//  Copyright © 2017 Football Addicts AB. All rights reserved.
//

#import "FRZHTTPImageCacheOptions.h"

@implementation FRZHTTPImageCacheOptions

+ (instancetype)defaultOptions
{
    return [[self alloc] init];
}

- (instancetype)init
{
    if (self = [super init]) {
        self.memoryCacheByteSizeLimit = 1024 * 1024 * 8; // 8 MiB
        self.diskCacheByteSizeLimit = 1024 * 1024 * 50; // 50 MiB
        self.defaultExpirationPeriod = 60 * 60 * 24 * 30; // 30 days
        self.minimumFreeDiskSpaceFraction = 0.02;
        self.cacheIdentifier = @"com.footballaddicts.FRZHTTPImageCache";
    }
    return self;
}

@end
