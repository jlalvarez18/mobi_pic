//
//  ImageCollectionViewCell.m
//  MobiPic
//
//  Created by Juan Alvarez on 11/8/14.
//  Copyright (c) 2014 Alvarez Productions. All rights reserved.
//

#import "ThumbnailCollectionViewCell.h"

NSString *ThumbnailCollectionViewCellIdentifier = @"ThumbnailCollectionViewCellIdentifier";

@interface ThumbnailCollectionViewCell ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation ThumbnailCollectionViewCell

- (void)prepareForReuse
{
    self.imageView.image = nil;
}

#pragma mark -
#pragma mark Accessor Methods

- (void)setImage:(UIImage *)image
{
    self.imageView.image = image;
}


@end
