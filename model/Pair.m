//
//  Pair.m
//  Strongbox
//
//  Created by Strongbox on 15/12/2020.
//  Copyright © 2014-2021 Mark McGuill. All rights reserved.
//

#import "Pair.h"

@implementation Pair

+ (instancetype)pairOfA:(id)a andB:(id)b {
    return [[Pair alloc] initPairOfA:a andB:b];
}

- (instancetype)initPairOfA:(id)a andB:(id)b {
    self = [super init];
    if (self) {
        _a = a;
        _b = b;
    }
    return self;
}

@end
