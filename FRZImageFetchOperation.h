//
//  FZFImageRequestOperation.h
//  Forza Football
//
//  Created by Joel Ekström on 2017-03-03.
//  Copyright © 2017 FootballAddicts. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FRZAsynchronousOperation.h"

@interface FRZImageFetchOperation : FRZAsynchronousOperation

- (instancetype)initWithURL:(NSURL *)URL;

@property (nonatomic, readonly) UIImage *image;

@end
