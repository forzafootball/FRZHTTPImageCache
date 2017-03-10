//
//  FZFImageRequestOperation.m
//  Forza Football
//
//  Created by Joel Ekström on 2017-03-03.
//  Copyright © 2017 FootballAddicts. All rights reserved.
//

#import "FRZImageFetchOperation.h"
#import "FRZHTTPImageRequestOperation.h"
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

    // Do we have this object in the cache?
    FRZImageCacheEntry *cacheEntry = [[FRZImageCacheManager sharedInstance] fetchImageForURL:_URL];

    if (cacheEntry == nil || cacheEntry.needsRevalidation) {
        FRZHTTPImageRequestOperation *requestOperation = [FRZImageFetchOperation requestOperationForURL:_URL];
        if (requestOperation == nil) {
            requestOperation = [[FRZHTTPImageRequestOperation alloc] initWithURL:_URL cacheEntry:cacheEntry];
            [[FRZImageFetchOperation requestQueue] addOperation:requestOperation];
        }

        NSOperation *completionOperation = [NSBlockOperation blockOperationWithBlock:^{
            if (requestOperation.response.statusCode == 304) {
                _result = FRZImageFetchOperationResultFromCacheRevalidated;
            } else if (requestOperation.image) {
                _result = FRZImageFetchOperationResultFromNetwork;
            } else if (requestOperation.response) {
                _result = FRZImageFetchOperationResultInvalidURL;
            }

            UIImage *image = requestOperation.image;
            if (image && _result == FRZImageFetchOperationResultFromNetwork && [self.delegate respondsToSelector:@selector(imageFetchOperation:transformImage:)]) {
                image = [self.delegate imageFetchOperation:self transformImage:image];
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
        }
        [self finish];
    }
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
