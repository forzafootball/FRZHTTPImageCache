//
//  FZFImageRequestOperation.h
//  Forza Football
//
//  Created by Joel Ekström on 2017-03-03.
//  Copyright © 2017 FootballAddicts. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FRZAsynchronousOperation.h"

typedef NS_ENUM(NSInteger, FRZImageFetchOperationResult) {
    FRZImageFetchOperationResultFromCache,
    FRZImageFetchOperationResultFromCacheRevalidated,
    FRZImageFetchOperationResultFromNetwork,
    FRZImageFetchOperationResultInvalidURL
};

@class FRZImageFetchOperation;
@protocol FRZImageFetchOperationDelegate <NSObject>

/**
 This method is called when an image is downloaded from the network, and before
 it is stored in the cache. Allows you to edit the image before it is cached.

 @note If you create multiple fetch operations for this URL at the same time, the
 transform block of the last one to finish will determine the cached result.
 */
- (UIImage *)imageFetchOperation:(FRZImageFetchOperation *)operation transformImage:(UIImage *)image;

@end

@interface FRZImageFetchOperation : FRZAsynchronousOperation

- (instancetype)initWithURL:(NSURL *)URL;

@property (nonatomic, readonly) UIImage *image;
@property (nonatomic, readonly) FRZImageFetchOperationResult result;
@property (nonatomic, weak) id<FRZImageFetchOperationDelegate> delegate;

- (void)setMainThreadCompletionBlock:(void (^)(UIImage *image, FRZImageFetchOperationResult result))completionBlock;

+ (NSOperationQueue *)imageFetchQueue;

@end
