//
//  Constants.h
//  Strongbox
//
//  Created by Strongbox on 22/06/2020.
//  Copyright © 2014-2021 Mark McGuill. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Constants : NSObject

extern const NSInteger kStorageProviderSFTPorWebDAVSecretMissingErrorCode;
extern const NSInteger kStorageProviderUserInteractionRequiredErrorCode;
extern NSString* const kStorageProviderUserInteractionRequiredErrorMessage;
extern const NSError* kUserInteractionRequiredError;
extern const NSUInteger kMinimumDatabasePrefixLengthForValidation;
extern const NSUInteger kStreamingSerializationChunkSize;
extern const size_t kMaxAttachmentTableviewIconImageSize;
extern NSString* const kDefaultKeePassEmailFieldKey;

@property (readonly, class) NSString* proEditionBundleId;
@property (readonly, class) NSString* scotusEditionBundleId;
@property (readonly, class) NSString* grapheneEditionBundleId;

@end

NS_ASSUME_NONNULL_END
