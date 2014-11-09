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

NSString *ImageCollectionViewCellIdentifier = @"ImageCollectionViewCellIdentifier";

@interface ImageCollectionViewCell ()

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UAProgressView *progressView;

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
    if (progress >= 0 && progress <= 1) {
        self.progressView.hidden = NO;
        self.progressView.progress = progress;
    } else {
        self.progressView.hidden = YES;
    }
}

#pragma mark -
#pragma mark Views

- (UIImageView *)imageView
{
    if (_imageView) {
        return _imageView;
    }
    
    _imageView = [UIImageView newAutoLayoutView];
    _imageView.contentMode = UIViewContentModeScaleAspectFill;
    _imageView.clipsToBounds = YES;
    _imageView.backgroundColor = [UIColor lightGrayColor];
    
    [self.contentView addSubview:_imageView];
    
    return _imageView;
}

- (UAProgressView *)progressView
{
    if (_progressView) {
        return _progressView;
    }
    
    _progressView = [UAProgressView newAutoLayoutView];
    
    [self.contentView addSubview:_progressView];
    
    return _progressView;
}

@end
