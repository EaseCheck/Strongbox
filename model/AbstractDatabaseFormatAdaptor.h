//
//  AbstractPasswordDatabase.h
//  Strongbox
//
//  Created by Mark on 07/11/2017.
//  Copyright © 2017 Mark McGuill. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Node.h"
#import "AbstractDatabaseMetadata.h"
#import "DatabaseAttachment.h"
#import "StrongboxDatabase.h"

NS_ASSUME_NONNULL_BEGIN

typedef enum {
    kPasswordSafe,
    kKeePass,
    kKeePass4,
    kKeePass1,
    kFormatUnknown,
} DatabaseFormat;

@protocol AbstractDatabaseFormatAdaptor <NSObject>

+ (BOOL)isAValidSafe:(nullable NSData *)candidate error:(NSError**)error;
+ (NSString *)fileExtension;

- (StrongboxDatabase*)create:(nullable NSString *)password;
- (StrongboxDatabase*)create:(nullable NSString *)password keyFileDigest:(nullable NSData*)keyFileDigest;
- (nullable StrongboxDatabase*)open:(NSData*)data password:(NSString *)password error:(NSError **)error;
- (nullable StrongboxDatabase*)open:(NSData*)data password:(nullable NSString *)password keyFileDigest:(nullable NSData *)keyFileDigest error:(NSError **)error;
- (nullable NSData*)save:(StrongboxDatabase*)database error:(NSError**)error;

@property (nonatomic, readonly) DatabaseFormat format;
@property (nonatomic, readonly) NSString* fileExtension;

@end

NS_ASSUME_NONNULL_END
