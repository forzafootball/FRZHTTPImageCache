//
//  FRZHTTPImageCacheLogger.m
//  Forza Football
//
//  Created by Joel Ekström on 2017-03-13.
//  Copyright © 2017 FootballAddicts. All rights reserved.
//

#import "FRZHTTPImageCacheLogger.h"

@implementation FRZHTTPImageCacheLogger

- (void)frz_logMessage:(NSString *)message forImageURL:(nonnull NSURL *)URL logLevel:(FRZHTTPImageCacheLogLevel)logLevel
{
    if (self.loggingBlock) {
        self.loggingBlock(message, URL, logLevel);
    }
}

static id<FRZHTTPImageCacheLogging> _sharedLogger = nil;

+ (id<FRZHTTPImageCacheLogging>)sharedLogger
{
    return _sharedLogger;
}

+ (void)setSharedLogger:(id<FRZHTTPImageCacheLogging>)sharedLogger
{
    _sharedLogger = sharedLogger;
}

@end
