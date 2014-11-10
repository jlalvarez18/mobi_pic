//
//  PhotoImageCell.h
//  MobiPic
//
//  Created by Juan Alvarez on 11/9/14.
//  Copyright (c) 2014 Alvarez Productions. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString *const PhotoImageCellIdentifier;

@interface PhotoImageCell : UICollectionViewCell

@property (nonatomic) UIImage *image;
@property (nonatomic) float progress;

@property (weak, nonatomic, readonly) UIImageView *imageView;

@end
