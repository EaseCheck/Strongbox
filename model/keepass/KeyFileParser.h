//
//  KeyFileParser.h
//  Strongbox
//
//  Created by Mark on 04/12/2018.
//  Copyright © 2014-2021 Mark McGuill. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface KeyFileParser : NSObject

+ (nullable NSData *)getKeyFileDigestFromFileData:(NSData *)data checkForXml:(BOOL)checkForXml;

@end

NS_ASSUME_NONNULL_END
