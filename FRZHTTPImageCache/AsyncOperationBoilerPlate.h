//
//  AsyncOperationBoilerPlate.h
//  FRZHTTPImageCache
//
//  Created by Joel Ekström on 2017-12-20.
//  Copyright © 2017 Football Addicts AB. All rights reserved.
//

- (BOOL)isAsynchronous
{
    return YES;
}

- (void)setExecuting:(BOOL)executing
{
    [self willChangeValueForKey:@"isExecuting"];
    _isExecuting = executing;
    [self didChangeValueForKey:@"isExecuting"];
}

- (void)setFinished:(BOOL)finished
{
    [self willChangeValueForKey:@"isFinished"];
    _isFinished = finished;
    [self didChangeValueForKey:@"isFinished"];
}

- (BOOL)isExecuting
{
    return _isExecuting;
}

- (BOOL)isFinished
{
    return _isFinished;
}

- (void)finish
{
    if ([self isExecuting]) {
        [self setExecuting:NO];
    }

    if (![self isFinished]) {
        [self setFinished:YES];
    }
}
