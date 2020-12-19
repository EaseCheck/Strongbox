//
//  ShowMergeDiffTableViewController.h
//  Strongbox
//
//  Created by Mark on 14/12/2020.
//  Copyright © 2020 Mark McGuill. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Model.h"

NS_ASSUME_NONNULL_BEGIN

@interface ShowMergeDiffTableViewController : UITableViewController

@property Model* firstDatabase;
@property Model* secondDatabase;

@property (nonatomic, copy) void (^onDone)(BOOL userCancelled);

@end

NS_ASSUME_NONNULL_END
