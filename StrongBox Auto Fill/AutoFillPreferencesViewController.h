//
//  AutoFillPreferencesViewController.h
//  Strongbox
//
//  Created by Strongbox on 17/08/2020.
//  Copyright © 2014-2021 Mark McGuill. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Model.h"
#import "StaticDataTableViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface AutoFillPreferencesViewController : StaticDataTableViewController

@property Model* viewModel;

@end

NS_ASSUME_NONNULL_END
