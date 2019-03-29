//
//  Alerts.h
//  MacBox
//
//  Created by Mark on 11/08/2017.
//  Copyright © 2017 Mark McGuill. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@interface Alerts : NSObject<NSTextFieldDelegate>

+ (void)error:(NSError*)error window:(NSWindow*)window;
+ (void)error:(NSString*)message error:(NSError*)error window:(NSWindow*)window;
+ (void)error:(NSString*)message error:(NSError*)error window:(NSWindow*)window completion:(void (^)(void))completion;

+ (void)info:(NSString *)info window:(NSWindow*)window;
+ (void)info:(NSString *)message informativeText:(NSString*)informativeText window:(NSWindow*)window completion:(void (^)(void))completion;

+ (void)yesNo:(NSString *)info window:(NSWindow*)window completion:(void (^)(BOOL yesNo))completion;

- (NSString *)input:(NSString *)prompt defaultValue:(NSString *)defaultValue allowEmpty:(BOOL)allowEmpty;

- (void)inputKeyValue:(NSString*)prompt
              initKey:(NSString*)initKey
            initValue:(NSString*)initValue
        initProtected:(BOOL)initProtected
          placeHolder:(BOOL)placeHolder
           completion:(void (^)(BOOL yesNo, NSString* key, NSString* value, BOOL protected))completion;

@end
