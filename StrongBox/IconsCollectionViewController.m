//
//  IconsCollectionViewController.m
//  Strongbox
//
//  Created by Mark on 22/02/2019.
//  Copyright © 2019 Mark McGuill. All rights reserved.
//

#import "IconsCollectionViewController.h"
#import "NodeIconHelper.h"
#import "IconViewCell.h"
#import "Utils.h"
#import "IconsSectionHeaderReusableView.h"

@interface IconsCollectionViewController () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIView *customIconsView;

@end

@implementation IconsCollectionViewController

- (IBAction)onCancel:(id)sender {
    self.onDone(NO, -1, nil);
}

- (IBAction)onUseDefault:(id)sender {
    self.onDone(YES, -1, nil);
}

- (void)viewDidLoad {
    [super viewDidLoad];

    //    self.collectionView.layer.borderWidth = 1.0f;
    //    self.collectionView.layer.cornerRadius = 5;
    //    self.collectionView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;

    [self.collectionView registerNib:[UINib nibWithNibName:@"IconCellView" bundle:nil] forCellWithReuseIdentifier:@"CELL"];
    [self.collectionView registerNib:[UINib nibWithNibName:@"IconsSectionHeaderReusableView" bundle:nil]
          forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                 withReuseIdentifier:@"IconsSectionHeaderReusableView"];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    if (![self hasCustomIcons]) {
        return CGSizeZero;
    }else {
        return CGSizeMake(collectionView.frame.size.width,50);
    }
}

- (BOOL)hasCustomIcons {
    return (self.customIcons && self.customIcons.count);
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return [self hasCustomIcons] ? 2 : 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return ([self hasCustomIcons] && section == 0) ? self.customIcons.count : [NodeIconHelper iconSet].count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if([self hasCustomIcons] && indexPath.section == 0) {
        IconViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CELL" forIndexPath:indexPath];
        NSUUID* uuid = self.customIcons.allKeys[indexPath.row];
        UIImage* image = [NodeIconHelper getCustomIcon:uuid customIcons:self.customIcons];
        
        if(image) {
            cell.imageView.image = image;
        }
        
        return cell;
    }
    else {
        IconViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CELL" forIndexPath:indexPath];
        cell.imageView.image = [NodeIconHelper iconSet][indexPath.item];
        return cell;
    }
}

-(UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind
                                atIndexPath:(NSIndexPath *)indexPath {
    UICollectionReusableView *reusableView = nil;
    
    if (kind == UICollectionElementKindSectionHeader) {
        IconsSectionHeaderReusableView *collectionHeader = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"IconsSectionHeaderReusableView" forIndexPath:indexPath];
        
        collectionHeader.labelTitle.text = ([self hasCustomIcons] && indexPath.section == 0) ?
        NSLocalizedString(@"icons_vc_header_database_icons_title", @"Database Icons") :
        NSLocalizedString(@"icons_vc_header_keepass_icons_title", @"KeePass Icons");
        
        reusableView = collectionHeader;
    }
    else {
        reusableView = [[UICollectionReusableView alloc] init];
    }
    
    return reusableView;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if([self hasCustomIcons] && indexPath.section == 0) {
        NSUUID* uuid = self.customIcons.allKeys[indexPath.row];
        self.onDone(YES, -1L, uuid);
    }
    else {
        self.onDone(YES, indexPath.item, nil);
    }
}

@end
