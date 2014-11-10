//
//  PhotoModel.h
//  MobiPic
//
//  Created by Juan Alvarez on 11/9/14.
//  Copyright (c) 2014 Alvarez Productions. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Dropbox/DBFilesystem.h>

@import MapKit.MKAnnotation;

@class CLLocation;
@class DBPath;
@class DBRecord;
@class DBFile;

extern NSString *const kPhotoPathNameKey;

@interface PhotoModel : NSObject <MKAnnotation>

@property (nonatomic, strong) DBPath *path;
@property (nonatomic, strong) NSString *city;
@property (nonatomic, strong) NSString *descriptionText;
@property (nonatomic, strong) CLLocation *location;

@property (nonatomic, strong, readonly) DBFile *file;

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic, readonly) NSString *title;

+ (PhotoModel *)modelForRecord:(DBRecord *)record;

- (NSDictionary *)attributes;

- (DBFile *)thumbnailFileForSize:(DBThumbSize)size;

@end
