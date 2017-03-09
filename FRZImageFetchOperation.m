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
    BOOL _isExecuting;
    BOOL _isFinished;
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
    FRZCachedImage *cachedImage = [[FRZImageCacheManager sharedInstance] cachedImageForURL:_URL];

    if (cachedImage == nil || cachedImage.needsRevalidation) {
        FRZHTTPImageRequestOperation *requestOperation = [[FRZHTTPImageRequestOperation alloc] initWithURL:_URL cachedImage:cachedImage];
        NSOperation *completionOperation = [NSBlockOperation blockOperationWithBlock:^{
            self.image = requestOperation.image;

            // Store the new (or already cached, but with updated expirationDate) image in the cache
            FRZCachedImage *cachedImage = [[FRZCachedImage alloc] initWithImage:requestOperation.image
                                                                       response:requestOperation.response];
            if (cachedImage) {
                [[FRZImageCacheManager sharedInstance] cacheImage:cachedImage];
            }

            [self finish];
        }];
        [completionOperation addDependency:requestOperation];
        [[FRZImageFetchOperation requestQueue] addOperations:@[requestOperation, completionOperation] waitUntilFinished:NO];
    } else {
        self.image = cachedImage.image;
        [self finish];
    }
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

@end
