//
//  FRZHTTPImageRequestOperation.h
//  Forza Football
//
//  Created by Joel Ekström on 2017-03-06.
//  Copyright © 2017 FootballAddicts. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FRZAsynchronousOperation.h"
#import "FRZCachedImage.h"

@interface FRZHTTPImageRequestOperation : FRZAsynchronousOperation

- (nullable instancetype)initWithURL:(nonnull NSURL *)URL cachedImage:(nullable FRZCachedImage *)cachedImage;

@property (nonatomic, readonly, nullable) UIImage *image;
@property (nonatomic, readonly, nullable) NSHTTPURLResponse *response;
@property (nonatomic, readonly, nullable) NSError *error;

@end
