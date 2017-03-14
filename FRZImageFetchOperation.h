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

NS_ASSUME_NONNULL_BEGIN

@interface FRZImageFetchOperation : FRZAsynchronousOperation

- (instancetype)initWithURL:(NSURL *)URL;

@property (nonatomic, readonly, nullable) UIImage *image;
@property (nonatomic, readonly) FRZImageFetchOperationResult result;

/**
 A block that can be used to transform/apply filters to an image before it is
 stored in the cache.

 @note If you create multiple fetch operations for this URL at the same time, the
 transform block of the last one to finish will determine the cached result.
 */
@property (nonatomic, copy, nullable) UIImage *(^transformBlock)(UIImage *originalImage);

/**
 A completion block that will be run on the main thread. This block will overwrite
 the completionBlock of the NSOperation base class.
 */
@property (nonatomic, copy, nullable) void (^mainThreadCompletionBlock)(UIImage *image, FRZImageFetchOperationResult result);

@property (class, nonatomic, readonly) NSOperationQueue *imageFetchQueue;

@end

NS_ASSUME_NONNULL_END
