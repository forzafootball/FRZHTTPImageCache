//
//  FZFImageRequestOperation.h
//  Forza Football
//
//  Created by Joel Ekström on 2017-03-03.
//  Copyright © 2017 FootballAddicts. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FRZAsynchronousOperation.h"

typedef NS_ENUM(NSInteger, FRZImageFetchOperationResult) {
    FRZImageFetchOperationResultFromCache,
    FRZImageFetchOperationResultFromCacheRevalidated,
    FRZImageFetchOperationResultFromNetwork,
    FRZImageFetchOperationResultInvalidURL
};

@interface FRZImageFetchOperation : FRZAsynchronousOperation

- (instancetype)initWithURL:(NSURL *)URL;

@property (nonatomic, readonly) UIImage *image;
@property (nonatomic, readonly) FRZImageFetchOperationResult result;

@end
