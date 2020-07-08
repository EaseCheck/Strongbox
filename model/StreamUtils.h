//
//  StreamUtils.h
//  Strongbox
//
//  Created by Strongbox on 29/06/2020.
//  Copyright © 2020 Mark McGuill. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface StreamUtils : NSObject

+ (BOOL)pipeFromStream:(NSInputStream*)inputStream to:(NSOutputStream*)outputStream;

@end

NS_ASSUME_NONNULL_END
