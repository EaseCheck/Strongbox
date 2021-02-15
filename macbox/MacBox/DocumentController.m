//
//  DocumentController.m
//  MacBox
//
//  Created by Mark on 21/08/2017.
//  Copyright © 2017 Mark McGuill. All rights reserved.
//

#import "DocumentController.h"
#import "Document.h"
#import "AbstractDatabaseFormatAdaptor.h"
#import "CreateFormatAndSetCredentialsWizard.h"
#import "DatabaseModel.h"
#import "Settings.h"
#import "DatabasesManagerVC.h"
#import "DatabasesManager.h"
#import "MacAlerts.h"
#import "Utils.h"
#import "NSArray+Extensions.h"
#import "BookmarksHelper.h"
#import "Serializator.h"
#import "MacUrlSchemes.h"

static NSString* const kStrongboxPasswordDatabaseDocumentType = @"Strongbox Password Database";

@implementation DocumentController



- (NSInteger)runModalOpenPanel:(NSOpenPanel *)openPanel forTypes:(nullable NSArray<NSString *> *)types {
    return [super runModalOpenPanel:openPanel forTypes:nil];
}

- (void)newDocument:(id)sender {
    CreateFormatAndSetCredentialsWizard* wizard = [[CreateFormatAndSetCredentialsWizard alloc] initWithWindowNibName:@"ChangeMasterPasswordWindowController"];
    
    NSString* loc = NSLocalizedString(@"mac_please_enter_master_credentials_for_this_database", @"Please Enter the Master Credentials for this Database");
    wizard.titleText = loc;
    wizard.initialDatabaseFormat = kKeePass4;
    wizard.createSafeWizardMode = YES;
    
    NSModalResponse returnCode = [NSApp runModalForWindow:wizard.window];

    if(returnCode != NSModalResponseOK) {
        return;
    }
    
    NSSavePanel *panel = [NSSavePanel savePanel];
    
    NSString* loc2 = NSLocalizedString(@"mac_save_new_database",  @"Save New Password Database...");
    panel.title = loc2;

    NSString* loc3 = NSLocalizedString(@"mac_save_action",  @"Save");
    panel.prompt = loc3;
    
    NSString* loc4 = NSLocalizedString(@"mac_save_new_db_message",  @"You must save this new database before you can use it");
    panel.message = loc4;
    
    NSString* ext = [Serializator getDefaultFileExtensionForFormat:wizard.selectedDatabaseFormat];
    
    NSString* loc5 = NSLocalizedString(@"mac_untitled_database_filename_fmt", @"Untitled.%@");
    panel.nameFieldStringValue = [NSString stringWithFormat:loc5, ext ];
    
    NSInteger modalCode = [panel runModal];

    if (modalCode == NSModalResponseOK) {
        NSURL *URL = [panel URL];

        CompositeKeyFactors* ckf = [wizard generateCkfFromSelected:nil];
        
        Document *document = [[Document alloc] initWithCredentials:wizard.selectedDatabaseFormat
                                               compositeKeyFactors:ckf];

        [document saveToURL:URL
                     ofType:kStrongboxPasswordDatabaseDocumentType
           forSaveOperation:NSSaveOperation
          completionHandler:^(NSError * _Nullable errorOrNil) {
            if(errorOrNil) {
                NSLog(@"Error Saving New Database: [%@]", errorOrNil);
            
                if (NSApplication.sharedApplication.keyWindow) {
                    [MacAlerts error:errorOrNil window:NSApplication.sharedApplication.keyWindow];
                }
                
                return;
            }

            DatabaseMetadata* database = [DatabasesManager.sharedInstance addOrGet:URL];
            database.keyFileBookmark = wizard.selectedKeyFileBookmark;
            database.yubiKeyConfiguration = wizard.selectedYubiKeyConfiguration;
            [DatabasesManager.sharedInstance update:database];
        
            [self addDocument:document];
            
            [document setDatabaseMetadata:database];
            
            [document makeWindowControllers];
            [document showWindows];
        }];
    }
}

- (void)openDocumentWithContentsOfURL:(NSURL *)url display:(BOOL)displayDocument completionHandler:(void (^)(NSDocument * _Nullable, BOOL, NSError * _Nullable))completionHandler {
    NSLog(@"openDocumentWithContentsOfURL: [%@]", url);
    [super openDocumentWithContentsOfURL:url display:displayDocument completionHandler:^(NSDocument * _Nullable document, BOOL documentWasAlreadyOpen, NSError * _Nullable error) {
        if ( document && !error ) {
            DatabaseMetadata* database = [DatabasesManager.sharedInstance addOrGet:url];
            [((Document*)document) setDatabaseMetadata:database];
        }
        
        completionHandler(document, documentWasAlreadyOpen, error);
    }];
}

- (void)openDocument:(id)sender {
    NSLog(@"openDocument: document count = [%ld]", self.documents.count);
    




        [self originalOpenDocument:sender];

    
    
}

- (void)originalOpenDocument:(id)sender {
    return [super openDocument:sender];
}

- (void)openDatabase:(DatabaseMetadata*)database completion:(void (^)(NSError* error))completion {
    NSURL* url = database.fileUrl;

    if(database.storageProvider == kLocalDevice) { 
        if (database.storageInfo != nil) {
            NSError *error = nil;
            NSString* updatedBookmark;
            url = [BookmarksHelper getUrlFromBookmark:database.storageInfo
                                                    readOnly:NO
                                             updatedBookmark:&updatedBookmark
                                                       error:&error];
            
            if(url == nil) {
                NSLog(@"WARN: Could not resolve bookmark for database... will try the saved fileUrl...");
                url = database.fileUrl;
            }
            else {
                
                
                if (updatedBookmark) {
                    database.storageInfo = updatedBookmark;
                }
                database.fileUrl = url;
                [DatabasesManager.sharedInstance update:database];
            }
        }
        else {
            NSLog(@"WARN: Storage info/Bookmark unavailable! Falling back solely on fileURL");
        }
    }
        
    if (url) {
        [url startAccessingSecurityScopedResource];
        [self openDocumentWithContentsOfURL:url
                                    display:YES
                          completionHandler:^(NSDocument * _Nullable document,
                                             BOOL documentWasAlreadyOpen,
                                             NSError * _Nullable error) {
            if(error) {
                NSLog(@"openDocumentWithContentsOfURL Error = [%@]", error);
            }
            
            completion(error);
        }];
    }
    else {
        completion([Utils createNSError:@"Database Open - Could not read file URL" errorCode:-2413]);
    }
}

- (NSString *)typeForContentsOfURL:(NSURL *)url error:(NSError *__autoreleasing  _Nullable *)outError {
    if ([url.scheme isEqualToString:kStrongboxSFTPUrlScheme]) {
        return kStrongboxPasswordDatabaseDocumentType;
    }
    
    return [super typeForContentsOfURL:url error:outError];
}

- (void)onAppStartup {
    NSLog(@"onAppStartup: document count = [%ld]", self.documents.count);

    if(DatabasesManager.sharedInstance.snapshot.count > 0 &&
       Settings.sharedInstance.autoOpenFirstDatabaseOnEmptyLaunch) {
        [self openPrimaryDatabase];
    }
    else if(self.documents.count == 0) {
        [DatabasesManagerVC show];
    }
}

- (void)performEmptyLaunchTasksIfNecessary {
    NSLog(@"performEmptyLaunchTasks...");
    
    if(self.documents.count == 0) { 
        NSLog(@"performEmptyLaunchTasks: document count = [%ld]", self.documents.count);
        
        if(DatabasesManager.sharedInstance.snapshot.count > 0 &&
           Settings.sharedInstance.autoOpenFirstDatabaseOnEmptyLaunch) {
            [self openPrimaryDatabase];
        }
        else {
            [DatabasesManagerVC show];
        }
    }
}

- (void)openPrimaryDatabase {
    if(DatabasesManager.sharedInstance.snapshot.count > 0 &&
       Settings.sharedInstance.autoOpenFirstDatabaseOnEmptyLaunch) {
        [self openDatabase:DatabasesManager.sharedInstance.snapshot.firstObject completion:^(NSError *error) { }];
    }
}



+ (void)restoreWindowWithIdentifier:(NSUserInterfaceItemIdentifier)identifier
                              state:(NSCoder *)state
                  completionHandler:(void (^)(NSWindow * _Nullable, NSError * _Nullable))completionHandler {
    NSLog(@"restoreWindowWithIdentifier...");
    
    if ([state containsValueForKey:@"StrongboxNonFileRestorationStateURL"] ) {
        NSURL *nonFileRestorationStateURL = [state decodeObjectForKey:@"StrongboxNonFileRestorationStateURL"];
        
        if ( nonFileRestorationStateURL ) {
            NSLog(@"restoreWindowWithIdentifier... custom URL");

            [[self sharedDocumentController] reopenDocumentForURL:nonFileRestorationStateURL
                                                withContentsOfURL:nonFileRestorationStateURL
                                                          display:NO
                                                completionHandler:^(NSDocument * _Nullable document, BOOL documentWasAlreadyOpen, NSError * _Nullable error) {
                NSWindow *resultWindow = nil;
                 
                if (!documentWasAlreadyOpen) {
                    if ( !document.windowControllers.count ) {
                         [document makeWindowControllers];
                    }
                    
                    if ( 1 == document.windowControllers.count ) {
                        resultWindow = document.windowControllers.firstObject.window;
                    }
                    else {
                        for (NSWindowController *wc in document.windowControllers) {
                            if ( [wc.window.identifier isEqual:identifier] ) {
                                resultWindow = wc.window;
                                break;
                            }
                        }
                    }
                }
                
                completionHandler(resultWindow, error);
            }];
        }
        
        return;
    }

    [super restoreWindowWithIdentifier:identifier state:state completionHandler:completionHandler];
}

@end
