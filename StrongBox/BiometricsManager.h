//
//  BiometricsManager.h
//  Strongbox
//
//  Created by Mark on 24/10/2019.
//  Copyright © 2019 Mark McGuill. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BiometricsManager : NSObject

+ (instancetype)sharedInstance;

+ (BOOL)isBiometricIdAvailable;

- (BOOL)requestBiometricId:(NSString*)reason
                completion:(void(^)(BOOL success, NSError * __nullable error))completion;

- (BOOL)requestBiometricId:(NSString *)reason
             fallbackTitle:(NSString*_Nullable)fallbackTitle
                completion:(void(^_Nullable)(BOOL success, NSError * __nullable error))completion;

- (NSString*)getBiometricIdName;

@end

NS_ASSUME_NONNULL_END
