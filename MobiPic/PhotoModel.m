//
//  PhotoModel.m
//  MobiPic
//
//  Created by Juan Alvarez on 11/9/14.
//  Copyright (c) 2014 Alvarez Productions. All rights reserved.
//

#import "PhotoModel.h"

#import <Dropbox/Dropbox.h>

@import CoreLocation.CLLocation;

NSString *const kPhotoPathNameKey = @"path_name";
static NSString *kPhotoModifiedDateKey = @"modified_date";
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

- (BOOL)isEqual:(id)other
{
    if (other == self) {
        return YES;
    }
    else if (![other isKindOfClass:[self class]]) {
        return NO;
    }
    else {
        PhotoModel *otherModel = other;
        
        return [self.path isEqual:otherModel.path];
    }
}

- (NSUInteger)hash
{
    return self.path.hash;
}

+ (PhotoModel *)modelForRecord:(DBRecord *)record
{
    PhotoModel *model = [PhotoModel new];
    
    model.city = record[kPhotoCityKey];
    model.path = [[DBPath root] childPath:record[kPhotoPathNameKey]];
    model.modifiedDate = record[kPhotoModifiedDateKey];
    
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
    [attr setValue:self.modifiedDate forKey:kPhotoModifiedDateKey];
    
    if (self.location) {
        CLLocationCoordinate2D coordinate = self.location.coordinate;
        
        [attr setValue:@(coordinate.latitude) forKey:kPhotoLatitudeKey];
        [attr setValue:@(coordinate.longitude) forKey:kPhotoLongitudeKey];
    }
    
    return [attr copy];
}

- (DBFile *)file
{
    if (_file) {
        return _file;
    }
    
    _file = [[DBFilesystem sharedFilesystem] openFile:self.path error:nil];
    
    return _file;
}

- (DBFile *)thumbnailFileForSize:(DBThumbSize)size error:(NSError **)error
{
    DBFile *file = self.thumbnails[@(size)];
    
    if (!file) {
        DBError *fileError;
        file = [[DBFilesystem sharedFilesystem] openThumbnail:self.path ofSize:size inFormat:DBThumbFormatJPG error:&fileError];
        
        if (file) {
            self.thumbnails[@(size)] = file;
        } else {
            if (error) {
                *error = fileError;
            }
        }
    }
    
    return file;
}

@end

@implementation PhotoModel (MKAnnotationSupport)

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

@end
