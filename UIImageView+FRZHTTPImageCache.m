//
//  UIImageView+FRZHTTPImageCache.m
//  Forza Football
//
//  Created by Joel Ekström on 2017-03-10.
//  Copyright © 2017 FootballAddicts. All rights reserved.
//

#import "UIImageView+FRZHTTPImageCache.h"
#import "FRZImageFetchOperation.h"
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

    FRZImageFetchOperation *fetchOperation = [[FRZImageFetchOperation alloc] initWithURL:URL];
    self.currentFetchOperation = fetchOperation;
    fetchOperation.transformBlock = transformBlock;
    NSDate *timestamp = [NSDate date];

    __weak FRZImageFetchOperation *weakFetchOperation = fetchOperation;
    [fetchOperation setCompletionBlock:^{
        if (self.currentFetchOperation != weakFetchOperation) {
            return;
        }

        UIImage *image = weakFetchOperation.image;
        FRZImageFetchOperationResult result = weakFetchOperation.result;
        self.currentFetchOperation = nil;

        dispatch_async(dispatch_get_main_queue(), ^{
            if (image) {
                self.image = image;
                if (completion) {
                    completion(result);
                }

                // Only perform animation if it took more than 0.1 seconds to fetch the image. This makes it
                // animate slow loading images regardless if they come from the cache or the network.
                if (animated && [[NSDate date] timeIntervalSinceDate:timestamp] > 0.1) {
                    [UIView transitionWithView:self duration:0.3 options:UIViewAnimationOptionTransitionCrossDissolve animations:nil completion:nil];
                }
            }
        });
    }];

    [[FRZImageFetchOperation imageFetchQueue] addOperation:fetchOperation];
}

@end

@implementation UIImageView (FRZHTTPImageCacheInternal)

- (void)setCurrentFetchOperation:(FRZImageFetchOperation *)currentFetchOperation
{
    objc_setAssociatedObject(self, @selector(currentFetchOperation), currentFetchOperation, OBJC_ASSOCIATION_ASSIGN);
}

- (FRZImageFetchOperation *)currentFetchOperation
{
    return objc_getAssociatedObject(self, @selector(currentFetchOperation));
}

- (void)setTransformBlock:(UIImage *(^)(UIImage *))transformBlock
{
    objc_setAssociatedObject(self, @selector(transformBlock), transformBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (UIImage *(^)(UIImage *))transformBlock
{
    return objc_getAssociatedObject(self, @selector(transformBlock));
}

@end
