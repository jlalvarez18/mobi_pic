//
//  LabelCollectionViewCell.m
//  MobiPic
//
//  Created by Juan Alvarez on 11/10/14.
//  Copyright (c) 2014 Alvarez Productions. All rights reserved.
//

#import "LabelCollectionViewCell.h"

NSString *const LabelCollectionViewCellIdentifier = @"LabelCollectionViewCell";

@interface LabelCollectionViewCell ()

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;

@end

@implementation LabelCollectionViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setText:(NSString *)text
{
    _text = text;
    
    if (_text && ![_text isEqualToString:@""]) {
        self.titleLabel.text = text;
        self.titleLabel.textColor = [UIColor blackColor];
        self.titleLabel.font = [UIFont systemFontOfSize:17];
    } else {
        self.titleLabel.text = self.placeholder;
        self.titleLabel.textColor = [UIColor lightGrayColor];
        self.titleLabel.font = [UIFont italicSystemFontOfSize:17];
    }
}

- (void)setIconImage:(UIImage *)iconImage
{
    _iconImage = iconImage;
    
    self.iconImageView.image = _iconImage;
}

@end
