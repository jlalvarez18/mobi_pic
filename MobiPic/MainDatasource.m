//
//  MainDatasource.m
//  MobiPic
//
//  Created by Juan Alvarez on 11/10/14.
//  Copyright (c) 2014 Alvarez Productions. All rights reserved.
//

#import "MainDatasource.h"

#import <Dropbox/Dropbox.h>

#import "ThumbnailCollectionViewCell.h"
#import "ImageCellViewModel.h"

@interface MainDatasource () <UICollectionViewDataSource>

@property (nonatomic, weak) UICollectionView *collectionView;

@property (nonatomic, readonly) DBFilesystem *filesystem;
@property (nonatomic, readonly) DBPath *root;

@property (nonatomic, strong) NSMutableOrderedSet *files;
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
        
        self.files = [NSMutableOrderedSet orderedSet];
        self.fileCache = [NSMutableDictionary dictionary];
        
        __weak id weakself = self;
        [self.filesystem addObserver:self forPathAndChildren:self.root block:^{
            [weakself reload];
        }];
    }
    
    return self;
}

#pragma mark -
#pragma mark UICollectionViewDatasource Methods

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.files.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ThumbnailCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:ThumbnailCollectionViewCellIdentifier forIndexPath:indexPath];
    
    DBFile *file = self.files[indexPath.row];
    
    ImageCellViewModel *viewModel = [[ImageCellViewModel alloc] initWithDBFile:file];
    
    cell.image = viewModel.image;
    
    return cell;
}

#pragma mark -
#pragma mark Public Methods

- (void)reload
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
                        
                        if (!file || error) {
                            NSLog(@"%@", error);
                        } else {
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
                    [self reload];
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

- (DBFile *)fileAtIndexPath:(NSIndexPath *)indexPath
{
    return self.files[indexPath.row];
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