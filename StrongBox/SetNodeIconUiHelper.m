//
//  SetNodeIconUiHelper.m
//  Strongbox-iOS
//
//  Created by Mark on 23/02/2019.
//  Copyright © 2019 Mark McGuill. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SetNodeIconUiHelper.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "Utils.h"
#import "SVProgressHUD/SVProgressHUD.h"
#import "Alerts.h"
#import "IconsCollectionViewController.h"
#import "Settings.h"

//#ifndef IS_APP_EXTENSION
@import FavIcon;
//#endif

static const int kMaxRecommendedCustomIconDimension = 256; // Future: Setting?

@interface SetNodeIconUiHelper () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property UIViewController *viewController;
@property ChangeIconCompletionBlock completionBlock;

@end

@implementation SetNodeIconUiHelper

- (void)changeIcon:(UIViewController *)viewController urlHint:(NSString *)urlHint format:(DatabaseFormat)format completion:(ChangeIconCompletionBlock)completion {
    self.viewController = viewController;
    self.completionBlock = completion;
    
    if(format == kPasswordSafe) {
        NSLog(@"Should not be calling this if safe is Password Safe!!");
        self.completionBlock(NO, nil, nil, nil);
        return;
    }
    if(format == kKeePass1) {
        [self presentKeePassAndDatabaseIconSets];
    }
    else {
        NSURL* url = [self smartDetermineUrlFromHint:urlHint];
        
        if (url) { // FavIcon support not available on free tier
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Select Icon Source"
                                                                                     message:@"Select the source of the icon you would like to use for this entry"
                                                                              preferredStyle:UIAlertControllerStyleAlert];
            
            // this is the center of the screen currently but it can be any point in the view
            
            
            UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"KeePass & Database Icon Set"
                                                                    style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction *a) { [self presentKeePassAndDatabaseIconSets]; }];
            
            UIAlertAction *secondAction = [UIAlertAction actionWithTitle:@"Media Library"
                                                                   style:UIAlertActionStyleDefault
                                                                 handler:^(UIAlertAction *a) { [self presentCustomIconImagePicker]; }];
            
            UIAlertAction *thirdAction = [UIAlertAction actionWithTitle:Settings.sharedInstance.isProOrFreeTrial ? @"Download FavIcon" : @"Download FavIcon (Pro Only)"
                                                                  style:UIAlertActionStyleDefault
                                                                handler:^(UIAlertAction *a) {  [self downloadFavIcon:url silent:NO completion:^(BOOL goNoGo, UIImage * _Nullable userSelectedNewCustomIcon) {
                completion(goNoGo, nil, nil, userSelectedNewCustomIcon);
            }]; }];
            
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                                   style:UIAlertActionStyleCancel
                                                                 handler:^(UIAlertAction *a) { self.completionBlock(NO, nil, nil, nil); }];
            
            thirdAction.enabled = Settings.sharedInstance.isProOrFreeTrial;
            
            [alertController addAction:defaultAction];
            [alertController addAction:secondAction];
            [alertController addAction:thirdAction];
            [alertController addAction:cancelAction];
            
            [self.viewController presentViewController:alertController animated:YES completion:nil];
        }
        else {
            [Alerts threeOptions:viewController
                           title:@"Select Icon Source"
                         message:@"Select the source of the icon you would like to use for this entry"
               defaultButtonText:@"KeePass & Database Icon Set"
                secondButtonText:@"Media Library"
                 thirdButtonText:@"Cancel"
                          action:^(int response) {
                   if(response == 0) {
                       [self presentKeePassAndDatabaseIconSets];
                   }
                   else if(response == 1) {
                       [self presentCustomIconImagePicker];
                   }
                   else {
                       self.completionBlock(NO, nil, nil, nil); // Cancelled
                   }}];
        }
    }
}

- (void)tryDownloadFavIcon:(NSString*)urlHint completion:(DownloadFavIconCompletionBlock)completion {
    NSURL* url = [self smartDetermineUrlFromHint:urlHint];
    
    if(url) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self downloadFavIcon:url silent:YES completion:completion];
        });
    }
    else {
        completion(NO, nil);
    }
}

- (NSURL*)smartDetermineUrlFromHint:(NSString*)urlHint {
    NSURL* url = [NSURL URLWithString:urlHint];
    
    if(urlHint.length > 0) {
        NSURLComponents *components = [NSURLComponents componentsWithString:urlHint];
        NSLog(@"scheme = [%@],user = [%@],password = [%@],host = [%@],port = [%@],path = [%@],query = [%@],fragment = [%@]",
              components.scheme,
              components.user,
              components.password,
              components.host,
              components.port,
              components.path,
              components.query,
              components.fragment);
        
        if(!components.scheme.length) { // facebook.com/whatever.php or just even Facebook!
            NSURLComponents* newComponents = [[NSURLComponents alloc] init];
            newComponents.scheme = @"http";
            NSArray* comp = [urlHint componentsSeparatedByString:@"/"];
            NSString* host = comp[0];
            if(![host containsString:@"."]) { // maybe just Facebook
                host = [host stringByAppendingString:@".com"];
            }
            
            newComponents.host = host;
            url = newComponents.URL;
        }
        else if (![components.scheme hasPrefix:@"http"]) { // ftp://facebook.com
            NSURLComponents* newComponents = [[NSURLComponents alloc] init];
            newComponents.scheme = @"http";
            newComponents.host = components.host;
            url = newComponents.URL;
        }
        else { // http://facebook.com/whatever.php - strip the path, just use the host
            NSURLComponents* newComponents = [[NSURLComponents alloc] init];
            newComponents.scheme = components.scheme;
            newComponents.host = components.host;
            url = newComponents.URL;
        }
    }
    
    return url;
}

- (void)downloadFavIcon:(NSURL*)url silent:(BOOL)silent completion:(DownloadFavIconCompletionBlock)completion {
    //[Fav downloadPreferred:];
    [SVProgressHUD showWithStatus:@"Downloading FavIcon"];
    NSLog(@"attempting to download favicon for: [%@]", url);
    [FavIcon downloadPreferred:url width:kMaxRecommendedCustomIconDimension height:kMaxRecommendedCustomIconDimension completion:^(UIImage * _Nullable image) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
            
            if(image && image.size.width > 0 && image.size.height > 0) {
                completion(YES, image);
                NSLog(@"FavIcon download Done!");
            }
            else {
                if(!silent) {
                    [Alerts warn:self.viewController title:@"FavIcon Problem" message:@"Could not download favicon for this item"];
                }
                completion(NO, nil);
            }
        });
    }];
}

- (void)presentKeePassAndDatabaseIconSets {
    IconsCollectionViewController* vc = [[IconsCollectionViewController alloc] init];
    vc.customIcons = self.customIcons;
    vc.modalPresentationStyle = UIModalPresentationFormSheet;
    
    vc.onDone = ^(BOOL response, NSInteger selectedIndex, NSUUID * _Nullable selectedCustomIconId) {
        [self.viewController dismissViewControllerAnimated:YES completion:^{
            if(response) {
                self.completionBlock(YES, @(selectedIndex), selectedCustomIconId, nil);
            }
            else {
                self.completionBlock(NO, nil, nil, nil);
            }
        }];
    };
    
    [self.viewController presentViewController:vc animated:YES completion:nil];
}

- (void)presentCustomIconImagePicker {
    UIImagePickerController *vc = [[UIImagePickerController alloc] init];
    vc.videoQuality = UIImagePickerControllerQualityTypeHigh;
    vc.delegate = self;
    vc.modalPresentationStyle = UIModalPresentationFormSheet;
    
    BOOL available = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary];
    
    if(!available) {
        [Alerts info:self.viewController title:@"Image Source Unavailable" message:@"Could not access photos source."];
        self.completionBlock(NO, nil, nil, nil);
        return;
    }
    
    vc.mediaTypes = @[(NSString*)kUTTypeImage];
    vc.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    [self.viewController presentViewController:vc animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey, id> *)info {
    [picker dismissViewControllerAnimated:YES completion:^
     {
         [self onDonePickingCustomIcon:info];
     }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:^
     {
         self.completionBlock(NO, nil, nil, nil);
     }];
}

- (void)onDonePickingCustomIcon:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    [SVProgressHUD showWithStatus:@"Reading Data..."];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0L), ^{
        NSError* error;
        NSData* data = [Utils getImageDataFromPickedImage:info error:&error];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
            if(!data) {
                NSLog(@"Error: %@", error);
                [Alerts error:self.viewController title:@"Error Reading Image" error:error];
                self.completionBlock(NO, nil, nil, nil);
            }
            else {
                [self analyzeCustomIconAndSet:data];
            }
        });
    });
}

- (void)analyzeCustomIconAndSet:(NSData*)data {
    [SVProgressHUD showWithStatus:@"Analyzing Image..."];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0L), ^{
        UIImage* image = [UIImage imageWithData:data];
        NSData* dataOriginal = UIImagePNGRepresentation(image);
        //NSLog(@"before: %f - %f - %lu", image.size.width, image.size.height, (unsigned long)dataOriginal.length);
        if(image.size.height > kMaxRecommendedCustomIconDimension || image.size.width > kMaxRecommendedCustomIconDimension) {
            UIImage* rescaled = scaleImage(image, CGSizeMake(kMaxRecommendedCustomIconDimension, kMaxRecommendedCustomIconDimension));
            NSData* rescaledData = UIImagePNGRepresentation(rescaled);
            //NSLog(@"after: %f - %f - %lu", rescaled.size.width, rescaled.size.height, (unsigned long)rescaledData.length);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD dismiss];
                
                if(dataOriginal.length > rescaledData.length) {
                    NSUInteger saving = dataOriginal.length - rescaledData.length;
                    NSString* savingString = friendlyFileSizeString(saving);
                    NSString* message = [NSString stringWithFormat:@"This is a rather large image (%dx%d), would you like to rescale it to a maximum dimension of %d pixels for a file size saving of roughly %@", (int)image.size.width, (int)image.size.height, kMaxRecommendedCustomIconDimension, savingString];
                    
                    [Alerts yesNo:self.viewController title:@"Large Custom Icon Image, Rescale?" message:message action:^(BOOL response) {
                        self.completionBlock(YES, nil, nil, response ? rescaled : image);
                    }];
                }
                else {
                    self.completionBlock(YES, nil, nil, image);
                }
            });
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD dismiss];
                self.completionBlock(YES, nil, nil, image);
            });
        }
    });
}

@end
