//
//  QuickLaunchViewController.h
//  Strongbox-iOS
//
//  Created by Mark on 06/10/2018.
//  Copyright © 2018 Mark McGuill. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface QuickLaunchViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *labelSafeName;
@property (weak, nonatomic) IBOutlet UIImageView *imageViewLogo;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *buttonUpgrade;

- (void)openPrimarySafe:(BOOL)userJustCompletedBiometricAuthentication;

@end

NS_ASSUME_NONNULL_END
