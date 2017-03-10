//
//  FRZHTTPImageRequestOperation.m
//  Forza Football
//
//  Created by Joel Ekström on 2017-03-06.
//  Copyright © 2017 FootballAddicts. All rights reserved.
//

#import "FRZHTTPImageRequestOperation.h"

@interface FRZHTTPImageRequestOperation()

@property (nonatomic, strong) NSURL *URL;
@property (nonatomic, strong) FRZImageCacheEntry *cacheEntry;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) NSHTTPURLResponse *response;
@property (nonatomic, strong) NSError *error;

@end

@implementation FRZHTTPImageRequestOperation

- (nullable instancetype)initWithURL:(nonnull NSURL *)URL cacheEntry:(nullable FRZImageCacheEntry *)cacheEntry;
{
    if (!URL) {
        return nil;
    }

    if (self = [super init]) {
        self.URL = URL;
        self.cacheEntry = cacheEntry;
    }
    return self;
}

- (void)start
{
    [super start];
    if (self.isCancelled) {
        return;
    }

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:_URL];

    //  Add If-Modified-Since and If-None-Match headers if we already have a cached image
    if (_cacheEntry) {
        NSDictionary *cachedHeaders = [_cacheEntry.originalResponse allHeaderFields];
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

        NSIndexSet *validStatuses = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 99)];
        if (HTTPResponse.statusCode == 304) {
            _image = _cacheEntry.image;
        } else if ([validStatuses containsIndex:HTTPResponse.statusCode]) {
            if ([validStatuses containsIndex:HTTPResponse.statusCode]) {
                CGFloat scale = 1.0;
                NSString *URLString = self.URL.absoluteString;
                if ([URLString containsString:@"@2x."]) {
                    scale = 2.0;
                } else if ([URLString containsString:@"@3x."]) {
                    scale = 3.0;
                }

                self.image = [UIImage imageWithData:data scale:scale];
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
