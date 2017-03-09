//
//  FRZAsynchronousOperation.m
//  Forza Football
//
//  Created by Joel Ekström on 2017-03-09.
//  Copyright © 2017 FootballAddicts. All rights reserved.
//

#import "FRZAsynchronousOperation.h"

@interface FRZAsynchronousOperation() {
    BOOL _isExecuting;
    BOOL _isFinished;
}

@end

@implementation FRZAsynchronousOperation

- (BOOL)isAsynchronous
{
    return YES;
}

- (void)start
{
    if ([self isCancelled]) {
        [self finish];
    } else {
        [self willChangeValueForKey:@"isExecuting"];
        _isExecuting = YES;
        [self didChangeValueForKey:@"isExecuting"];
    }
}

- (void)finish
{
    if ([self isExecuting]) {
        [self willChangeValueForKey:@"isExecuting"];
        _isExecuting = NO;
        [self didChangeValueForKey:@"isExecuting"];
    }

    if (![self isFinished]) {
        [self willChangeValueForKey:@"isFinished"];
        _isFinished = YES;
        [self didChangeValueForKey:@"isFinished"];
    }
}

- (BOOL)isExecuting
{
    return _isExecuting;
}

- (BOOL)isFinished
{
    return _isFinished;
}



@end
