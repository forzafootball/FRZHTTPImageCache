//
//  FZFCachedImage.m
//  Forza Football
//
//  Created by Joel Ekström on 2017-03-03.
//  Copyright © 2017 FootballAddicts. All rights reserved.
//

#import "FRZImageCacheEntry.h"

@interface FRZImageCacheEntry()

@property (nonatomic, strong) NSHTTPURLResponse *originalResponse;
@property (nonatomic, strong) NSDate *expirationDate;
@property (nonatomic, strong) UIImage *image;

@end

@implementation FRZImageCacheEntry

- (instancetype)initWithImage:(UIImage *)image response:(NSHTTPURLResponse *)response
{
    if (self = [super init]) {
        self.originalResponse = response;
        self.image = image;

        static NSDateFormatter *dateFormatter = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            dateFormatter.dateFormat = @"EEE',' dd' 'MMM' 'yyyy HH':'mm':'ss zzz";
            dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
        });

        NSDictionary *headers = response.allHeaderFields;
        NSString *cacheControl = headers[@"Cache-Control"];

        // Should we cache this at all?
        if ([cacheControl containsString:@"no-store"]) {
            return nil;
        }

        // Calculate an eventual expiration date for the cache. After this date, the image should be requested
        // again if found in the cache. Prioritize max-age, and if that doesn't exist, use the Expires-header
        if (cacheControl) {
            NSRange maxAgeRange = [cacheControl rangeOfString:@"max-age=\\d+" options:NSRegularExpressionSearch];
            if (maxAgeRange.location != NSNotFound) {
                NSString *maxAgeString = [cacheControl substringWithRange:maxAgeRange];
                NSTimeInterval maxAge = [[maxAgeString stringByReplacingOccurrencesOfString:@"max-age=" withString:@""] doubleValue];
                self.expirationDate = [[NSDate date] dateByAddingTimeInterval:maxAge];
            }
        } else if (headers[@"Expires"]) {
            self.expirationDate = [dateFormatter dateFromString:headers[@"Expires"]];
        }
    }
    return self;
}

- (BOOL)needsRevalidation
{
    return self.image && (self.expirationDate == nil || [[NSDate date] timeIntervalSinceDate:self.expirationDate] > 0);
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        self.expirationDate = [aDecoder decodeObjectOfClass:[NSDate class] forKey:NSStringFromSelector(@selector(expirationDate))];
        self.originalResponse = [aDecoder decodeObjectOfClass:[NSHTTPURLResponse class] forKey:NSStringFromSelector(@selector(originalResponse))];
        self.image = [aDecoder decodeObjectOfClass:[UIImage class] forKey:NSStringFromSelector(@selector(image))];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.expirationDate forKey:NSStringFromSelector(@selector(expirationDate))];
    [aCoder encodeObject:self.originalResponse forKey:NSStringFromSelector(@selector(originalResponse))];
    [aCoder encodeObject:self.image forKey:NSStringFromSelector(@selector(image))];
}

@end
