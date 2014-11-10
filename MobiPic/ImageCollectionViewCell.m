//
//  ImageCollectionViewCell.m
//  MobiPic
//
//  Created by Juan Alvarez on 11/8/14.
//  Copyright (c) 2014 Alvarez Productions. All rights reserved.
//

#import "ImageCollectionViewCell.h"

#import <PureLayout/PureLayout.h>
#import <UAProgressView/UAProgressView.h>

NSString *ImageCollectionViewCellIdentifier = @"ImageCollectionViewCell";

@interface ImageCollectionViewCell ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UAProgressView *progressView;

@end

@implementation ImageCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    self.backgroundColor = [UIColor whiteColor];
    
    [self defineConstraints];
    
    return self;
}

- (void)prepareForReuse
{
    self.imageView.image = nil;
    
    self.progressView.hidden = NO;
    self.progressView.progress = 0.0;
}

- (void)defineConstraints
{
    [self.imageView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
    
    [self.progressView autoSetDimensionsToSize:CGSizeMake(44, 44)];
    [self.progressView autoCenterInSuperview];
}

#pragma mark -
#pragma mark Accessor Methods

- (void)setImage:(UIImage *)image
{
    self.imageView.image = image;
}

- (void)setProgress:(float)progress
{
    if (progress >= 0 && progress < 1) {
        self.progressView.hidden = NO;
        [self.progressView setProgress:progress animated:YES];
    } else {
        self.progressView.hidden = YES;
    }
}

@end
