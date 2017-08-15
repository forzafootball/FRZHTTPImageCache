//
//  FRZHTTPImageCacheLogging.h
//  Forza Football
//
//  Created by Joel Ekström on 2017-03-13.
//  Copyright © 2017 FootballAddicts. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, FRZHTTPImageCacheLogLevel) {
    FRZHTTPImageCacheLogLevelVerbose,
    FRZHTTPImageCacheLogLevelWarning,
    FRZHTTPImageCacheLogLevelError
};

NS_ASSUME_NONNULL_BEGIN

@protocol FRZHTTPImageCacheLogging <NSObject>

- (void)frz_logMessage:(nonnull NSString *)message forImageURL:(nonnull NSURL *)URL logLevel:(FRZHTTPImageCacheLogLevel)logLevel;

@end

@interface FRZHTTPImageCacheBasicLogger : NSObject <FRZHTTPImageCacheLogging>

+ (instancetype)loggerWithLoggingBlock:(nonnull void(^)(NSString *message, NSURL *URL, FRZHTTPImageCacheLogLevel logLevel))loggingBlock;

@end

NS_ASSUME_NONNULL_END
