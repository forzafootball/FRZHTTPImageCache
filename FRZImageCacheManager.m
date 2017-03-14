//
//  FRZImageCacheManager.m
//  Forza Football
//
//  Created by Joel Ekström on 2017-03-03.
//  Copyright © 2017 FootballAddicts. All rights reserved.
//

#import "FRZImageCacheManager.h"
#import <SPTPersistentCache/SPTPersistentCache.h>
#import "FRZHTTPImageCacheLogger.h"

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

#warning investigate how to solve garbage collection
        //[self.diskCache scheduleGarbageCollector];
    }
    return self;
}

- (FRZImageCacheEntry *)fetchImageForURL:(NSURL *)URL
{
    FRZImageCacheEntry *cachedImage = [self.memoryCache objectForKey:[self keyForURL:URL]];
    if (cachedImage) {
        [FRZHTTPImageCacheLogger.sharedLogger frz_logMessage:@"Returning image from memory cache" forImageURL:cachedImage.originalResponse.URL logLevel:FRZHTTPImageCacheLogVerbose];
        return cachedImage;
    }
    return [self diskCachedImageForURL:URL];
}

- (FRZImageCacheEntry *)diskCachedImageForURL:(NSURL *)URL
{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block FRZImageCacheEntry *cacheEntry = nil;
    [self.diskCache loadDataForKey:[self keyForURL:URL]
                      withCallback:^(SPTPersistentCacheResponse * _Nonnull response) {
                          if (response.error) {
                          } else {
                              if (response.result == SPTPersistentCacheResponseCodeOperationSucceeded) {
                                  NSData *data = response.record.data;
                                  cacheEntry = [NSKeyedUnarchiver unarchiveObjectWithData:data];
                                  NSAssert([cacheEntry.originalResponse.URL isEqual:URL], @"Cached entry didn't match requested URL. This probably means that there was a hash collision when generating keys.");

                                  // Store the entry in the memory cache for further requests
                                  [self storeEntryInMemoryCache:cacheEntry];
                                  [FRZHTTPImageCacheLogger.sharedLogger frz_logMessage:@"Returning image from disk cache (and propagating to memory cache)" forImageURL:cacheEntry.originalResponse.URL logLevel:FRZHTTPImageCacheLogVerbose];
                              }
                          }
                          dispatch_semaphore_signal(semaphore);
                      } onQueue:self.diskCacheQueue];
    dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC));
    return cacheEntry;
}

- (void)cacheImage:(UIImage *)image forURLResponse:(NSHTTPURLResponse *)response
{
    FRZImageCacheEntry *cacheEntry = [[FRZImageCacheEntry alloc] initWithImage:image response:response];
    if (cacheEntry == nil) {
        // If no cache entry was created, it means that this response shouldn't be cached
        return;
    }

    [self storeEntryInMemoryCache:cacheEntry];

    // We only want to store an entry in the disk cache if it is valid (has an image). Otherwise,
    // it's probably a 404 response, or a server error. We still want those in the memory cache to
    // avoid requests to that URL until the app is restarted.
    NSMutableIndexSet *acceptedStatuses = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 99)];
    [acceptedStatuses addIndex:304];
    if (image && [acceptedStatuses containsIndex:response.statusCode]) {
        [self storeEntryInDiskCache:cacheEntry];
    }
}

- (NSString *)keyForURL:(NSURL *)URL
{
    return @([URL hash]).stringValue;
}

- (void)storeEntryInMemoryCache:(FRZImageCacheEntry *)image
{
    [FRZHTTPImageCacheLogger.sharedLogger frz_logMessage:@"Storing image in memory cache..." forImageURL:image.originalResponse.URL logLevel:FRZHTTPImageCacheLogVerbose];
    [self.memoryCache setObject:image
                         forKey:[self keyForURL:image.originalResponse.URL]
                           cost:[self memoryCostForImage:image.image]];
}

- (void)storeEntryInDiskCache:(FRZImageCacheEntry *)image
{
    [FRZHTTPImageCacheLogger.sharedLogger frz_logMessage:@"Storing image in disk cache..." forImageURL:image.originalResponse.URL logLevel:FRZHTTPImageCacheLogVerbose];
    NSData *encodedData = [NSKeyedArchiver archivedDataWithRootObject:image];
    [self.diskCache storeData:encodedData
                       forKey:[self keyForURL:image.originalResponse.URL]
                       locked:NO
                 withCallback:nil
                      onQueue:nil];
}

- (NSUInteger)memoryCostForImage:(UIImage *)image
{
    return CGImageGetBytesPerRow(image.CGImage) * CGImageGetHeight(image.CGImage);
}

@end
