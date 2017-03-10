//
//  FRZHTTPImageRequestOperation.h
//  Forza Football
//
//  Created by Joel Ekström on 2017-03-06.
//  Copyright © 2017 FootballAddicts. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FRZAsynchronousOperation.h"
#import "FRZImageCacheEntry.h"

@interface FRZHTTPImageRequestOperation : FRZAsynchronousOperation

- (nullable instancetype)initWithURL:(nonnull NSURL *)URL cacheEntry:(nullable FRZImageCacheEntry *)cacheEntry;

@property (nonatomic, readonly, nonnull) NSURL *URL;
@property (nonatomic, readonly, nullable) UIImage *image;
@property (nonatomic, readonly, nullable) NSHTTPURLResponse *response;
@property (nonatomic, readonly, nullable) NSError *error;

@end
