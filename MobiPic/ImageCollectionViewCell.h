//
//  ImageCollectionViewCell.h
//  MobiPic
//
//  Created by Juan Alvarez on 11/8/14.
//  Copyright (c) 2014 Alvarez Productions. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString *ImageCollectionViewCellIdentifier;

@interface ImageCollectionViewCell : UICollectionViewCell

@property (nonatomic) UIImage *image;
@property (nonatomic) float progress;

@end
