//
//  PickCredentialsTableViewController.h
//  Strongbox AutoFill
//
//  Created by Mark on 14/10/2018.
//  Copyright © 2018 Mark McGuill. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Model.h"
#import "CredentialProviderViewController.h"
#import <DZNEmptyDataSet/UIScrollView+EmptyDataSet.h>

NS_ASSUME_NONNULL_BEGIN

@interface PickCredentialsTableViewController : UITableViewController<DZNEmptyDataSetSource, DZNEmptyDataSetDelegate>

@property (nonatomic, strong) Model *model;
@property (nonatomic, strong) CredentialProviderViewController *rootViewController;

@end

NS_ASSUME_NONNULL_END
