//
//  PhotoDetailsViewController.h
//  MobiPic
//
//  Created by Juan Alvarez on 11/9/14.
//  Copyright (c) 2014 Alvarez Productions. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DBPath;

@interface PhotoDetailsViewController : UICollectionViewController

- (instancetype)initWithPath:(DBPath *)path;

@end
