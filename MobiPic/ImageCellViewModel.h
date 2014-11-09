//
//  ImageCellViewModel.h
//  MobiPic
//
//  Created by Juan Alvarez on 11/9/14.
//  Copyright (c) 2014 Alvarez Productions. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DBFile;

@interface ImageCellViewModel : UIView

@property (nonatomic, strong, readonly) UIImage *image;
@property (nonatomic, assign, readonly) float progress;

- (instancetype)initWithDBFile:(DBFile *)file;

@end
