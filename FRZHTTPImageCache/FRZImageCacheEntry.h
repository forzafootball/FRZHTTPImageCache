//
//  FRZImageCacheEntry.h
//  Forza Football
//
//  Created by Joel Ekström on 2017-03-03.
//  Copyright © 2017 FootballAddicts. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@import UIKit;

@interface FRZImageCacheEntry : NSObject <NSSecureCoding>

@property (nonatomic, readonly, nullable) NSDate *expirationDate;
@property (nonatomic, readonly) NSHTTPURLResponse *originalResponse;
@property (nonatomic, readonly, nullable) UIImage *image;
@property (nonatomic, readonly) BOOL needsRevalidation;

- (nullable instancetype)initWithImage:(nullable UIImage *)image response:(NSHTTPURLResponse *)response;

@end

NS_ASSUME_NONNULL_END
