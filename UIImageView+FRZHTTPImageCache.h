//
//  UIImageView+FRZHTTPImageCache.h
//  Forza Football
//
//  Created by Joel Ekström on 2017-03-10.
//  Copyright © 2017 FootballAddicts. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FRZImageFetchOperation.h"

NS_ASSUME_NONNULL_BEGIN

@interface UIImageView (FRZHTTPImageCache) <FRZImageFetchOperationDelegate>

- (void)frz_setImageWithURL:(NSURL *)URL placeholderImage:(nullable UIImage *)placeholderImage animated:(BOOL)animated;
- (void)frz_setImageWithURL:(NSURL *)URL
           placeholderImage:(nullable UIImage *)placeholderImage
                  transform:(nullable UIImage *(^)(UIImage *originalImage))transformBlock
                   animated:(BOOL)animated
                 completion:(nullable void(^)(FRZImageFetchOperationResult fetchResult))completion;

@end

NS_ASSUME_NONNULL_END
