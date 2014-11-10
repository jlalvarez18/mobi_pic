//
//  LabelCollectionViewCell.h
//  MobiPic
//
//  Created by Juan Alvarez on 11/10/14.
//  Copyright (c) 2014 Alvarez Productions. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString *const LabelCollectionViewCellIdentifier;

@interface LabelCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) NSString *placeholder;

@property (nonatomic, strong) UIImage *iconImage;

@end
