//
//  UIImageView+FRZHTTPImageCache.h
//  Forza Football
//
//  Created by Joel Ekström on 2017-03-10.
//  Copyright © 2017 FootballAddicts. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FRZImageFetchOperation.h"

@interface UIImageView (FRZHTTPImageCache)

- (void)frz_setImageWithURL:(NSURL *)URL placeholderImage:(UIImage *)placeholderImage animated:(BOOL)animated;
- (void)frz_setImageWithURL:(NSURL *)URL
           placeholderImage:(UIImage *)placeholderImage
                  transform:(UIImage *(^)(UIImage *originalImage))transformBlock
                   animated:(BOOL)animated
                 completion:(void(^)(FRZImageFetchOperationResult fetchResult))completion;

@end
