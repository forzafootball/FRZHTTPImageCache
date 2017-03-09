//
//  FRZHTTPImageRequestOperation.m
//  Forza Football
//
//  Created by Joel Ekström on 2017-03-06.
//  Copyright © 2017 FootballAddicts. All rights reserved.
//

#import "FRZHTTPImageRequestOperation.h"

@interface FRZHTTPImageRequestOperation() {
    BOOL _isExecuting;
    BOOL _isFinished;
}

@property (nonatomic, strong) NSURL *URL;
@property (nonatomic, strong) FRZCachedImage *cachedImage;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) NSHTTPURLResponse *response;
@property (nonatomic, strong) NSError *error;

@end

@implementation FRZHTTPImageRequestOperation

- (nullable instancetype)initWithURL:(nonnull NSURL *)URL cachedImage:(nullable FRZCachedImage *)cachedImage;
{
    if (!URL) {
        return nil;
    }

    if (self = [super init]) {
        self.URL = URL;
        self.cachedImage = cachedImage;
    }
    return self;
}

- (void)start
{
    [super start];
    if (self.isCancelled) {
        return;
    }

    [self willChangeValueForKey:@"isExecuting"];
    _isExecuting = YES;
    [self didChangeValueForKey:@"isExecuting"];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:_URL];

    // Add If-Modified-Since and If-None-Match headers if we already have a cached image
    if (_cachedImage) {
        NSDictionary *cachedHeaders = [_cachedImage.originalResponse allHeaderFields];
        if (cachedHeaders[@"Last-Modified"]) {
            [request addValue:cachedHeaders[@"Last-Modified"] forHTTPHeaderField:@"If-Modified-Since"];
        }

        if (cachedHeaders[@"Etag"]) {
            [request addValue:cachedHeaders[@"Etag"] forHTTPHeaderField:@"If-None-Match"];
        }
    }

    NSURLSessionDataTask *networkTask = [FRZHTTPImageRequestOperation.imageRequestSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSHTTPURLResponse *HTTPResponse = (NSHTTPURLResponse *)response;
        self.response = HTTPResponse;
        self.error = error;
        if (HTTPResponse.statusCode == 304) {
            _image = _cachedImage.image;
        } else if (!error) {
            NSIndexSet *validStatuses = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 99)];
            if ([validStatuses containsIndex:HTTPResponse.statusCode]) {
#warning set scale if URL contains @2x, @3x and so on? Let clients handle it?
                self.image = [UIImage imageWithData:data scale:1.0];
            }
        }
        [self finish];
    }];
    [networkTask resume];
}

#pragma mark - NSURLSession

+ (NSURLSession *)imageRequestSession
{
    static NSURLSession *session = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        configuration.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        session = [NSURLSession sessionWithConfiguration:configuration];
    });
    return session;
}

@end
