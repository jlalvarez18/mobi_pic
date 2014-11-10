//
//  PhotoDetailsViewController.m
//  MobiPic
//
//  Created by Juan Alvarez on 11/9/14.
//  Copyright (c) 2014 Alvarez Productions. All rights reserved.
//

#import "PhotoDetailsViewController.h"

#import <Dropbox/Dropbox.h>
#import <MHVideoPhotoGallery/MHGallery.h>

#import "PhotoImageCell.h"
#import "LabelCollectionViewCell.h"

#import "PhotoModel.h"
#import "ImageCellViewModel.h"

#import "DataManager.h"

@interface PhotoDetailsViewController () <UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) DBPath *path;
@property (nonatomic, strong) DBFile *file;
@property (nonatomic, strong) PhotoModel *model;

@end

@implementation PhotoDetailsViewController

static NSString * const reuseIdentifier = @"Cell";

- (instancetype)initWithPath:(DBPath *)path
{
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];

    self = [super initWithCollectionViewLayout:layout];
    
    self.path = path;
    self.hidesBottomBarWhenPushed = YES;
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(sharePhoto:)];
    
    self.collectionView.backgroundColor = [UIColor whiteColor];
    self.collectionView.alwaysBounceVertical = YES;
    
    [self.collectionView registerNib:[UINib nibWithNibName:NSStringFromClass([PhotoImageCell class]) bundle:nil] forCellWithReuseIdentifier:PhotoImageCellIdentifier];
    [self.collectionView registerNib:[UINib nibWithNibName:NSStringFromClass([LabelCollectionViewCell class]) bundle:nil] forCellWithReuseIdentifier:LabelCollectionViewCellIdentifier];
    
    self.file = [[DBFilesystem sharedFilesystem] openFile:self.path error:nil];
    self.model = [[DataManager sharedInstance] modelForPath:self.path];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

#pragma mark - Action Methods

- (void)sharePhoto:(id)sender
{
    UIImage *image = [UIImage imageWithData:[self.file readData:nil]];
    
    if (image) {
        UIActivityViewController *shareController = [[UIActivityViewController alloc] initWithActivityItems:@[image] applicationActivities:nil];
        
        [self presentViewController:shareController animated:YES completion:nil];
    }
}

#pragma mark UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 3;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        // the image cell
        
        ImageCellViewModel *viewModel = [[ImageCellViewModel alloc] initWithDBFile:self.file];
        
        PhotoImageCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:PhotoImageCellIdentifier forIndexPath:indexPath];
        
        cell.image = viewModel.image;
        cell.progress = viewModel.progress;
        
        return cell;
    }
    
    else if (indexPath.row == 1) {
        // location cell
        
        LabelCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:LabelCollectionViewCellIdentifier forIndexPath:indexPath];
        
        cell.placeholder = @"Location not available";
        cell.text = self.model.city;
        cell.iconImage = [UIImage imageNamed:@"Map_Pin"];

        return cell;
    }
    
    else if (indexPath.row == 2) {
        // description cell
        
        LabelCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:LabelCollectionViewCellIdentifier forIndexPath:indexPath];
        
        cell.placeholder = @"Enter description";
        cell.text = self.model.descriptionText;
        cell.iconImage = [UIImage imageNamed:@"Info"];
        
        return cell;
    }
    
    return nil;
}

#pragma mark -
#pragma mark UICollectionViewDelegate Methods

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    
    if (indexPath.row == 0) {
        // the image cell
        
        // only present the image if it is cached and ready to roll
        if (self.file.status.cached) {
            PhotoImageCell *cell = (PhotoImageCell *)[collectionView cellForItemAtIndexPath:indexPath];
            
            ImageCellViewModel *viewModel = [[ImageCellViewModel alloc] initWithDBFile:self.file];
            MHGalleryItem *item = [MHGalleryItem itemWithImage:viewModel.image];
            
            MHGalleryController *gallery = [MHGalleryController galleryWithPresentationStyle:MHGalleryViewModeImageViewerNavigationBarHidden];
            gallery.galleryItems = @[item];
            gallery.presentingFromImageView = cell.imageView;
            gallery.presentationIndex = indexPath.row;
            
            MHUICustomization *customization = gallery.UICustomization;
            customization.showOverView = NO;
            customization.hideShare = YES;
            
            __weak typeof(self) weakSelf = self;
            __weak MHGalleryController *weakGallery = gallery;
            
            gallery.finishedCallback = ^(NSUInteger currentIndex, UIImage *image, MHTransitionDismissMHGallery *interactiveTransition, MHGalleryViewMode viewMode) {
                NSIndexPath *newIndexPath = [NSIndexPath indexPathForItem:currentIndex inSection:0];
                
                [weakSelf.collectionView scrollToItemAtIndexPath:newIndexPath atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    // this makes sure the collectionView is ready to provide the new cell if it scrolled to a new position
                    [weakSelf.collectionView layoutIfNeeded];
                    
                    PhotoImageCell *newCell = (PhotoImageCell *)[weakSelf.collectionView cellForItemAtIndexPath:newIndexPath];
                    
                    [weakGallery dismissViewControllerAnimated:YES dismissImageView:newCell.imageView completion:nil];
                });
            };
            
            [self presentMHGalleryController:gallery animated:YES completion:nil];
        }
    }
}

#pragma mark -
#pragma mark UICollectionViewDelegateFlowLayout Methods

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat width = CGRectGetWidth(self.view.bounds);
    
    if (indexPath.row == 0) {
        return CGSizeMake(width, 200);
    }
    
    else {
        // location/description cell
        return CGSizeMake(width, 44);
    }
}

#pragma mark -
#pragma mark Accessor Methods

- (void)setFile:(DBFile *)file
{
    _file = file;
    
    __weak typeof(self) weakSelf = self;
    [_file addObserver:self block:^{
        // update photo progress
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
        [weakSelf.collectionView reloadItemsAtIndexPaths:@[indexPath]];
    }];
    
    if (_file.newerStatus.cached) {
        // Update when the newer version of the file is cached
        [self.file update:nil];
    }
}

@end
