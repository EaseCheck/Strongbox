//
//  AddAttachmentHelper.h
//  Strongbox-iOS
//
//  Created by Mark on 25/04/2019.
//  Copyright © 2019 Mark McGuill. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "UiAttachment.h"

NS_ASSUME_NONNULL_BEGIN

extern const int kMaxRecommendedAttachmentSize;

@interface AddAttachmentHelper : NSObject

+ (instancetype)sharedInstance;

- (void)beginAddAttachmentUi:(UIViewController*)vc
               usedFilenames:(NSArray<NSString*>*)usedFilenames
                       onAdd:(void(^)(UiAttachment* attachment))onAdd;

@end

NS_ASSUME_NONNULL_END
