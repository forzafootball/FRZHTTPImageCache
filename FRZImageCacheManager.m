//
//  FRZImageCacheManager.m
//  Forza Football
//
//  Created by Joel Ekström on 2017-03-03.
//  Copyright © 2017 FootballAddicts. All rights reserved.
//

#import "FRZImageCacheManager.h"
#import <SPTPersistentCache/SPTPersistentCache.h>

@interface FRZImageCacheManager()

@property (nonatomic, strong) NSCache *memoryCache;
@property (nonatomic, strong) SPTPersistentCache *diskCache;
@property (nonatomic, strong) dispatch_queue_t diskCacheQueue;

@end

@implementation FRZImageCacheManager

+ (instancetype)sharedInstance
{
    static FRZImageCacheManager *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[FRZImageCacheManager alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    if (self = [super init]) {
        self.memoryCache = [[NSCache alloc] init];
        self.memoryCache.totalCostLimit = 1024 * 1024 * 5; // Default to 5MB in-memory cache

        // Create the cache folder Library/Caches/com.footballaddicts.FRZHTTPImageCache
        NSString *cacheDirectory = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
        NSString *cacheIdentifier = @"com.footballaddicts.FRZHTTPImageCache";
        NSString *cacheDirectoryPath = [cacheDirectory stringByAppendingPathComponent:cacheIdentifier];

        SPTPersistentCacheOptions *options = [[SPTPersistentCacheOptions alloc] init];
        options.cachePath = cacheDirectoryPath;
        options.cacheIdentifier = cacheIdentifier;
        options.defaultExpirationPeriod = 60 * 60 * 24 * 30; // If an image isn't accessed for 30 days, the garbage collector can remove it
        options.sizeConstraintBytes = 1024 * 1024 * 30; // We store at most 30 MiB of images

        self.diskCache = [[SPTPersistentCache alloc] initWithOptions:options];
        self.diskCacheQueue = dispatch_queue_create("com.footballaddicts.FRZHTTPImageCache.diskQueue", 0);

        [self.diskCache scheduleGarbageCollector];
    }
    return self;
}

- (FRZCachedImage *)cachedImageForURL:(NSURL *)URL
{
    FRZCachedImage *cachedImage = [self.memoryCache objectForKey:[self keyForURL:URL]];
    if (cachedImage) {
        return cachedImage;
    }
    return [self diskCachedImageForURL:URL];
}

- (FRZCachedImage *)diskCachedImageForURL:(NSURL *)URL
{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block FRZCachedImage *cachedImage = nil;
    [self.diskCache loadDataForKey:[self keyForURL:URL]
                      withCallback:^(SPTPersistentCacheResponse * _Nonnull response) {
                          if (response.error) {
#warning check errors
                          } else {
                              if (response.result == SPTPersistentCacheResponseCodeOperationSucceeded) {
                                  NSData *data = response.record.data;
                                  cachedImage = [NSKeyedUnarchiver unarchiveObjectWithData:data];

                                  // Store the image in the memory cache for further requests
                                  [self storeImageInDiskCache:cachedImage];
                              }
                          }
                          dispatch_semaphore_signal(semaphore);
                      } onQueue:self.diskCacheQueue];
    dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC));
    return cachedImage;
}

- (void)cacheImage:(FRZCachedImage *)image
{
    [self storeImageInMemoryCache:image];
    [self storeImageInDiskCache:image];
}

- (NSString *)keyForURL:(NSURL *)URL
{
    return @([URL hash]).stringValue;
}

- (void)storeImageInMemoryCache:(FRZCachedImage *)image
{
    [self.memoryCache setObject:image
                         forKey:[self keyForURL:image.originalResponse.URL]
                           cost:[self memoryCostForImage:image.image]];
}

- (void)storeImageInDiskCache:(FRZCachedImage *)image
{
    NSData *encodedData = [NSKeyedArchiver archivedDataWithRootObject:image];
    [self.diskCache storeData:encodedData
                       forKey:[self keyForURL:image.originalResponse.URL]
                       locked:NO
                 withCallback:nil
                      onQueue:nil];
}

- (NSUInteger)memoryCostForImage:(UIImage *)image
{
    if (image.CGImage) {
        return CGImageGetBytesPerRow(image.CGImage) * CGImageGetHeight(image.CGImage);
    } else if (image.CIImage) {
#warning remove
        NSAssert(NO, @"Just testing if we ever get CIImages....");
    }
    return 0;
}

@end
