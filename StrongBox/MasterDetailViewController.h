//
//  MasterDetailViewController.h
//  Strongbox-iOS
//
//  Created by Mark on 04/06/2019.
//  Copyright © 2019 Mark McGuill. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Model.h"

NS_ASSUME_NONNULL_BEGIN

@interface MasterDetailViewController : UISplitViewController

@property (nonatomic, strong, nonnull) Model *viewModel;

- (void)onClose;

@end

NS_ASSUME_NONNULL_END
