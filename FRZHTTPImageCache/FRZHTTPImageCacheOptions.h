//
//  FRZHTTPImageCacheOptions.h
//  FRZHTTPImageCache
//
//  Created by Joel Ekström on 2017-08-15.
//  Copyright © 2017 Football Addicts AB. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FRZHTTPImageCacheOptions : NSObject

+ (instancetype)defaultOptions;

@property (nonatomic, assign) NSUInteger memoryCacheByteSizeLimit; // Default: 8 MiB
@property (nonatomic, assign) NSUInteger diskCacheByteSizeLimit;   // Default: 50 MiB

// If the image isn't accessed in this period, it will be garbage collected
@property (nonatomic, assign) NSTimeInterval defaultExpirationPeriod; // Default: 30 days

// A percentage of desired free disk space on the device. If the disk gets filled, the cache will be
// purged until this fraction is met.
@property (nonatomic, assign) float minimumFreeDiskSpaceFraction; // Default: 0.02, (2% free disk space)

// The identifier for your cache, for example com.yourCompany.FRZHTTPImageCache
@property (nonatomic, copy) NSString *cacheIdentifier; // Default: com.footballaddicts.FRZHTTPImageCache

@end
