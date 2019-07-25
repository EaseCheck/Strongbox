//
//  SafeStorageProvider.h
//  StrongBox
//
//  Created by Mark on 19/11/2014.
//  Copyright (c) 2014 Mark McGuill. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "SafeMetaData.h"
#import "StorageBrowserItem.h"

NS_ASSUME_NONNULL_BEGIN

@protocol SafeStorageProvider <NSObject>

@property (strong, nonatomic, readonly) NSString *displayName;
@property (strong, nonatomic, readonly) NSString *icon;
@property (nonatomic, readonly) StorageProvider storageId;
@property (nonatomic, readonly) BOOL allowOfflineCache;
@property (nonatomic, readonly) BOOL providesIcons;
@property (nonatomic, readonly) BOOL browsableNew;
@property (nonatomic, readonly) BOOL browsableExisting;
@property (nonatomic, readonly) BOOL rootFolderOnly;

- (void)    create:(NSString *)nickName
         extension:(NSString *)extension
              data:(NSData *)data
      parentFolder:(NSObject * _Nullable)parentFolder
    viewController:(UIViewController *_Nullable)viewController
        completion:(void (^)(SafeMetaData *metadata, NSError *error))completion;

- (void)      read:(SafeMetaData *)safeMetaData
    viewController:(UIViewController *)viewController
        completion:(void (^)(NSData *data, NSError *error))completion;

- (void)update:(SafeMetaData *)safeMetaData
          data:(NSData *)data
    completion:(void (^)(NSError *error))completion;

- (void)delete:(SafeMetaData*)safeMetaData completion:(void (^)(NSError *_Nullable error))completion;

- (void)      list:(NSObject *)parentFolder
    viewController:(UIViewController *)viewController
        completion:(void (^)(BOOL userCancelled, NSArray<StorageBrowserItem *> *items, NSError *error))completion;

- (void)readWithProviderData:(NSObject * _Nullable)providerData
              viewController:(UIViewController *)viewController
                  completion:(void (^)(NSData *data, NSError *error))completionHandler;

- (void)loadIcon:(NSObject *)providerData viewController:(UIViewController *)viewController
      completion:(void (^)(UIImage *image))completionHandler;

- (SafeMetaData *_Nullable)getSafeMetaData:(NSString *)nickName providerData:(NSObject *)providerData;

@end

NS_ASSUME_NONNULL_END
