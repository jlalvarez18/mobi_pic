//
//  MainDatasource.m
//  MobiPic
//
//  Created by Juan Alvarez on 11/10/14.
//  Copyright (c) 2014 Alvarez Productions. All rights reserved.
//

#import "MainDatasource.h"

#import <Dropbox/Dropbox.h>
#import <BlocksKit/BlocksKit.h>

#import "ThumbnailCollectionViewCell.h"
#import "ImageCellViewModel.h"

#import "DataManager.h"
#import "PhotoModel.h"

static DBThumbSize DefaultThumbSize = DBThumbSizeL;

@interface MainDatasource () <UICollectionViewDataSource>

@property (nonatomic, weak) UICollectionView *collectionView;

@property (nonatomic, readonly) DBFilesystem *filesystem;
@property (nonatomic, readonly) DBPath *root;
@property (nonatomic, readonly) DBDatastore *datastore;

@property (nonatomic, strong) NSMutableArray *items;
@property (nonatomic, strong) NSMutableDictionary *fileCache;

@property (nonatomic) BOOL loadingFiles;
@property (nonatomic) BOOL needToReloadFiles;

@end

@implementation MainDatasource

- (instancetype)initWithCollectionView:(UICollectionView *)collectionView
{
    self = [super init];
    
    if (self) {
        self.collectionView = collectionView;
        self.collectionView.dataSource = self;
        
        [self.collectionView registerNib:[UINib nibWithNibName:@"ThumbnailCollectionViewCell" bundle:nil]
              forCellWithReuseIdentifier:ThumbnailCollectionViewCellIdentifier];
        
        self.items = [NSMutableArray array];
        self.fileCache = [NSMutableDictionary dictionary];
        
        __weak id weakself = self;
        [[DataManager sharedInstance].datastore addObserver:self block:^{
            [weakself reloadData];
        }];
    }
    
    return self;
}

- (void)reloadData
{
    DBAccount *account = [[DBAccountManager sharedManager] linkedAccount];
    
    if (account) {
        self.needToReloadFiles = YES;
        
        if (self.loadingFiles) {
            // Currently loading files
            return;
        }
        
        self.loadingFiles = YES;
        
        [[DataManager sharedInstance] getAllPhotoModels:^(NSArray *results, NSError *error) {
            self.needToReloadFiles = NO;
            
            NSSortDescriptor *sortDesc = [[NSSortDescriptor alloc] initWithKey:@"modifiedDate" ascending:NO];
            NSArray *sortedModels = [results sortedArrayUsingDescriptors:@[sortDesc]];
            
            NSMutableArray *newItems = [NSMutableArray array];
            NSMutableDictionary *newFileCache = [NSMutableDictionary dictionary];
            NSMutableArray *addedItems = [NSMutableArray array];
            
            [sortedModels enumerateObjectsUsingBlock:^(PhotoModel *model, NSUInteger idx, BOOL *stop) {
                DBPath *path = model.path;
                
                NSString *fileName = path.name;
                
                DBFile *file = self.fileCache[fileName];
                
                if (file) {
                    // this file has been previously opened
                    
                    newFileCache[fileName] = file;
                    
                    [self.items removeObject:model];
                    [newItems addObject:model];
                } else {
                    // this file is new since we last did a reload
                    
                    DBError *error;
                    file = [model thumbnailFileForSize:DefaultThumbSize error:&error];
                    
                    if (!file || error) {
                        NSLog(@"%@", error);
                    } else {
                        __weak DBFile *weakFile = file;
                        __weak typeof(self) weakSelf = self;
                        
                        [file addObserver:self block:^{
                            DBError *error;
                            if ([weakFile update:&error]) {
                                [weakSelf reloadCellForItem:model];
                            } else if ([error dbErrorCode] == DBErrorNotFound) {
                                // deleted!
                                [[DataManager sharedInstance] deletePhoto:model];
                            } else {
                                NSLog(@"%@", error);
                            }
                        }];
                        
                        newFileCache[fileName] = file;
                        
                        [newItems addObject:model];
                        [addedItems addObject:model];
                    }
                }
            }];
            
            // any of the remaining files have been deleted since we last reloaded
            NSArray *indexPathsToDelete = [self.items bk_map:^NSIndexPath *(PhotoModel *item) {
                return [self indexPathForItem:item];
            }];
            
            self.items = newItems;
            self.fileCache = newFileCache;
            
            // items that have been added since we last reloaded
            NSArray *indexPathsToAdd = [addedItems bk_map:^NSIndexPath *(PhotoModel *item) {
                return [self indexPathForItem:item];
            }];
            
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
                [self reloadData];
            }
        }];
    }
}

#pragma mark -
#pragma mark UICollectionViewDatasource Methods

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.items.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ThumbnailCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:ThumbnailCollectionViewCellIdentifier forIndexPath:indexPath];
    
    PhotoModel *model = self.items[indexPath.row];
    
    ImageCellViewModel *viewModel = [[ImageCellViewModel alloc] initWithDBFile:[model thumbnailFileForSize:DefaultThumbSize error:nil]];
    
    cell.image = viewModel.image;
    
    return cell;
}

#pragma mark -
#pragma mark Public Methods

//- (void)reload
//{
//    DBAccount *account = [[DBAccountManager sharedManager] linkedAccount];
//    
//    if (account) {
//        self.needToReloadFiles = YES;
//        
//        if (self.loadingFiles) {
//            // Currently loading files
//            return;
//        }
//        
//        self.loadingFiles = YES;
//        
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//            self.needToReloadFiles = NO;
//            
//            NSArray *infos = [self.filesystem listFolder:self.root error:nil];
//            
//            NSSortDescriptor *sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"modifiedTime" ascending:NO];
//            NSArray *sortedFileInfos = [infos sortedArrayUsingDescriptors:@[sortDesc]];
//            
//            dispatch_async(dispatch_get_main_queue(), ^{
//                NSMutableOrderedSet *newFiles = [NSMutableOrderedSet orderedSet];
//                NSMutableDictionary *newFileCache = [NSMutableDictionary dictionary];
//                
//                NSMutableArray *addedFiles = [NSMutableArray array];
//                
//                [sortedFileInfos enumerateObjectsUsingBlock:^(DBFileInfo *info, NSUInteger idx, BOOL *stop) {
//                    NSString *filename = info.path.name;
//                    DBFile *previouslyOpenedFile = self.fileCache[filename];
//                    
//                    if (previouslyOpenedFile) {
//                        // this file has been opened already
//                        
//                        newFileCache[filename] = previouslyOpenedFile;
//                        
//                        [self.files removeObject:previouslyOpenedFile];
//                        
//                        [newFiles addObject:previouslyOpenedFile];
//                    } else {
//                        // this file is new since we last did a reload
//                        
//                        DBError *error;
//                        DBFile *file = [self.filesystem openThumbnail:info.path
//                                                               ofSize:DBThumbSizeL
//                                                             inFormat:DBThumbFormatJPG
//                                                                error:&error];
//                        
//                        if (!file || error) {
//                            NSLog(@"%@", error);
//                        } else {
//                            newFileCache[filename] = file;
//                            
//                            __weak DBFile *weakFile = file;
//                            __weak typeof(self) weakSelf = self;
//                            
//                            [file addObserver:self block:^{
//                                DBError *error;
//                                if ([weakFile update:&error]) {
//                                    [weakSelf reloadCellForFile:weakFile];
//                                } else if ([error dbErrorCode] == DBErrorNotFound) {
//                                    // deleted!
//                                }
//                            }];
//                            
//                            [newFiles addObject:file];
//                            
//                            [addedFiles addObject:file];
//                        }
//                    }
//                }];
//                
//                NSMutableArray *indexPathsToDelete = [NSMutableArray array];
//                
//                // any of the remaining files have been deleted since we last reloaded
//                [self.files enumerateObjectsUsingBlock:^(DBFile *file, NSUInteger idx, BOOL *stop) {
//                    [indexPathsToDelete addObject:[self indexPathForFile:file]];
//                    
//                    [file removeObserver:self];
//                }];
//                
//                // set the new ordered set of files
//                self.files = newFiles;
//                self.fileCache = newFileCache;
//                
//                NSMutableArray *indexPathsToAdd = [NSMutableArray array];
//                
//                [addedFiles enumerateObjectsUsingBlock:^(DBFile *file, NSUInteger idx, BOOL *stop) {
//                    [indexPathsToAdd addObject:[self indexPathForFile:file]];
//                }];
//                
//                self.files = newFiles;
//                
//                NSInteger addedCount = indexPathsToAdd.count;
//                NSInteger removedCount = indexPathsToDelete.count;
//                
//                // we want to make sure we only perform batch updates if we have to
//                if (addedCount > 0 || removedCount > 0) {
//                    [self.collectionView performBatchUpdates:^{
//                        if (addedCount > 0) {
//                            [self.collectionView insertItemsAtIndexPaths:indexPathsToAdd];
//                        }
//                        
//                        if (removedCount > 0) {
//                            [self.collectionView deleteItemsAtIndexPaths:indexPathsToDelete];
//                        }
//                    } completion:nil];
//                }
//                
//                self.loadingFiles = NO;
//                
//                if (self.needToReloadFiles) {
//                    // this means that the reloadFiles method was called while loading
//                    // so lets reload just in case
//                    [self reload];
//                }
//            });
//        });
//    }
//}

// Reloads the cell for the provided file
// Updates can be to reflect progress in upload, download or update
// or to change the image visible in a cell once an update or download is complete
- (void)reloadCellForItem:(PhotoModel *)item
{
    if (!item) {
        return;
    }
    
    NSIndexPath *indexPath = [self indexPathForItem:item];
    
    DBFile *file = [item thumbnailFileForSize:DefaultThumbSize error:nil];
    
    if (!file || ![file isOpen] || !indexPath) {
        return;
    }
    
    if (file.newerStatus.cached) {
        // Update when the newer version of the file is cached
        [file update:nil];
    }
    
    [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
}

- (NSIndexPath *)indexPathForItem:(PhotoModel *)item
{
    // since the files are sorted by modifiedTime we are able to perform a binary search to increase performance
//    NSInteger index = [self.items indexOfObject:item
//                                  inSortedRange:NSMakeRange(0, self.items.count)
//                                        options:NSBinarySearchingFirstEqual
//                                usingComparator:^NSComparisonResult(PhotoModel *obj1, PhotoModel *obj2) {
//                                    if ([obj1.path.stringValue isEqualToString:obj2.path.stringValue]) {
//                                        return NSOrderedSame;
//                                    }
//                                    
//                                    NSDate *date1 = obj1.modifiedDate;
//                                    NSDate *date2 = obj2.modifiedDate;
//                                    
//                                    return [date2 compare:date1];
//                                }];

    NSInteger index = [self.items indexOfObject:item];
    
    if (index != NSNotFound) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
        
        return indexPath;
    }
    
    return nil;
}

- (DBFile *)fileAtIndexPath:(NSIndexPath *)indexPath
{
    PhotoModel *model = self.items[indexPath.row];
    
    return [model thumbnailFileForSize:DefaultThumbSize error:nil];
}

#pragma mark -
#pragma mark Accessor Methods

- (DBFilesystem *)filesystem
{
    return [DBFilesystem sharedFilesystem];
}

- (DBPath *)root
{
    return [DBPath root];
}

@end
