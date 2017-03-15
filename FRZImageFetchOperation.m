//
//  FZFImageRequestOperation.m
//  Forza Football
//
//  Created by Joel Ekström on 2017-03-03.
//  Copyright © 2017 FootballAddicts. All rights reserved.
//

#import "FRZImageFetchOperation.h"
#import "FRZHTTPImageRequestOperation.h"
#import "FRZHTTPImageCacheLogger.h"
#import "FRZImageCacheManager.h"

@interface FRZImageFetchOperation() {
    NSURL *_URL;
}

@property (nonatomic, strong) UIImage *image;

@end

@implementation FRZImageFetchOperation

- (instancetype)initWithURL:(NSURL *)URL
{
    if (self = [super init]) {
        _URL = URL;
    }
    return self;
}

- (void)start
{
    [super start];
    if (self.isCancelled) {
        return;
    }

    [FRZHTTPImageCacheLogger.sharedLogger frz_logMessage:@"Image fetch operation starting" forImageURL:_URL logLevel:FRZHTTPImageCacheLogLevelVerbose];

    // Do we have this object in the cache?
    FRZImageCacheEntry *cacheEntry = [[FRZImageCacheManager sharedInstance] fetchImageForURL:_URL];

    if (cacheEntry == nil || cacheEntry.needsRevalidation) {
        [FRZHTTPImageCacheLogger.sharedLogger frz_logMessage:cacheEntry == nil ?
         @"Image does not exist in cache, will perform network request" :
         @"Image exists in cache but needs revalidation, will perform network request" forImageURL:_URL logLevel:FRZHTTPImageCacheLogLevelVerbose];

        FRZHTTPImageRequestOperation *requestOperation = [FRZImageFetchOperation requestOperationForURL:_URL];
        if (requestOperation == nil) {
            requestOperation = [[FRZHTTPImageRequestOperation alloc] initWithURL:_URL cacheEntry:cacheEntry];
            [[FRZImageFetchOperation requestQueue] addOperation:requestOperation];
        } else {
            [FRZHTTPImageCacheLogger.sharedLogger frz_logMessage:@"Another network request is ongoing for this URL, hooking into current one..." forImageURL:_URL logLevel:FRZHTTPImageCacheLogLevelVerbose];
        }

        NSOperation *completionOperation = [NSBlockOperation blockOperationWithBlock:^{
            if (requestOperation.response.statusCode == 304) {
                _result = FRZImageFetchOperationResultFromCacheRevalidated;
                [FRZHTTPImageCacheLogger.sharedLogger frz_logMessage:@"Cache was revalidated and still valid, reusing current image from cache" forImageURL:_URL logLevel:FRZHTTPImageCacheLogLevelVerbose];
            } else if (requestOperation.image) {
                _result = FRZImageFetchOperationResultFromNetwork;
                [FRZHTTPImageCacheLogger.sharedLogger frz_logMessage:@"Network request returned a new image" forImageURL:_URL logLevel:FRZHTTPImageCacheLogLevelVerbose];
            } else if (requestOperation.response) {
                _result = FRZImageFetchOperationResultInvalidURL;
                [FRZHTTPImageCacheLogger.sharedLogger frz_logMessage:[NSString stringWithFormat:@"Network request finished with an error (%li), caching as non-existing image URL", requestOperation.response.statusCode] forImageURL:_URL logLevel:FRZHTTPImageCacheLogLevelWarning];
            }

            UIImage *image = requestOperation.image;
            if (image && _result == FRZImageFetchOperationResultFromNetwork && self.transformBlock) {
                image = self.transformBlock(image);
                [FRZHTTPImageCacheLogger.sharedLogger frz_logMessage:@"Applying image transforms from delegate..." forImageURL:_URL logLevel:FRZHTTPImageCacheLogLevelVerbose];
            }

            [[FRZImageCacheManager sharedInstance] cacheImage:image forURLResponse:requestOperation.response];
            self.image = image;
            [self finish];
        }];
        [completionOperation addDependency:requestOperation];
        [[FRZImageFetchOperation requestQueue] addOperation:completionOperation];
    } else {
        self.image = cacheEntry.image;
        if (self.image) {
            _result = FRZImageFetchOperationResultFromCache;
        } else {
            _result = FRZImageFetchOperationResultInvalidURL;
            [FRZHTTPImageCacheLogger.sharedLogger frz_logMessage:[NSString stringWithFormat:@"The requested URL was found in cache but marked as invalid (%li)", cacheEntry.originalResponse.statusCode] forImageURL:_URL logLevel:FRZHTTPImageCacheLogLevelWarning];
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
    });
    return imageRequestQueue;
}

+ (NSOperationQueue *)imageFetchQueue
{
    static NSOperationQueue *imageFetchQueue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        imageFetchQueue = [NSOperationQueue new];
    });
    return imageFetchQueue;
}

@end
