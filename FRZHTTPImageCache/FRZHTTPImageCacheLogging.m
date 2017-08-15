//
//  FRZHTTPImageCacheLogger.m
//  Forza Football
//
//  Created by Joel Ekström on 2017-03-13.
//  Copyright © 2017 FootballAddicts. All rights reserved.
//

#import "FRZHTTPImageCacheLogging.h"

@interface FRZHTTPImageCacheBasicLogger()

@property (nonatomic, copy, nullable) void (^loggingBlock)(NSString *message, NSURL *URL, FRZHTTPImageCacheLogLevel logLevel);

@end

@implementation FRZHTTPImageCacheBasicLogger

+ (instancetype)loggerWithLoggingBlock:(void (^)(NSString * _Nonnull, NSURL * _Nonnull, FRZHTTPImageCacheLogLevel))loggingBlock
{
    FRZHTTPImageCacheBasicLogger *logger = [self new];
    logger.loggingBlock = loggingBlock;
    return logger;
}

- (void)frz_logMessage:(NSString *)message forImageURL:(nonnull NSURL *)URL logLevel:(FRZHTTPImageCacheLogLevel)logLevel
{
    self.loggingBlock(message, URL, logLevel);
}

@end
