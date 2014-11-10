//
//  MainDatasource.h
//  MobiPic
//
//  Created by Juan Alvarez on 11/10/14.
//  Copyright (c) 2014 Alvarez Productions. All rights reserved.
//

@import UIKit;

@class DBFile;

@interface MainDatasource : NSObject

- (instancetype)initWithCollectionView:(UICollectionView *)collectionView;

- (void)reload;

- (DBFile *)fileAtIndexPath:(NSIndexPath *)indexPath;

@end
