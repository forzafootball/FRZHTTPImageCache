//
//  FZFImageRequestOperation.m
//  Forza Football
//
//  Created by Joel Ekström on 2017-03-03.
//  Copyright © 2017 FootballAddicts. All rights reserved.
//

#import "FRZHTTPImageCache.h"
#import "FRZHTTPImageRequestOperation.h"
#import "FRZImageCacheManager.h"

@interface FRZImageFetchOperation() {
    BOOL _isExecuting;
    BOOL _isFinished;
}

@property (nonatomic, strong) NSURL *URL;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, assign) FRZImageFetchOperationResult result;

@end

@implementation FRZImageFetchOperation

#import "AsyncOperationBoilerPlate.h"

- (instancetype)initWithURL:(NSURL *)URL
{
    if (self = [super init]) {
        self.URL = URL;
    }
    return self;
}

- (void)start
{
    if ([self isCancelled]) {
        [self finish];
        return;
    }

    if (!self.URL || self.URL.absoluteString.length == 0) {
        self.result = FRZImageFetchOperationResultInvalidURL;
        [self finish];
        return;
    }

    [self setExecuting:YES];
    [FRZHTTPImageCache.logger frz_logMessage:@"Image fetch operation starting" forImageURL:self.URL logLevel:FRZHTTPImageCacheLogLevelVerbose];

    // Do we have this object in the cache?
    FRZImageCacheEntry *cacheEntry = [[FRZImageCacheManager sharedInstance] fetchImageForURL:self.URL];

    if (cacheEntry == nil || cacheEntry.needsRevalidation) {
        [FRZHTTPImageCache.logger frz_logMessage:cacheEntry == nil ?
         @"Image does not exist in cache, will perform network request" :
         @"Image exists in cache but needs revalidation, will perform network request" forImageURL:self.URL logLevel:FRZHTTPImageCacheLogLevelVerbose];

        if (cacheEntry.image && [self.delegate respondsToSelector:@selector(fetchOperation:willRevalidateCachedImage:)]) {
            [self.delegate fetchOperation:self willRevalidateCachedImage:cacheEntry.image];
        }

        FRZHTTPImageRequestOperation *requestOperation = [FRZImageFetchOperation requestOperationForURL:self.URL];
        if (requestOperation == nil) {
            requestOperation = [[FRZHTTPImageRequestOperation alloc] initWithURL:self.URL cacheEntry:cacheEntry];
            [[FRZImageFetchOperation requestQueue] addOperation:requestOperation];
        } else {
            [FRZHTTPImageCache.logger frz_logMessage:@"Another network request is ongoing for this URL, hooking into current one..." forImageURL:self.URL logLevel:FRZHTTPImageCacheLogLevelVerbose];
        }

        NSOperation *completionOperation = [NSBlockOperation blockOperationWithBlock:^{
            if (requestOperation.response.statusCode == 304) {
                self.result = FRZImageFetchOperationResultFromCacheRevalidated;
                [FRZHTTPImageCache.logger frz_logMessage:@"Cache was revalidated and still valid, reusing current image from cache" forImageURL:self.URL logLevel:FRZHTTPImageCacheLogLevelVerbose];
            } else if (requestOperation.image) {
                self.result = FRZImageFetchOperationResultFromNetwork;
                [FRZHTTPImageCache.logger frz_logMessage:@"Network request returned a new image" forImageURL:self.URL logLevel:FRZHTTPImageCacheLogLevelVerbose];
            } else if (requestOperation.response) {
                self.result = FRZImageFetchOperationResultInvalidURL;
                [FRZHTTPImageCache.logger frz_logMessage:[NSString stringWithFormat:@"Network request finished with an error (%li), caching as non-existing image URL", (long)requestOperation.response.statusCode] forImageURL:self.URL logLevel:FRZHTTPImageCacheLogLevelWarning];
            }

            UIImage *image = requestOperation.image;
            if (image && self.result == FRZImageFetchOperationResultFromNetwork && self.transformBlock) {
                image = self.transformBlock(image);
                [FRZHTTPImageCache.logger frz_logMessage:@"Applying image transforms from delegate..." forImageURL:self.URL logLevel:FRZHTTPImageCacheLogLevelVerbose];
            }

            if (requestOperation.response) {
                [[FRZImageCacheManager sharedInstance] cacheImage:image forURLResponse:requestOperation.response];
            } else {
                [FRZHTTPImageCache.logger frz_logMessage:@"Network request failed for image request. Will not store anything to cache." forImageURL:self.URL logLevel:FRZHTTPImageCacheLogLevelVerbose];
            }

            self.image = image;
            [self finish];
        }];
        [completionOperation addDependency:requestOperation];
        [[FRZImageFetchOperation requestQueue] addOperation:completionOperation];
    } else {
        self.image = cacheEntry.image;
        if (self.image) {
            self.result = FRZImageFetchOperationResultFromCache;
        } else {
            self.result = FRZImageFetchOperationResultInvalidURL;
            [FRZHTTPImageCache.logger frz_logMessage:[NSString stringWithFormat:@"The requested URL was found in cache but marked as invalid (%li)", (long)cacheEntry.originalResponse.statusCode] forImageURL:self.URL logLevel:FRZHTTPImageCacheLogLevelWarning];
        }
        [self finish];
    }
}

- (void)setMainThreadCompletionBlock:(void (^)(UIImage *, FRZImageFetchOperationResult))completionBlock
{
    __weak typeof(self) weakSelf = self;
    [self setCompletionBlock:^{
        UIImage *image = weakSelf.image;
        FRZImageFetchOperationResult result = weakSelf.result;
        dispatch_async(dispatch_get_main_queue(), ^{
            completionBlock(image, result);
        });
    }];
}

/**
 If there's already a network request ongoing for this URL, returns the current operation.
 This allows any new requests to hook into that request instead of creating a new one.
 */
+ (FRZHTTPImageRequestOperation *)requestOperationForURL:(NSURL *)URL
{
    for (NSOperation *operation in [FRZImageFetchOperation requestQueue].operations) {
        if ([operation isKindOfClass:[FRZHTTPImageRequestOperation class]]) {
            FRZHTTPImageRequestOperation *requestOperation = (FRZHTTPImageRequestOperation *)operation;
            if ([requestOperation.URL isEqual:URL]) {
                return requestOperation;
            }
        }
    }
    return nil;
}

+ (NSOperationQueue *)requestQueue
{
    static NSOperationQueue *imageRequestQueue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        imageRequestQueue = [NSOperationQueue new];
        imageRequestQueue.qualityOfService = NSQualityOfServiceUserInitiated;
    });
    return imageRequestQueue;
}

+ (NSOperationQueue *)imageFetchQueue
{
    static NSOperationQueue *imageFetchQueue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        imageFetchQueue = [NSOperationQueue new];
        imageFetchQueue.qualityOfService = NSQualityOfServiceUserInteractive;
    });
    return imageFetchQueue;
}

@end
