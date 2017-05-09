//
//  FRZAsynchronousOperation.h
//  Forza Football
//
//  Created by Joel Ekström on 2017-03-09.
//  Copyright © 2017 FootballAddicts. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 An "abstract" class that contains boilerplate for async NSOperations
 */
@interface FRZAsynchronousOperation : NSOperation

- (void)start;
- (void)finish;

@end
