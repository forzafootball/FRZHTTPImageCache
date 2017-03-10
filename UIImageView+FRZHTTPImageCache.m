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

static void *UpdateImageOperationKey = &UpdateImageOperationKey;

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

@interface UIImageView ()

@property (nonatomic, strong) UpdateImageOperation *updateImageOperation;

@end

@implementation UIImageView (FRZHTTPImageCache)

- (void)setUpdateImageOperation:(UpdateImageOperation *)updateImageOperation
{
    objc_setAssociatedObject(self, UpdateImageOperationKey, updateImageOperation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UpdateImageOperation *)updateImageOperation
{
    return objc_getAssociatedObject(self, UpdateImageOperationKey);
}

- (void)frz_setImageWithURL:(NSURL *)URL placeholderImage:(UIImage *)placeholderImage animated:(BOOL)animated
{
    [self.updateImageOperation cancel];

    self.image = placeholderImage;
    FRZImageFetchOperation *fetchOperation = [[FRZImageFetchOperation alloc] initWithURL:URL];
    [[NSOperationQueue mainQueue] addOperation:fetchOperation];

    UpdateImageOperation *updateOperation = [[UpdateImageOperation alloc] init];
    updateOperation.imageView = self;
    updateOperation.fetchOperation = fetchOperation;
    updateOperation.animated = animated;
    [updateOperation addDependency:fetchOperation];
    [[NSOperationQueue mainQueue] addOperation:updateOperation];
    self.updateImageOperation = updateOperation;
}

@end

@implementation UpdateImageOperation

- (void)main
{
    if (self.isCancelled) {
        return;
    }

    self.imageView.updateImageOperation = nil;
    UIImage *image = self.fetchOperation.image;
    if (image) {
        self.imageView.image = image;
        if (self.animated && self.fetchOperation.result != FRZImageFetchOperationResultFromCache) {
            [UIView transitionWithView:self.imageView duration:0.3 options:UIViewAnimationOptionTransitionCrossDissolve animations:nil completion:nil];
        }
    }
}

@end
