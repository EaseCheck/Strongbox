//
//  ClipboardManager.m
//  Strongbox
//
//  Created by Mark on 10/01/2020.
//  Copyright © 2020 Mark McGuill. All rights reserved.
//

#import "ClipboardManager.h"
#import <Cocoa/Cocoa.h>
#import "Settings.h"

@implementation ClipboardManager

+ (instancetype)sharedInstance {
    static ClipboardManager *sharedInstance = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        sharedInstance = [[ClipboardManager alloc] init];
    });
    return sharedInstance;
}

- (void)copyConcealedString:(NSString *)string {
    [NSPasteboard.generalPasteboard clearContents]; // NB: Must be called!
    
    if (@available(macOS 10.12, *)) {
        if (!Settings.sharedInstance.clipboardHandoff) {
            [NSPasteboard.generalPasteboard prepareForNewContentsWithOptions:NSPasteboardContentsCurrentHostOnly];
        }
    }
    
    [NSPasteboard.generalPasteboard setString:(string ? string : @"") forType:NSStringPboardType];
}

@end

