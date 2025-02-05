//
//  PickCredentialsTableViewController.m
//  Strongbox AutoFill
//
//  Created by Mark on 14/10/2018.
//  Copyright © 2014-2021 Mark McGuill. All rights reserved.
//

#import "PickCredentialsTableViewController.h"
#import "NodeIconHelper.h"
#import "NSArray+Extensions.h"
#import "Alerts.h"
#import "Utils.h"
#import "regdom.h"
#import "BrowseItemCell.h"
#import "ItemDetailsViewController.h"
#import "DatabaseSearchAndSorter.h"
#import "OTPToken+Generation.h"
#import "ClipboardManager.h"
#import "BrowseTableViewCellHelper.h"
#import "AppPreferences.h"
#import "SafeStorageProviderFactory.h"
#import "NSString+Extensions.h"
#import "AutoFillPreferencesViewController.h"

static NSString* const kGroupTitleMatches = @"title";
static NSString* const kGroupUrlMatches = @"url";
static NSString* const kGroupAllFieldsMatches = @"all-matches";
static NSString* const kGroupNoMatchingItems = @"no-matches";
static NSString* const kGroupPinned = @"pinned";
static NSString* const kGroupServiceId = @"service-id";
static NSString* const kGroupActions = @"actions";
static NSString* const kGroupAllItems = @"all-items";

@interface PickCredentialsTableViewController () <UISearchBarDelegate, UISearchResultsUpdating>

@property NSArray<NSString*> *groups;
@property (strong, nonatomic) NSDictionary<NSString*, NSArray<Node*>*> *groupedResults;

@property (strong, nonatomic) UISearchController *searchController;
@property NSTimer* timerRefreshOtp;

@property BrowseTableViewCellHelper* cellHelper;
@property BOOL doneFirstAppearanceTasks;
@property (readonly) BOOL foundSearchResults;
@property (readonly) BOOL showNoMatchesSection;
@property (readonly) BOOL showAllItemsSection;

@end

@implementation PickCredentialsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if(AppPreferences.sharedInstance.hideTips) {
        self.navigationItem.prompt = nil;
    }
    
    [self setupTableview];
    
    self.extendedLayoutIncludesOpaqueBars = YES;
    self.definesPresentationContext = YES;
    
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.obscuresBackgroundDuringPresentation = NO;
    self.searchController.searchBar.delegate = self;

    if (@available(iOS 11.0, *)) {
        self.navigationItem.searchController = self.searchController;
        
        self.navigationItem.hidesSearchBarWhenScrolling = NO;
    } else {
        self.tableView.tableHeaderView = self.searchController.searchBar;
        [self.searchController.searchBar sizeToFit];
    }
    self.searchController.searchBar.enablesReturnKeyAutomatically = NO; 
        
    
    
    self.groups = @[
        kGroupNoMatchingItems,
        kGroupUrlMatches,
        kGroupTitleMatches,
        kGroupAllFieldsMatches,
        kGroupPinned,
        kGroupActions,
        kGroupServiceId,
        kGroupAllItems
    ];
    
    NSArray<Node*> *allItems = [self loadAllItems];
    NSArray<Node*> *pinnedItems = [self loadPinnedItems];
    
    self.groupedResults = @{ kGroupAllItems : allItems,
                                   kGroupPinned : pinnedItems };
}

- (void)setupTableview {
    self.cellHelper = [[BrowseTableViewCellHelper alloc] initWithModel:self.model tableView:self.tableView];
    
    self.tableView.estimatedRowHeight = UITableViewAutomaticDimension;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    self.tableView.tableFooterView = [UIView new];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if(self.timerRefreshOtp) {
        [self.timerRefreshOtp invalidate];
        self.timerRefreshOtp = nil;
    }
}

- (IBAction)updateOtpCodes:(id)sender {
    [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self.navigationController setNavigationBarHidden:NO];
    [self.navigationController setToolbarHidden:NO];
    
    if(self.timerRefreshOtp) {
        [self.timerRefreshOtp invalidate];
        self.timerRefreshOtp = nil;
    }
    
    if(!self.model.metadata.hideTotpInBrowse) {
        self.timerRefreshOtp = [NSTimer timerWithTimeInterval:1.0f target:self selector:@selector(updateOtpCodes:) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:self.timerRefreshOtp forMode:NSRunLoopCommonModes];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    
    
    if (!self.doneFirstAppearanceTasks) {
        self.doneFirstAppearanceTasks = YES;
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5  * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ 
            [self smartInitializeSearch];

            [self.searchController.searchBar becomeFirstResponder];

            
            
            if ( AppPreferences.sharedInstance.autoProceedOnSingleMatch ) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self proceedWithSingleMatch];
                });
            }
        });
    }
}

- (NSUInteger)getSearchResultsCount {
    NSArray<Node*>* urls = self.groupedResults[kGroupUrlMatches];
    NSArray<Node*>* titles = self.groupedResults[kGroupTitleMatches];
    NSArray<Node*>* others = self.groupedResults[kGroupAllFieldsMatches];

    NSUInteger urlCount = urls ? urls.count : 0;
    NSUInteger titleCount = titles ? titles.count : 0;
    NSUInteger otherCount = others ? others.count : 0;

    return urlCount + titleCount + otherCount;
}

- (IBAction)onCancel:(id)sender {
    [self.rootViewController exitWithUserCancelled:self.model.metadata];
}

- (void)smartInitializeSearch {
    NSArray<ASCredentialServiceIdentifier *> *serviceIdentifiers = [self.rootViewController getCredentialServiceIdentifiers];
    
    ASCredentialServiceIdentifier *serviceId = [serviceIdentifiers firstObject];
    if(serviceId) {
        if(serviceId.type == ASCredentialServiceIdentifierTypeURL) {
            NSURL* url = serviceId.identifier.urlExtendedParse;
            
            
            
            
            
            if (url) {
                NSArray* items = [self getMatchingItems:url.absoluteString scope:kSearchScopeUrl];
                if(items.count) {
                    [self.searchController.searchBar setText:url.absoluteString];
                    [self.searchController.searchBar setSelectedScopeButtonIndex:kSearchScopeUrl];
                    return;
                }
                else {
                    NSLog(@"No matches for URL: %@", url.absoluteString);
                }
                
                
                
                items = [self getMatchingItems:url.host scope:kSearchScopeUrl];
                if(items.count) {
                    [self.searchController.searchBar setText:url.host];
                    [self.searchController.searchBar setSelectedScopeButtonIndex:kSearchScopeUrl];
                    return;
                }
                else {
                    NSLog(@"No matches for URL: %@", url.host);
                }

                
                NSString* domain = getDomain(url.host);
                [self smartInitializeSearchFromDomain:domain];
            }
            else {
                NSLog(@"No matches for URL: %@", url);
            }
        }
        else if (serviceId.type == ASCredentialServiceIdentifierTypeDomain) {
            [self smartInitializeSearchFromDomain:serviceId.identifier];
        }
    }
}

- (void)smartInitializeSearchFromDomain:(NSString*)domain {
    
    
    NSArray* items = [self getMatchingItems:domain scope:kSearchScopeUrl];
    if(items.count) {
        [self.searchController.searchBar setText:domain];
        [self.searchController.searchBar setSelectedScopeButtonIndex:kSearchScopeUrl];
        return;
    }
    else {
        NSLog(@"No matches in URLs for Domain: %@", domain);
    }
    
    
    
    items = [self getMatchingItems:domain scope:kSearchScopeAll];
    if(items.count) {
        [self.searchController.searchBar setText:domain];
        [self.searchController.searchBar setSelectedScopeButtonIndex:kSearchScopeAll];
        return;
    }
    else {
        NSLog(@"No matches across all fields for Domain: %@", domain);
    }

    
    
    NSString * searchTerm = getCompanyOrOrganisationNameFromDomain(domain);
    [self.searchController.searchBar setText:searchTerm];
    [self.searchController.searchBar setSelectedScopeButtonIndex:kSearchScopeAll];
}

NSString *getDomain(NSString* host) {
    if(host == nil) {
        return @"";
    }
    
    if(!host.length) {
        return @"";
    }
    
    const char *cStringUrl = [host UTF8String];
    if(!cStringUrl || strlen(cStringUrl) == 0) {
        return @"";
    }
    
    void *tree = loadTldTree();
    const char *result = getRegisteredDomainDrop(cStringUrl, tree, 1);
    
    if(result == NULL) {
        return @"";
    }
    
    NSString *domain = [NSString stringWithCString:result encoding:NSUTF8StringEncoding];
    
    NSLog(@"Calculated Domain: %@", domain);
    
    return domain;
}

NSString *getCompanyOrOrganisationNameFromDomain(NSString* domain) {
    if(!domain.length) {
        return domain;
    }
    
    NSArray<NSString*> *parts = [domain componentsSeparatedByString:@"."];
    
    NSLog(@"%@", parts);
    
    NSString *searchTerm =  parts.count ? parts[0] : domain;
    return searchTerm;
}

- (NSArray<Node*>*)loadAllItems {
    BrowseSortField sortField = self.model.metadata.browseSortField;
    BOOL descending = self.model.metadata.browseSortOrderDescending;
    BOOL foldersSeparately = self.model.metadata.browseSortFoldersSeparately;
    
    DatabaseSearchAndSorter* searcher = [[DatabaseSearchAndSorter alloc] initWithModel:self.model.database
                                                                       browseSortField:sortField
                                                                            descending:descending
                                                                     foldersSeparately:foldersSeparately
                                                                           checkPinYin:AppPreferences.sharedInstance.pinYinSearchEnabled
                                                                      isFlaggedByAudit:^BOOL(Node * _Nonnull node) {
        return [self.model isFlaggedByAudit:node.uuid];
    }];

    return [searcher filterAndSortForBrowse:self.model.allRecords.mutableCopy
                      includeKeePass1Backup:self.model.metadata.showKeePass1BackupGroup
                          includeRecycleBin:self.model.metadata.showRecycleBinInSearchResults
                             includeExpired:self.model.metadata.showExpiredInSearch
                              includeGroups:NO];
}

- (NSArray<Node*>*)loadPinnedItems {
    if( !self.model.pinnedSet.count || !AppPreferences.sharedInstance.autoFillShowPinned ) {
        return @[];
    }
    
    BrowseSortField sortField = self.model.metadata.browseSortField;
    BOOL descending = self.model.metadata.browseSortOrderDescending;
    BOOL foldersSeparately = self.model.metadata.browseSortFoldersSeparately;
    
    DatabaseSearchAndSorter* searcher = [[DatabaseSearchAndSorter alloc] initWithModel:self.model.database
                                                                       browseSortField:sortField
                                                                            descending:descending
                                                                     foldersSeparately:foldersSeparately
                                                                           checkPinYin:AppPreferences.sharedInstance.pinYinSearchEnabled
                                                                      isFlaggedByAudit:^BOOL(Node * _Nonnull node) {
        return [self.model isFlaggedByAudit:node.uuid];
    }];

    return [searcher filterAndSortForBrowse:self.model.pinnedNodes.mutableCopy
                      includeKeePass1Backup:NO
                          includeRecycleBin:NO
                             includeExpired:YES
                              includeGroups:NO];
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *searchString = searchController.searchBar.text;
    
    NSMutableDictionary* updated = self.groupedResults.mutableCopy;

    if(!searchString.length) {
        updated[kGroupUrlMatches] = @[];
        updated[kGroupTitleMatches] =  @[];
        updated[kGroupAllFieldsMatches] = @[];
    }
    else {
        NSArray<Node*> *urlMatches = [self getMatchingItems:searchString scope:kSearchScopeUrl];
        NSArray<Node*> *titleMatches = [self getMatchingItems:searchString scope:kSearchScopeTitle];
        NSArray<Node*> *otherFieldMatches = [self getMatchingItems:searchString scope:kSearchScopeAll];
        
        updated[kGroupUrlMatches] = urlMatches;
        NSSet<NSUUID*>* urlMatchSet = [urlMatches map:^id _Nonnull(Node * _Nonnull obj, NSUInteger idx) {
            return obj.uuid;
        }].set;
        
        titleMatches = [titleMatches filter:^BOOL(Node * _Nonnull obj) {
            return ![urlMatchSet containsObject:obj.uuid];
        }];
        
        updated[kGroupTitleMatches] = titleMatches;
        
        NSSet<NSUUID*>* titleMatchSet = [titleMatches map:^id _Nonnull(Node * _Nonnull obj, NSUInteger idx) {
            return obj.uuid;
        }].set;

        otherFieldMatches = [otherFieldMatches filter:^BOOL(Node * _Nonnull obj) {
            return ![urlMatchSet containsObject:obj.uuid] && ![titleMatchSet containsObject:obj.uuid];
        }];
        
        updated[kGroupAllFieldsMatches] = otherFieldMatches;
    }
    
    self.groupedResults = updated;
    
    [self.tableView reloadData];
}

- (NSArray<Node*>*)getMatchingItems:(NSString*)searchText scope:(SearchScope)scope {
    BrowseSortField sortField = self.model.metadata.browseSortField;
    BOOL descending = self.model.metadata.browseSortOrderDescending;
    BOOL foldersSeparately = self.model.metadata.browseSortFoldersSeparately;
    DatabaseSearchAndSorter* searcher = [[DatabaseSearchAndSorter alloc] initWithModel:self.model.database
                                                                       browseSortField:sortField
                                                                            descending:descending
                                                                     foldersSeparately:foldersSeparately
                                                                           checkPinYin:AppPreferences.sharedInstance.pinYinSearchEnabled
                                                                      isFlaggedByAudit:^BOOL(Node * _Nonnull node) {
        return [self.model isFlaggedByAudit:node.uuid];
    }];

    return [searcher search:searchText
                      scope:scope
                dereference:self.model.metadata.searchDereferencedFields
      includeKeePass1Backup:self.model.metadata.showKeePass1BackupGroup
          includeRecycleBin:self.model.metadata.showRecycleBinInSearchResults
             includeExpired:self.model.metadata.showExpiredInSearch
              includeGroups:NO];
}



- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.groups.count;
}

- (BOOL)foundSearchResults {
    return [self getSearchResultsCount] != 0;
}

- (BOOL)showNoMatchesSection {
    return !self.foundSearchResults && self.searchController.searchBar.text.length != 0;
}

- (BOOL)showAllItemsSection {
    return !self.foundSearchResults || self.searchController.searchBar.text.length == 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSString* group = self.groups[section];
    
    if ( [group isEqualToString:kGroupServiceId] ) {
        return 1;
    }
    else if ( [group isEqualToString:kGroupActions] ) {
        return 2;
    }
    else if ( [group isEqualToString:kGroupNoMatchingItems] ) {
        return self.showNoMatchesSection ? 1 : 0;
    }
    else if ( [group isEqualToString:kGroupAllItems] ) {
        NSArray<Node*> *items = self.groupedResults[kGroupAllItems];
        return self.showAllItemsSection ? (items ? items.count : 0) : 0;
    }
    else {
        NSArray<Node*> *items = self.groupedResults[group];
        return items ? items.count : 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString* group = self.groups[indexPath.section];
    
    if ( [group isEqualToString:kGroupServiceId] ) {
        UITableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:@"PickCredentialGenericCell" forIndexPath:indexPath];

        NSArray<ASCredentialServiceIdentifier *> *serviceIdentifiers = [self.rootViewController getCredentialServiceIdentifiers];
      

        cell.textLabel.text = @"";
        cell.detailTextLabel.text = serviceIdentifiers.firstObject ? serviceIdentifiers.firstObject.identifier : NSLocalizedString(@"generic_none", @"None");
        
        cell.imageView.image = nil;
        
        return cell;
    }
    else if ( [group isEqualToString:kGroupActions] ) {
        UITableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:@"PickCredentialGenericBasicCell" forIndexPath:indexPath];
        
        if ( indexPath.row == 0 ) {
            cell.textLabel.text = NSLocalizedString(@"pick_creds_vc_create_new_button_title", @"Create New Entry...");
            if (@available(iOS 13.0, *)) {
                cell.imageView.image = [UIImage systemImageNamed:@"plus"];
                cell.imageView.tintColor = [self canCreateNewCredential] ? nil : UIColor.secondaryLabelColor;
                
                cell.textLabel.textColor = [self canCreateNewCredential] ? UIColor.systemBlueColor : UIColor.secondaryLabelColor;
            }
            else {
                cell.textLabel.textColor = [self canCreateNewCredential] ? UIColor.systemBlueColor : UIColor.darkTextColor;
            }
            cell.userInteractionEnabled = [self canCreateNewCredential];
        }
        else {
            cell.textLabel.text = NSLocalizedString(@"generic_preferences", @"Preferences");
            if (@available(iOS 13.0, *)) {
                cell.imageView.image = [UIImage systemImageNamed:@"gear"];
            }
            
            cell.textLabel.textColor = UIColor.systemBlueColor;
            cell.userInteractionEnabled = YES;
        }
        
        return cell;
    }
    else if ( [group isEqualToString:kGroupNoMatchingItems] ) {
        UITableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:@"PickCredentialGenericBasicCell" forIndexPath:indexPath];
        
        cell.textLabel.text = NSLocalizedString(@"pick_creds_vc_empty_search_dataset_title", @"No Matching Records");
        cell.imageView.image = [UIImage imageNamed:@"search"];
        if (@available(iOS 13.0, *)) {
            cell.textLabel.textColor = UIColor.labelColor;
        }
        else {
            cell.textLabel.textColor = UIColor.darkTextColor;
        }
        
        return cell;
    }
    else {
        NSArray<Node*> *items = self.groupedResults[group];
        Node* item = (items && items.count > indexPath.row) ? items[indexPath.row] : nil;

        if ( item ) {
            return [self.cellHelper getBrowseCellForNode:item indexPath:indexPath showLargeTotpCell:NO showGroupLocation:self.searchController.isActive];
        }
        else { 
            return [self.tableView dequeueReusableCellWithIdentifier:@"PickCredentialGenericCell" forIndexPath:indexPath];
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString* group = self.groups[indexPath.section];
    
    if ( [group isEqualToString:kGroupServiceId] ) {
        NSArray<ASCredentialServiceIdentifier *> *serviceIdentifiers = [self.rootViewController getCredentialServiceIdentifiers];
        if ( serviceIdentifiers.firstObject ) {
            [ClipboardManager.sharedInstance copyStringWithNoExpiration:serviceIdentifiers.firstObject.identifier];
        }
    }
    else if ( [group isEqualToString:kGroupActions] ) {
        if ( indexPath.row == 0 ) {
            [self onAddCredential:nil];
        }
        else {
            [self onPreferences:nil];
        }
    }
    else if ( [group isEqualToString:kGroupNoMatchingItems] ) {
        
    }
    else {
        NSArray<Node*> *items = self.groupedResults[group];
        Node* item = (items && items.count > indexPath.row) ? items[indexPath.row] : nil;

        if(item) {
            [self proceedWithItem:item];
        }
        else {
            NSLog(@"WARN: DidSelectRow with no Record?!");
        }
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString* group = self.groups[section];

    if ( [group isEqualToString:kGroupTitleMatches] ) {
        return NSLocalizedString(@"autofill_search_title_matches_section_header", @"Title Matches");
    }
    else if ( [group isEqualToString:kGroupUrlMatches] ) {
        return NSLocalizedString(@"autofill_search_url_matches_section_header", @"URL Matches");
    }
    else if ( [group isEqualToString:kGroupAllFieldsMatches] ) {
        return NSLocalizedString(@"autofill_search_other_matches_section_header", @"Other Matches");
    }
    else if ( [group isEqualToString:kGroupPinned] ) {
        return NSLocalizedString(@"browse_vc_section_title_pinned", @"Pinned");
    }
    else if ( [group isEqualToString:kGroupServiceId] ) {
        return NSLocalizedString(@"autofill_search_title_service_id_section_header", @"Service ID");
    }
    else if ( [group isEqualToString:kGroupActions] ) {
        return NSLocalizedString(@"generic_actions", @"Actions");
    }
    else if ( [group isEqualToString:kGroupAllItems] ) {
        return NSLocalizedString(@"quick_view_title_all_entries_title", @"All Entries");
    }
    else if ( [group isEqualToString:kGroupNoMatchingItems] ) {
        return NSLocalizedString(@"quick_view_title_no_matches_title", @"Results");
    }
    
    return self.groups[section];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NSString* group = self.groups[section];

    if ( [group isEqualToString:kGroupServiceId] ) {
        return NSLocalizedString(@"autofill_search_service_id_section_footer", @"");
    }
    
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    NSString* group = self.groups[section];

    if ( [group isEqualToString:kGroupNoMatchingItems] ) {
        return self.showNoMatchesSection ? UITableViewAutomaticDimension : 0.1f;
    }

    if ( [group isEqualToString:kGroupAllItems] ) {
        return self.showAllItemsSection ? UITableViewAutomaticDimension : 0.1f;
    }

    if ( ![group isEqualToString:kGroupServiceId] && ![group isEqualToString:kGroupActions] ) {
        NSArray<Node*> *items = self.groupedResults[group];
        if ( items.count == 0) {
            return 0.1f;
        }
    }

    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString* group = self.groups[indexPath.section];

    if ( [group isEqualToString:kGroupActions] ) {
        if ( indexPath.row == 0 ) {
            if ( self.model.isReadOnly ) {
                return 0.0f;
            }
        }
    }
    
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    NSString* group = self.groups[section];

    if ( [group isEqualToString:kGroupServiceId] ) {
        return UITableViewAutomaticDimension;
    }









            return 0.1f;





}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    NSString* group = self.groups[section];

    if ( [group isEqualToString:kGroupNoMatchingItems] ) {
        return self.showNoMatchesSection ? [super tableView:tableView viewForHeaderInSection:section] : [self sectionFiller];
    }

    if ( [group isEqualToString:kGroupAllItems] ) {
        return self.showAllItemsSection ? [super tableView:tableView viewForHeaderInSection:section] : [self sectionFiller];
    }
    
    if ( ![group isEqualToString:kGroupServiceId]  && ![group isEqualToString:kGroupActions] ) {
        NSArray<Node*> *items = self.groupedResults[group];
        if ( items.count == 0) {
            return [self sectionFiller];
        }
    }

    return [super tableView:tableView viewForHeaderInSection:section];
}

- (UIView *)sectionFiller {
    static UILabel *emptyLabel = nil;
    if (!emptyLabel) {
        emptyLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        emptyLabel.backgroundColor = [UIColor clearColor];
    }
    return emptyLabel;
}

- (Node*)getTopMatch {
    NSArray<Node*>* urls = self.groupedResults[kGroupUrlMatches];
    NSArray<Node*>* titles = self.groupedResults[kGroupTitleMatches];
    NSArray<Node*>* others = self.groupedResults[kGroupAllFieldsMatches];

    NSUInteger urlCount = urls ? urls.count : 0;
    NSUInteger titleCount = titles ? titles.count : 0;
    NSUInteger otherCount = others ? others.count : 0;

    if ( ( urlCount + titleCount + otherCount ) > 0 ) {
        if ( urlCount ) {
            return urls.firstObject;
        }
        else if ( titleCount ) {
            return titles.firstObject;
        }
        
        return others.firstObject;
    }
    
    return nil;
}

- (void)proceedWithSingleMatch {
    if ( [self getSearchResultsCount] == 1 ) {
        [self proceedWithTopMatch];
    }
}

- (void)proceedWithTopMatch {
    Node* item = [self getTopMatch];
    [self proceedWithItem:item];
}

- (void)proceedWithItem:(Node*)item {
    if ( item ) {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
            [self.rootViewController exitWithCredential:self.model item:item];
        }];
    }
}


- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    if ( self.foundSearchResults ) {
        [self proceedWithTopMatch];
    }
}

- (NSString*)dereference:(NSString*)text node:(Node*)node {
    return [self.model.database dereference:text node:node];
}

- (IBAction)onAddCredential:(id)sender {
    if ( [self canCreateNewCredential] ) {
        [self performSegueWithIdentifier:@"segueToAddNew" sender:nil];
    }
}

- (IBAction)onPreferences:(id)sender {
    [self performSegueWithIdentifier:@"segueToPreferences" sender:self.model];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {  
    if ([segue.identifier isEqualToString:@"segueToAddNew"]) {
        ItemDetailsViewController* vc = (ItemDetailsViewController*)segue.destinationViewController;
        [self addNewEntry:vc];
    }
    else if ([segue.identifier isEqualToString:@"segueToPreferences"]) {
        
        
        
        NSLog(@"segueToPreferences");
        [self.searchController.searchBar resignFirstResponder];
        
        UINavigationController* nav = segue.destinationViewController;
        AutoFillPreferencesViewController* vc = (AutoFillPreferencesViewController*)nav.topViewController;
        vc.viewModel = sender;
    }
    else {
        NSLog(@"Unknown SEGUE!");
    }
}

- (void)addNewEntry:(ItemDetailsViewController*)vc {
    NSString* suggestedTitle = nil;
    NSString* suggestedUrl = nil;
    NSString* suggestedNotes = nil;
    
    NSArray<ASCredentialServiceIdentifier *> *serviceIdentifiers = [self.rootViewController getCredentialServiceIdentifiers];

    if (AppPreferences.sharedInstance.storeAutoFillServiceIdentifiersInNotes) {
        suggestedNotes = [[serviceIdentifiers map:^id _Nonnull(ASCredentialServiceIdentifier * _Nonnull obj, NSUInteger idx) {
            return obj.identifier;
        }] componentsJoinedByString:@"\n\n"];
    }
    
    ASCredentialServiceIdentifier *serviceId = [serviceIdentifiers firstObject];
    if(serviceId) {
        if(serviceId.type == ASCredentialServiceIdentifierTypeURL) {
            NSURL* url = serviceId.identifier.urlExtendedParse;
            if(url && url.host.length) {
                NSString* bar = getDomain(url.host);
                NSString* foo = getCompanyOrOrganisationNameFromDomain(bar);
                suggestedTitle = foo.length ? [foo capitalizedString] : foo;
                
                if (AppPreferences.sharedInstance.useFullUrlAsURLSuggestion) {
                    suggestedUrl = url.absoluteString;
                }
                else {
                    suggestedUrl = [[url.scheme stringByAppendingString:@":
                }
            }
        }
        else if (serviceId.type == ASCredentialServiceIdentifierTypeDomain) {
            NSString* bar = getDomain(serviceId.identifier);
            NSString* foo = getCompanyOrOrganisationNameFromDomain(bar);
            suggestedTitle = foo.length ? [foo capitalizedString] : foo;
            suggestedUrl = serviceId.identifier;
        }
    }

    vc.createNewItem = YES;
    vc.itemId = nil;
    vc.parentGroupId = self.model.database.effectiveRootGroup.uuid;
    vc.forcedReadOnly = NO;
    vc.databaseModel = self.model;
    vc.autoFillSuggestedUrl = suggestedUrl;
    vc.autoFillSuggestedTitle = suggestedTitle;
    vc.autoFillSuggestedNotes = suggestedNotes;
        
    vc.onAutoFillNewItemAdded = ^(NSString * _Nonnull username, NSString * _Nonnull password) {
        [self notifyUserToSwitchToAppAfterUpdate:username password:password];
    };
}

- (void)notifyUserToSwitchToAppAfterUpdate:(NSString*)username password:(NSString*)password {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.model.metadata.storageProvider != kLocalDevice && !AppPreferences.sharedInstance.dontNotifyToSwitchToMainAppForSync) {
            NSString* title = NSLocalizedString(@"autofill_add_entry_sync_required_title", @"Sync Required");
            NSString* locMessage = NSLocalizedString(@"autofill_add_entry_sync_required_message_fmt",@"You have added a new entry and this change has been saved locally.\n\nDon't forget to switch to the main Strongbox app to fully sync these changes to %@.");
            NSString* gotIt = NSLocalizedString(@"autofill_add_entry_sync_required_option_got_it",@"Got it!");
            NSString* gotItDontTellMeAgain = NSLocalizedString(@"autofill_add_entry_sync_required_option_dont_tell_again",@"Don't tell me again");
            
            NSString* storageName = [SafeStorageProviderFactory getStorageDisplayName:self.model.metadata];
            NSString* message = [NSString stringWithFormat:locMessage, storageName];
            
            [Alerts twoOptions:self title:title message:message defaultButtonText:gotIt secondButtonText:gotItDontTellMeAgain action:^(BOOL response) {
                if (response == NO) {
                    AppPreferences.sharedInstance.dontNotifyToSwitchToMainAppForSync = YES;
                }
                
                [self.rootViewController exitWithCredential:self.model.metadata user:username password:password];
            }];
        }
        else {
            [self.rootViewController exitWithCredential:self.model.metadata user:username password:password];
        }
    });
}

- (BOOL)canCreateNewCredential {
    return !self.model.isReadOnly;
}




























@end
