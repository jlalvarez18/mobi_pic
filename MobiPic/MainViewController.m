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

#import "ImageCollectionViewCell.h"

@interface MainViewController () <UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, strong) DBFilesystem *filesystem;
@property (nonatomic, strong) DBPath *root;

@property (nonatomic, strong) UIImagePickerController *pickerController;

@property (nonatomic, strong) NSMutableOrderedSet *files;

@property (nonatomic) BOOL loadingFiles;
@property (nonatomic) BOOL needToReloadFiles;

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = NSLocalizedString(@"My Photos", nil);
    
    self.files = [NSMutableOrderedSet orderedSet];
    
    [self.collectionView registerClass:[ImageCollectionViewCell class] forCellWithReuseIdentifier:ImageCollectionViewCellIdentifier];
    
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
    
    [self reloadFiles];
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        self.navigationController.toolbarHidden = NO;
    } else {
//        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Camera Missing"
//                                                                       message:@"This app is pretty boring without a camera :("
//                                                                preferredStyle:UIAlertControllerStyleAlert];
//        
//        UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:@"Dismiss"
//                                                                style:UIAlertActionStyleDefault
//                                                              handler:^(UIAlertAction *action) {
//                                                                  [alert dismissViewControllerAnimated:YES completion:nil];
//                                                              }];
//
//        [alert addAction:dismissAction];
//        
//        [self presentViewController:alert animated:YES completion:nil];
    }
}

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
                
                [sortedFileInfos enumerateObjectsUsingBlock:^(DBFileInfo *info, NSUInteger idx, BOOL *stop) {
                    DBFile *file;
                    
                    if (info.thumbExists) {
                        file = [self.filesystem openThumbnail:info.path ofSize:DBThumbSizeL inFormat:DBThumbFormatPNG error:nil];
                    } else {
                        file = [self.filesystem openFile:info.path error:nil];
                    }
                    
                    if (file) {
                        __weak id weakFile = file;
                        __weak id weakSelf = self;
                        
                        [file addObserver:self block:^{
                            [weakSelf reloadCellForFile:weakFile];
                        }];
                        
                        [newFiles addObject:file];
                    }
                }];
                
                self.files = newFiles;
                
                [self.collectionView reloadData];
                
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
    NSInteger index = [self.files indexOfObject:file];
    
    if (index != NSNotFound) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
        
        return indexPath;
    }
    
    return nil;
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
    
    DBFileStatus *fileStatus = file.status;
    DBFileStatus *newerStatus = file.newerStatus;
    
    if (fileStatus.cached) {
        cell.image = [UIImage imageWithData:[file readData:nil]];
    }
    
    float progress = 0.0;
    
    if (fileStatus.state == DBFileStateDownloading || fileStatus.state == DBFileStateUploading) {
        progress = fileStatus.progress;
    } else if (newerStatus && newerStatus.state == DBFileStateDownloading) {
        progress = newerStatus.progress;
    }
    
    cell.progress = progress;
    
    return cell;
}

#pragma mark -
#pragma mark UICollectionViewDelegateFlowLayout Methods

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(320, 320);
}

#pragma mark -
#pragma mark UIImagePickerControllerDelegate Methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
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
        if ([imageFile writeData:imageData error:&error]) {
            [self.filesystem openFile:imagePath error:nil];
            
            [self.files insertObject:imageFile atIndex:0];
            
            [picker dismissViewControllerAnimated:YES completion:^{
                [self reloadCellForFile:imageFile];
            }];
        } else {
            NSLog(@"%@", error);
        }
    }
    
    NSLog(@"%@", info);
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
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
