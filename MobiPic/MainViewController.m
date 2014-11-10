//
//  ViewController.m
//  MobiPic
//
//  Created by Juan Alvarez on 11/8/14.
//  Copyright (c) 2014 Alvarez Productions. All rights reserved.
//

#import "MainViewController.h"

#import <Dropbox/Dropbox.h>
#import <UIImage-Resize/UIImage+Resize.h>
#import <MHVideoPhotoGallery/MHGallery.h>
#import <INTULocationManager/INTULocationManager.h>
#import <SVProgressHUD/SVProgressHUD.h>

#import "ImageCollectionViewCell.h"
#import "ImageCellViewModel.h"

#import "DataManager.h"
#import "PhotoModel.h"

@interface MainViewController () <UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate, MHGalleryDataSource>

@property (nonatomic, strong) DBFilesystem *filesystem;
@property (nonatomic, strong) DBPath *root;

@property (nonatomic, strong) UIImagePickerController *pickerController;

@property (nonatomic, strong) NSMutableOrderedSet *files;
@property (nonatomic, strong) NSMutableDictionary *fileCache;

@property (nonatomic, strong) CLLocation *location;
@property (nonatomic, strong) CLGeocoder *geocoder;
@property (nonatomic, strong) NSString *cityLocation;

@property (nonatomic) BOOL loadingFiles;
@property (nonatomic) BOOL needToReloadFiles;
@property (nonatomic) BOOL viewAppeared;

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = NSLocalizedString(@"My Photos", nil);
    
    self.files = [NSMutableOrderedSet orderedSet];
    self.fileCache = [NSMutableDictionary dictionary];
    self.geocoder = [[CLGeocoder alloc] init];
    
    [self.collectionView registerNib:[UINib nibWithNibName:@"ImageCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:ImageCollectionViewCellIdentifier];
    
    __weak id weakself = self;
    [self.filesystem addObserver:self forPathAndChildren:self.root block:^{
        [weakself reloadFiles];
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    DBAccount *account = [[DBAccountManager sharedManager] linkedAccount];
    
    if (account) {
        if (!self.viewAppeared) {
            // we only want to call this once when view appears
            [self reloadFiles];
            
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Camera Missing"
                                                                           message:@"This app is pretty boring without a camera :("
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [alert dismissViewControllerAnimated:YES completion:nil];
            }];
            
            [alert addAction:dismissAction];
            
            [self presentViewController:alert animated:YES completion:nil];
            
            self.viewAppeared = YES;
        }
        
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            self.navigationController.toolbarHidden = NO;
            
            [[INTULocationManager sharedInstance] requestLocationWithDesiredAccuracy:INTULocationAccuracyCity timeout:5.0 block:^(CLLocation *currentLocation, INTULocationAccuracy achievedAccuracy, INTULocationStatus status) {
                 if (status == INTULocationStatusSuccess || status == INTULocationStatusTimedOut) {
                     NSLog(@"%@", currentLocation);
                     
                     self.location = currentLocation;
                     
                     [self.geocoder reverseGeocodeLocation:self.location completionHandler:^(NSArray *placemarks, NSError *error) {
                         CLPlacemark *placemark = placemarks.firstObject;
                         
                         if (placemark) {
                             self.cityLocation = placemark.locality;
                         }
                     }];
                 }
             }];
        }
    }
}

#pragma mark -
#pragma mark Action Methods

- (IBAction)takePicture:(id)sender
{
    [self presentViewController:self.pickerController animated:YES completion:nil];
}

#pragma mark -
#pragma mark UICollectionViewDatasource Methods

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.files.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ImageCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:ImageCollectionViewCellIdentifier forIndexPath:indexPath];
    
    DBFile *file = self.files[indexPath.row];
    
    ImageCellViewModel *viewModel = [[ImageCellViewModel alloc] initWithDBFile:file];
    
    cell.image = viewModel.image;
    cell.progress = viewModel.progress;
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    
    DBFile *file = self.files[indexPath.row];
    
    // only present the image if it is cached and ready to roll
    if (file.status.cached) {
        ImageCollectionViewCell *cell = (ImageCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
        
        MHGalleryController *gallery = [MHGalleryController galleryWithPresentationStyle:MHGalleryViewModeImageViewerNavigationBarHidden];
        gallery.dataSource = self;
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
                
                ImageCollectionViewCell *newCell = (ImageCollectionViewCell *)[weakSelf.collectionView cellForItemAtIndexPath:newIndexPath];
                
                [weakGallery dismissViewControllerAnimated:YES dismissImageView:newCell.imageView completion:nil];
            });
        };
        
        [self presentMHGalleryController:gallery animated:YES completion:nil];
    }
}

#pragma mark -
#pragma mark MHGalleryDataSource Methods

- (NSInteger)numberOfItemsInGallery:(MHGalleryController *)galleryController
{
    return self.files.count;
}

- (MHGalleryItem *)itemForIndex:(NSInteger)index
{
    DBFile *file = self.files[index];
    ImageCellViewModel *viewModel = [[ImageCellViewModel alloc] initWithDBFile:file];
    
    MHGalleryItem *item = [MHGalleryItem itemWithImage:viewModel.image];
    
    return item;
}

#pragma mark -
#pragma mark UIImagePickerControllerDelegate Methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSLog(@"%@", info);
    
    // resize and compress image to save on size :)
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    UIImage *resizedImage = [image resizedImageToFitInSize:CGSizeMake(640, 640) scaleIfSmaller:NO];
    
    NSData *imageData = UIImageJPEGRepresentation(resizedImage, 0.7);
    
    NSString *imageId = [NSUUID UUID].UUIDString;
    NSString *imageName = [imageId stringByAppendingPathExtension:@"jpg"];
    
    NSError *error;
    DBPath *imagePath = [[DBPath root] childPath:imageName];
    DBFile *imageFile = [[DBFilesystem sharedFilesystem] createFile:imagePath error:&error];
    
    if (error) {
        NSLog(@"%@", error);
    } else {
        [SVProgressHUD show];
        
        if ([imageFile writeData:imageData error:&error]) {
            PhotoModel *model = [PhotoModel new];
            model.path = imagePath;
            model.city = self.cityLocation;
            model.location = self.location;
            
            [[DataManager sharedInstance] savePhoto:model];
            
            [SVProgressHUD dismiss];
            
            [picker dismissViewControllerAnimated:YES completion:^{
                // the file system observer block will get called
                // so no need to manually call reloadFiles
            }];
        } else {
            NSLog(@"%@", error);
        }
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -
#pragma mark Private Methods

- (void)reloadFiles
{
    DBAccount *account = [[DBAccountManager sharedManager] linkedAccount];
    
    if (account) {
        self.needToReloadFiles = YES;
        
        if (self.loadingFiles) {
            // Currently loading files
            return;
        }
        
        self.loadingFiles = YES;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            self.needToReloadFiles = NO;
            
            NSArray *infos = [self.filesystem listFolder:self.root error:nil];
            
            NSSortDescriptor *sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"modifiedTime" ascending:NO];
            NSArray *sortedFileInfos = [infos sortedArrayUsingDescriptors:@[sortDesc]];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                NSMutableOrderedSet *newFiles = [NSMutableOrderedSet orderedSet];
                NSMutableDictionary *newFileCache = [NSMutableDictionary dictionary];
                
                NSMutableArray *addedFiles = [NSMutableArray array];
                
                [sortedFileInfos enumerateObjectsUsingBlock:^(DBFileInfo *info, NSUInteger idx, BOOL *stop) {
                    NSString *filename = info.path.name;
                    DBFile *previouslyOpenedFile = self.fileCache[filename];
                    
                    if (previouslyOpenedFile) {
                        // this file has been opened already
                        
                        newFileCache[filename] = previouslyOpenedFile;
                        
                        [self.files removeObject:previouslyOpenedFile];
                        
                        [newFiles addObject:previouslyOpenedFile];
                    } else {
                        // this file is new since we last did a reload
                        
                        DBError *error;
                        DBFile *file = [self.filesystem openThumbnail:info.path
                                                               ofSize:DBThumbSizeL
                                                             inFormat:DBThumbFormatJPG
                                                                error:&error];
                        
                        if (error) {
                            NSLog(@"%@", error);
                        }
                        
                        newFileCache[filename] = file;
                        
                        __weak DBFile *weakFile = file;
                        __weak typeof(self) weakSelf = self;
                        
                        [file addObserver:self block:^{
                            DBError *error;
                            if ([weakFile update:&error]) {
                                [weakSelf reloadCellForFile:weakFile];
                            } else if ([error dbErrorCode] == DBErrorNotFound) {
                                // deleted!
                            }
                        }];
                        
                        [newFiles addObject:file];
                        
                        [addedFiles addObject:file];
                    }
                }];
                
                NSMutableArray *indexPathsToDelete = [NSMutableArray array];
                
                // any of the remaining files have been deleted since we last reloaded
                [self.files enumerateObjectsUsingBlock:^(DBFile *file, NSUInteger idx, BOOL *stop) {
                    [indexPathsToDelete addObject:[self indexPathForFile:file]];
                    
                    [file removeObserver:self];
                }];
                
                // set the new ordered set of files
                self.files = newFiles;
                self.fileCache = newFileCache;
                
                NSMutableArray *indexPathsToAdd = [NSMutableArray array];
                
                [addedFiles enumerateObjectsUsingBlock:^(DBFile *file, NSUInteger idx, BOOL *stop) {
                    [indexPathsToAdd addObject:[self indexPathForFile:file]];
                }];
                
                self.files = newFiles;
                
                NSInteger addedCount = indexPathsToAdd.count;
                NSInteger removedCount = indexPathsToDelete.count;
                
                // we want to make sure we only perform batch updates if we have to
                if (addedCount > 0 || removedCount > 0) {
                    [self.collectionView performBatchUpdates:^{
                        if (addedCount > 0) {
                            [self.collectionView insertItemsAtIndexPaths:indexPathsToAdd];
                        }
                        
                        if (removedCount > 0) {
                            [self.collectionView deleteItemsAtIndexPaths:indexPathsToDelete];
                        }
                    } completion:nil];
                }
                
                self.loadingFiles = NO;
                
                if (self.needToReloadFiles) {
                    // this means that the reloadFiles method was called while loading
                    // so lets reload just in case
                    [self reloadFiles];
                }
            });
        });
    }
}

// Reloads the cell for the provided file
// Updates can be to reflect progress in upload, download or update
// or to change the image visible in a cell once an update or download is complete
- (void)reloadCellForFile:(DBFile *)file
{
    NSIndexPath *indexPath = [self indexPathForFile:file];
    
    if (!file || ![file isOpen] || !indexPath) {
        return;
    }
    
    if (file.newerStatus.cached) {
        // Update when the newer version of the file is cached
        [file update:nil];
    }
    
    [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
}

- (NSIndexPath *)indexPathForFile:(DBFile *)file
{
    // since the files are sorted by modifiedTime we are able to perform a binary search to increase performance
    NSInteger index = [self.files indexOfObject:file
                                  inSortedRange:NSMakeRange(0, self.files.count)
                                        options:NSBinarySearchingFirstEqual
                                usingComparator:^NSComparisonResult(DBFile *obj1, DBFile *obj2) {
                                    NSDate *date1 = obj1.info.modifiedTime;
                                    NSDate *date2 = obj2.info.modifiedTime;
                                    
                                    return [date2 compare:date1];
                                }];
    
    if (index != NSNotFound) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
        
        return indexPath;
    }
    
    return nil;
}

#pragma mark -
#pragma mark Accessor Methods

- (UIImagePickerController *)pickerController
{
    if (_pickerController) {
        return _pickerController;
    }
    
    _pickerController = [[UIImagePickerController alloc] init];
    _pickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
    _pickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    _pickerController.delegate = self;
    
    return _pickerController;
}

- (DBFilesystem *)filesystem
{
    if (_filesystem) {
        return _filesystem;
    }
    
    _filesystem = [DBFilesystem sharedFilesystem];
    
    return _filesystem;
}

- (DBPath *)root
{
    if (_root) {
        return _root;
    }
    
    _root = [DBPath root];
    
    return _root;
}

@end
