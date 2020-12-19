//
//  OpenSafeSequenceHelper.h
//  Strongbox-iOS
//
//  Created by Mark on 12/10/2018.
//  Copyright © 2018 Mark McGuill. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SafeMetaData.h"
#import "Model.h"

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    kUnlockDatabaseResultError,
    kUnlockDatabaseResultUserCancelled,
    kUnlockDatabaseResultSuccess,
    kUnlockDatabaseResultViewDebugSyncLogRequested,
} UnlockDatabaseResult;

typedef void(^UnlockDatabaseCompletionBlock)(UnlockDatabaseResult result, Model*_Nullable model, NSError*_Nullable error);

@interface OpenSafeSequenceHelper : NSObject

- (instancetype)init NS_UNAVAILABLE;





+ (void)beginSequenceWithViewController:(UIViewController*)viewController
                                   safe:(SafeMetaData*)safe
                    canConvenienceEnrol:(BOOL)canConvenienceEnrol
                         isAutoFillOpen:(BOOL)isAutoFillOpen
                          openLocalOnly:(BOOL)openLocalOnly
                             completion:(UnlockDatabaseCompletionBlock)completion;

+ (void)beginSequenceWithViewController:(UIViewController*)viewController
                                   safe:(SafeMetaData*)safe
                    canConvenienceEnrol:(BOOL)canConvenienceEnrol
                         isAutoFillOpen:(BOOL)isAutoFillOpen
                          openLocalOnly:(BOOL)openLocalOnly
            biometricAuthenticationDone:(BOOL)biometricAuthenticationDone
                             completion:(UnlockDatabaseCompletionBlock)completion;

+ (void)beginSequenceWithViewController:(UIViewController*)viewController
                                   safe:(SafeMetaData*)safe
                    canConvenienceEnrol:(BOOL)canConvenienceEnrol
                         isAutoFillOpen:(BOOL)isAutoFillOpen
                          openLocalOnly:(BOOL)openLocalOnly
            biometricAuthenticationDone:(BOOL)biometricAuthenticationDone
                    noConvenienceUnlock:(BOOL)noConvenienceUnlock
                        allowOnboarding:(BOOL)allowOnboarding
                             completion:(UnlockDatabaseCompletionBlock)completion;


+ (void)beginSequenceWithViewController:(UIViewController*)viewController
                                   safe:(SafeMetaData*)safe
                    canConvenienceEnrol:(BOOL)canConvenienceEnrol
                         isAutoFillOpen:(BOOL)isAutoFillOpen
                isAutoFillQuickTypeOpen:(BOOL)isAutoFillQuickTypeOpen
                          openLocalOnly:(BOOL)openLocalOnly
            biometricAuthenticationDone:(BOOL)biometricAuthenticationDone
                    noConvenienceUnlock:(BOOL)noConvenienceUnlock
                        allowOnboarding:(BOOL)allowOnboarding
                             completion:(UnlockDatabaseCompletionBlock)completion;

@end

NS_ASSUME_NONNULL_END
