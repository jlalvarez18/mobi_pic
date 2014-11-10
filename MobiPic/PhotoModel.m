//
//  PhotoModel.m
//  MobiPic
//
//  Created by Juan Alvarez on 11/9/14.
//  Copyright (c) 2014 Alvarez Productions. All rights reserved.
//

#import "PhotoModel.h"

@import CoreLocation.CLLocation;

#import <Dropbox/Dropbox.h>

NSString *const kPhotoPathNameKey = @"path_name";
static NSString *kPhotoCityKey = @"city";
static NSString *kPhotoDescriptionKey = @"description";
static NSString *kPhotoLatitudeKey = @"lat";
static NSString *kPhotoLongitudeKey = @"long";

@interface PhotoModel ()

@property (nonatomic, strong) NSMutableDictionary *thumbnails;

@end

@implementation PhotoModel

@synthesize file = _file;

- (instancetype)init
{
    self = [super init];
    
    self.thumbnails = [NSMutableDictionary dictionary];
    
    return self;
}

+ (PhotoModel *)modelForRecord:(DBRecord *)record
{
    PhotoModel *model = [PhotoModel new];
    
    model.city = record[kPhotoCityKey];
    model.path = [[DBPath root] childPath:record[kPhotoPathNameKey]];
    
    double latitude = [record[kPhotoLatitudeKey] doubleValue];
    double longitude = [record[kPhotoLongitudeKey] doubleValue];
    
    if (latitude != 0 && longitude != 0) {
        model.location = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
    }
    
    model.descriptionText = record[kPhotoDescriptionKey];
    
    return model;
}

- (NSDictionary *)attributes
{
    NSMutableDictionary *attr = [NSMutableDictionary dictionary];
    [attr setValue:self.path.name forKey:kPhotoPathNameKey];
    [attr setValue:self.city forKey:kPhotoCityKey];
    [attr setValue:self.descriptionText forKey:kPhotoDescriptionKey];
    
    if (self.location) {
        CLLocationCoordinate2D coordinate = self.location.coordinate;
        
        [attr setValue:@(coordinate.latitude) forKey:kPhotoLatitudeKey];
        [attr setValue:@(coordinate.longitude) forKey:kPhotoLongitudeKey];
    }
    
    return attr;
}

- (CLLocationCoordinate2D)coordinate
{
    return self.location.coordinate;
}

- (NSString *)title
{
    if (self.city) {
        return self.city;
    }
    
    return @"Unknown Location";
}

- (DBFile *)file
{
    if (_file) {
        return _file;
    }
    
    _file = [[DBFilesystem sharedFilesystem] openFile:self.path error:nil];
    
    return _file;
}

- (DBFile *)thumbnailFileForSize:(DBThumbSize)size
{
    DBFile *file = self.thumbnails[@(size)];
    
    if (!file) {
        file = [[DBFilesystem sharedFilesystem] openThumbnail:self.path ofSize:size inFormat:DBThumbFormatJPG error:nil];
        
        if (file) {
            self.thumbnails[@(size)] = file;
        }
    }
    
    return file;
}

@end
