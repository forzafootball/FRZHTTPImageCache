//
//  FRZHTTPImageCacheLogger.h
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

@interface FRZHTTPImageCacheLogger : NSObject <FRZHTTPImageCacheLogging>

@property (nullable, class, nonatomic, strong) id<FRZHTTPImageCacheLogging> sharedLogger;

@property (nonatomic, copy, nullable) void (^loggingBlock)(NSString *message, NSURL *URL, FRZHTTPImageCacheLogLevel logLevel);

@end

NS_ASSUME_NONNULL_END
