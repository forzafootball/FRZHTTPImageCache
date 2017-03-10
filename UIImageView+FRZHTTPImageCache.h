//
//  UIImageView+FRZHTTPImageCache.h
//  Forza Football
//
//  Created by Joel Ekström on 2017-03-10.
//  Copyright © 2017 FootballAddicts. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImageView (FRZHTTPImageCache)

- (void)frz_setImageWithURL:(NSURL *)URL placeholderImage:(UIImage *)placeholderImage animated:(BOOL)animated;

@end
