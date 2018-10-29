//
//  FRZImageCacheManager.m
//  Forza Football
//
//  Created by Joel Ekström on 2017-03-03.
//  Copyright © 2017 FootballAddicts. All rights reserved.
//

#import "FRZImageCacheManager.h"
#import <SPTPersistentCache/SPTPersistentCache.h>
#import <CommonCrypto/CommonDigest.h>
#import "FRZHTTPImageCache.h"

NS_ASSUME_NONNULL_BEGIN

@interface FRZImageCacheManager()

@property (nonatomic, strong) NSCache *memoryCache;
@property (nonatomic, strong) SPTPersistentCache *diskCache;
@property (nonatomic, strong) dispatch_queue_t diskCacheQueue;

@end

@implementation FRZImageCacheManager

static FRZImageCacheManager *sharedInstance = nil;

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!sharedInstance) {
            sharedInstance = [[FRZImageCacheManager alloc] initWithOptions:[FRZHTTPImageCacheOptions defaultOptions]];
        }
    });
    return sharedInstance;
}

+ (void)setSharedInstance:(FRZImageCacheManager *)manager
{
    sharedInstance = manager;
}

- (instancetype)initWithOptions:(FRZHTTPImageCacheOptions *)options
{
    if (self = [super init]) {
        self.memoryCache = [[NSCache alloc] init];
        self.memoryCache.totalCostLimit = options.memoryCacheByteSizeLimit;

        // Create the cache folder Library/Caches/cacheIdentifier
        NSString *cacheDirectory = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
        NSString *cacheDirectoryPath = [cacheDirectory stringByAppendingPathComponent:options.cacheIdentifier];

        SPTPersistentCacheOptions *persistentCacheOptions = [[SPTPersistentCacheOptions alloc] init];
        persistentCacheOptions.cachePath = cacheDirectoryPath;
        persistentCacheOptions.cacheIdentifier = options.cacheIdentifier;
        persistentCacheOptions.defaultExpirationPeriod = options.defaultExpirationPeriod;
        persistentCacheOptions.sizeConstraintBytes = options.diskCacheByteSizeLimit;
        persistentCacheOptions.minimumFreeDiskSpaceFraction = options.minimumFreeDiskSpaceFraction;

        self.diskCache = [[SPTPersistentCache alloc] initWithOptions:persistentCacheOptions];
        NSString *queueName = [NSString stringWithFormat:@"%@.diskQueue", options.cacheIdentifier];
        self.diskCacheQueue = dispatch_queue_create([queueName cStringUsingEncoding:NSUTF8StringEncoding], 0);

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidReceiveMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)applicationWillResignActive:(NSNotification *)notification
{
    [self.diskCache enqueueGarbageCollector];
}

- (void)applicationDidReceiveMemoryWarning:(NSNotification *)notification
{
    [self.memoryCache removeAllObjects];
}

- (nullable FRZImageCacheEntry *)fetchImageForURL:(NSURL *)URL
{
    FRZImageCacheEntry *cachedImage = [self memoryCachedImageForURL:URL];
    if (cachedImage) {
        [FRZHTTPImageCache.logger frz_logMessage:@"Returning image from memory cache" forImageURL:cachedImage.originalResponse.URL logLevel:FRZHTTPImageCacheLogLevelVerbose];
        return cachedImage;
    }
    return [self diskCachedImageForURL:URL];
}

- (nullable FRZImageCacheEntry *)memoryCachedImageForURL:(NSURL *)URL
{
    return [self.memoryCache objectForKey:[self keyForURL:URL]];
}

- (nullable FRZImageCacheEntry *)diskCachedImageForURL:(NSURL *)URL
{
    return [self diskCachedImageForURL:URL timeout:1.0];
}

- (nullable FRZImageCacheEntry *)diskCachedImageForURL:(NSURL *)URL timeout:(NSTimeInterval)timeout
{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block FRZImageCacheEntry *cacheEntry = nil;
    __block BOOL fetchBlockFinished = NO;
    [self.diskCache loadDataForKey:[self keyForURL:URL]
                      withCallback:^(SPTPersistentCacheResponse * _Nonnull response) {
                          if (response.error) {
                              [FRZHTTPImageCache.logger frz_logMessage:[NSString stringWithFormat:@"Failed to fetch image from disk cache. Error: %@", response.error] forImageURL:cacheEntry.originalResponse.URL logLevel:FRZHTTPImageCacheLogLevelError];
                          } else {
                              if (response.result == SPTPersistentCacheResponseCodeOperationSucceeded) {
                                  NSData *data = response.record.data;
                                  cacheEntry = [NSKeyedUnarchiver unarchiveObjectWithData:data];

                                  // Bufix, we accidentally stored 5xx responses in disk cache, so remove those if they come up.
                                  if (NSLocationInRange(cacheEntry.originalResponse.statusCode, NSMakeRange(500, 99))) {
                                      [self removeEntryInDiskCache:cacheEntry];
                                      cacheEntry = nil;
                                  } else {
                                      // Store the entry in the memory cache for further requests
                                      [self storeEntryInMemoryCache:cacheEntry];
                                      [FRZHTTPImageCache.logger frz_logMessage:@"Returning image from disk cache (and propagating to memory cache)" forImageURL:cacheEntry.originalResponse.URL logLevel:FRZHTTPImageCacheLogLevelVerbose];
                                  }
                              }
                          }
                          fetchBlockFinished = YES;
                          dispatch_semaphore_signal(semaphore);
                      } onQueue:self.diskCacheQueue];
    dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, timeout * NSEC_PER_SEC));

    if (!fetchBlockFinished) {
        [FRZHTTPImageCache.logger frz_logMessage:@"Aborted image fetch from disk cache because it took too long to retrieve." forImageURL:URL logLevel:FRZHTTPImageCacheLogLevelError];
    }

    return cacheEntry;
}

- (void)cacheImage:(nullable UIImage *)image forURLResponse:(NSHTTPURLResponse *)response
{
    FRZImageCacheEntry *cacheEntry = [[FRZImageCacheEntry alloc] initWithImage:image response:response];
    if (cacheEntry == nil) {
        // If no cache entry was created, it means that this response shouldn't be cached
        return;
    }

    // If response is 2xx or 304, store response in both memory and disk cache
    if (image && (response.statusCode == 304 || NSLocationInRange(response.statusCode, NSMakeRange(200, 99)))) {
        [self storeEntryInMemoryCache:cacheEntry];
        [self storeEntryInDiskCache:cacheEntry];
    }

    // If 4xx, remove the image from disk cache but keep in memory cache to avoid
    // multiple requests to empty endpoint this session
    else if (NSLocationInRange(response.statusCode, NSMakeRange(400, 99))) {
        [self storeEntryInMemoryCache:cacheEntry];
        [self removeEntryInDiskCache:cacheEntry];
    }

    // If 5xx, there was a server error. Store it in memory cache to avoid
    // excessive requests, but keep the disk cache for if/when the server comes back alive
    else if (NSLocationInRange(response.statusCode, NSMakeRange(500, 99))) {
        [self storeEntryInMemoryCache:cacheEntry];
    }
}

- (NSString *)keyForURL:(NSURL *)URL
{
    // MD5 hash. Using the built-in hash-function of NSURL/NSString is very collision prone
    const char *utf8String = [URL.absoluteString UTF8String];
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
    CC_MD5(utf8String, (CC_LONG)strlen(utf8String), md5Buffer);
    NSMutableString *hexString = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [hexString appendFormat:@"%02x", md5Buffer[i]];
    }
    return hexString;
}

- (void)storeEntryInMemoryCache:(FRZImageCacheEntry *)image
{
    [FRZHTTPImageCache.logger frz_logMessage:@"Storing image in memory cache..." forImageURL:image.originalResponse.URL logLevel:FRZHTTPImageCacheLogLevelVerbose];
    [self.memoryCache setObject:image
                         forKey:[self keyForURL:image.originalResponse.URL]
                           cost:[self memoryCostForImage:image.image]];
}

- (void)storeEntryInDiskCache:(FRZImageCacheEntry *)image
{
    [FRZHTTPImageCache.logger frz_logMessage:@"Storing image in disk cache..." forImageURL:image.originalResponse.URL logLevel:FRZHTTPImageCacheLogLevelVerbose];
    NSData *encodedData = [NSKeyedArchiver archivedDataWithRootObject:image];
    [self.diskCache storeData:encodedData
                       forKey:[self keyForURL:image.originalResponse.URL]
                       locked:NO
                 withCallback:nil
                      onQueue:nil];
}

- (void)removeEntryInDiskCache:(FRZImageCacheEntry *)image
{
    [FRZHTTPImageCache.logger frz_logMessage:@"Removing image from disk cache..." forImageURL:image.originalResponse.URL logLevel:FRZHTTPImageCacheLogLevelVerbose];
    [self.diskCache removeDataForKeys:@[[self keyForURL:image.originalResponse.URL]]
                             callback:nil
                              onQueue:nil];
}

- (NSUInteger)memoryCostForImage:(UIImage *)image
{
    return CGImageGetBytesPerRow(image.CGImage) * CGImageGetHeight(image.CGImage);
}

@end

NS_ASSUME_NONNULL_END
