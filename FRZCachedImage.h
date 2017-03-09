//
//  FRZCachedImage.h
//  Forza Football
//
//  Created by Joel Ekström on 2017-03-03.
//  Copyright © 2017 FootballAddicts. All rights reserved.
//

#import <Foundation/Foundation.h>

#warning make NSDiscardableContent?
@interface FRZCachedImage : NSObject <NSSecureCoding>

@property (nonatomic, readonly) NSDate *expirationDate;
@property (nonatomic, readonly) NSHTTPURLResponse *originalResponse;
@property (nonatomic, readonly) UIImage *image;

@property (nonatomic, readonly) BOOL needsRevalidation;

- (instancetype)initWithImage:(UIImage *)image response:(NSHTTPURLResponse *)response;

@end
