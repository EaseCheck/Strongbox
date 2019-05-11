//
//  WebDAVConfigurationViewController.h
//  Strongbox
//
//  Created by Mark on 12/12/2018.
//  Copyright © 2018 Mark McGuill. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WebDAVSessionConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@interface WebDAVConfigurationViewController : UIViewController

@property (nonatomic, copy) void (^onDone)(BOOL success);
@property (nullable) WebDAVSessionConfiguration* configuration;

@end

NS_ASSUME_NONNULL_END
