//
//  GzipDecompressOutputStream.h
//  Strongbox
//
//  Created by Strongbox on 26/06/2020.
//  Copyright © 2020 Mark McGuill. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface GzipDecompressOutputStream : NSOutputStream

- (instancetype)initToOutputStream:(NSOutputStream*)outputStream;

@end

NS_ASSUME_NONNULL_END
