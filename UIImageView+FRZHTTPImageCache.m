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

/**
 An NSOperation that updates an image view after its image has been fetched.
 This is used so you can cancel an update operation for an image view when
 the image view is reused, to get it ready for another image.
 */
@interface UpdateImageOperation : NSOperation

@property (nonatomic, strong) FRZImageFetchOperation *fetchOperation;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, assign) BOOL animated;

@end

@interface UIImageView (FRZHTTPImageCacheInternal) <FRZImageFetchOperationDelegate>

@property (nonatomic, strong) UpdateImageOperation *updateImageOperation;
@property (nonatomic, copy) UIImage *(^transformBlock)(UIImage *);

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
    [self.updateImageOperation cancel];
    self.image = placeholderImage;

    FRZImageFetchOperation *fetchOperation = [[FRZImageFetchOperation alloc] initWithURL:URL];

    if (transformBlock) {
        self.transformBlock = transformBlock;
        fetchOperation.delegate = self;
    }

    [[NSOperationQueue mainQueue] addOperation:fetchOperation];

    UpdateImageOperation *updateOperation = [[UpdateImageOperation alloc] init];
    updateOperation.imageView = self;
    updateOperation.fetchOperation = fetchOperation;
    updateOperation.animated = animated;
    [updateOperation addDependency:fetchOperation];
    [[NSOperationQueue mainQueue] addOperation:updateOperation];
    self.updateImageOperation = updateOperation;

    if (completion) {
        NSOperation *completionOperation = [NSBlockOperation blockOperationWithBlock:^{
            completion(fetchOperation.result);
        }];
        [completionOperation addDependency:updateOperation];
        [[NSOperationQueue mainQueue] addOperation:completionOperation];
    }
}

@end

@implementation UIImageView (FRZHTTPImageCacheInternal)

- (UIImage *)imageFetchOperation:(FRZImageFetchOperation *)operation transformImage:(UIImage *)image
{
    if (self.transformBlock) {
        return self.transformBlock(image);
    }
    return image;
}

- (void)setUpdateImageOperation:(UpdateImageOperation *)updateImageOperation
{
    objc_setAssociatedObject(self, @selector(updateImageOperation), updateImageOperation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UpdateImageOperation *)updateImageOperation
{
    return objc_getAssociatedObject(self, @selector(updateImageOperation));
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

@implementation UpdateImageOperation

- (void)main
{
    if (self.isCancelled) {
        return;
    }

    self.imageView.updateImageOperation = nil;
    self.imageView.transformBlock = nil;
    UIImage *image = self.fetchOperation.image;
    if (image) {
        self.imageView.image = image;
        if (self.animated && self.fetchOperation.result != FRZImageFetchOperationResultFromCache) {
            [UIView transitionWithView:self.imageView duration:0.3 options:UIViewAnimationOptionTransitionCrossDissolve animations:nil completion:nil];
        }
    }
}

@end
