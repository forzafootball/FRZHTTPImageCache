//
//  UIImageView+FRZHTTPImageCache.m
//  Forza Football
//
//  Created by Joel Ekström on 2017-03-10.
//  Copyright © 2017 FootballAddicts. All rights reserved.
//

#import "UIImageView+FRZHTTPImageCache.h"
#import "FRZImageFetchOperation.h"
#import "FRZImageCacheManager.h"
#import <objc/runtime.h>

@interface UIImageView (FRZHTTPImageCacheInternal)

@property (nonatomic, weak) FRZImageFetchOperation *currentFetchOperation;

@end

@implementation UIImageView (FRZHTTPImageCache)

- (void)frz_setImageWithURL:(NSURL *)URL placeholderImage:(UIImage *)placeholderImage animated:(BOOL)animated
{
    [self frz_setImageWithURL:URL placeholderImage:placeholderImage transform:nil animated:animated completion:nil];
}

- (void)frz_setImageWithURL:(NSURL *)URL
           placeholderImage:(UIImage *)placeholderImage
                  transform:(UIImage *(^)(UIImage *originalImage))transformBlock
                   animated:(BOOL)animated
                 completion:(void (^)(FRZImageFetchOperationResult fetchResult))completion
{
    [self.layer removeAllAnimations];
    self.image = placeholderImage;
    self.currentFetchOperation = nil;
    if (URL == nil) {
        if (completion) {
            completion(FRZImageFetchOperationResultInvalidURL);
        }
        return;
    }
    
    FRZImageCacheEntry *memoryCacheEntry = [[FRZImageCacheManager sharedInstance] memoryCachedImageForURL:URL];
    if (memoryCacheEntry.image != nil) {
        self.image = memoryCacheEntry.image;
    }
    
    FRZImageFetchOperation *fetchOperation = [[FRZImageFetchOperation alloc] initWithURL:URL];
    self.currentFetchOperation = fetchOperation;
    fetchOperation.delegate = self;
    fetchOperation.transformBlock = transformBlock;
    CFTimeInterval timestamp = CACurrentMediaTime();

    __weak FRZImageFetchOperation *weakFetchOperation = fetchOperation;
    [fetchOperation setCompletionBlock:^{
        if (self.currentFetchOperation != weakFetchOperation) {
            return;
        }

        UIImage *image = weakFetchOperation.image;
        FRZImageFetchOperationResult result = weakFetchOperation.result;
        self.currentFetchOperation = nil;

        dispatch_async(dispatch_get_main_queue(), ^{
            // Only set the image didn't revalidate and got the same one. If we had a cached one
            // that was revalidated, it is already set via the delegate callback
            if (image && result != FRZImageFetchOperationResultFromCacheRevalidated) {
                self.image = image;

                // Only perform animation if it took more than 0.1 seconds to fetch the image. This makes it
                // animate slow loading images regardless if they come from the cache or the network.
                if (animated && CACurrentMediaTime() - timestamp > 0.1) {
                    [UIView transitionWithView:self duration:0.3 options:UIViewAnimationOptionTransitionCrossDissolve animations:nil completion:nil];
                }
            }

            if (completion) {
                completion(result);
            }
        });
    }];

    [[FRZImageFetchOperation imageFetchQueue] addOperation:fetchOperation];
}

- (void)fetchOperation:(FRZImageFetchOperation *)operation willRevalidateCachedImage:(UIImage *)cachedImage
{
    // If we have a cached image but need to revalidate it, set the cached image anyway
    // to improve speed. If the image has changed, it will animate into the new one later
    if (operation == self.currentFetchOperation) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.image = cachedImage;
        });
    }
}

@end


@implementation UIImageView (FRZHTTPImageCacheInternal)

typedef FRZImageFetchOperation *(^WeakImageFetchOperationWrapperBlock)(void);

- (void)setCurrentFetchOperation:(FRZImageFetchOperation *)currentFetchOperation
{
    __weak FRZImageFetchOperation *weakCurrentFetchOperation = currentFetchOperation;
    WeakImageFetchOperationWrapperBlock wrapperBlock = ^{
        return weakCurrentFetchOperation;
    };
    objc_setAssociatedObject(self, @selector(currentFetchOperation), wrapperBlock, OBJC_ASSOCIATION_COPY);
}

- (FRZImageFetchOperation *)currentFetchOperation
{
    WeakImageFetchOperationWrapperBlock wrapperBlock = objc_getAssociatedObject(self, @selector(currentFetchOperation));
    return wrapperBlock? wrapperBlock() : nil;
}

@end
