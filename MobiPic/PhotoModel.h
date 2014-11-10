//
//  PhotoModel.h
//  MobiPic
//
//  Created by Juan Alvarez on 11/9/14.
//  Copyright (c) 2014 Alvarez Productions. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CLLocation;

@class DBPath;
@class DBRecord;

extern NSString *const kPhotoPathNameKey;

@interface PhotoModel : NSObject

@property (nonatomic, strong) DBPath *path;
@property (nonatomic, strong) NSString *city;
@property (nonatomic, strong) NSString *descriptionText;
@property (nonatomic, strong) CLLocation *location;

+ (PhotoModel *)modelForRecord:(DBRecord *)record;

- (NSDictionary *)attributes;

@end
