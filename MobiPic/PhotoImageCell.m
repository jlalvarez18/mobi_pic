//
//  PhotoImageCell.m
//  MobiPic
//
//  Created by Juan Alvarez on 11/9/14.
//  Copyright (c) 2014 Alvarez Productions. All rights reserved.
//

#import "PhotoImageCell.h"

#import <UAProgressView/UAProgressView.h>

NSString *const PhotoImageCellIdentifier = @"PhotoImageCell";

@interface PhotoImageCell ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UAProgressView *progressView;

@end

@implementation PhotoImageCell

- (void)prepareForReuse
{
    self.imageView.image = nil;
    
    self.progressView.hidden = NO;
    self.progressView.progress = 0.0;
}

#pragma mark -
#pragma mark Accessor Methods

- (void)setImage:(UIImage *)image
{
    self.imageView.image = image;
}

- (void)setProgress:(float)progress
{
    if (progress > 0 && progress < 1) {
        self.progressView.hidden = NO;
        [self.progressView setProgress:progress animated:YES];
    } else {
        self.progressView.hidden = YES;
    }
}

@end
