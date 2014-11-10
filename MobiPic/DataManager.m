//
//  DataManager.m
//  MobiPic
//
//  Created by Juan Alvarez on 11/9/14.
//  Copyright (c) 2014 Alvarez Productions. All rights reserved.
//

#import "DataManager.h"

#import <Dropbox/Dropbox.h>

@import CoreLocation;

static NSString *kPhotosTableID = @"Photos";

static NSString *kPhotoPathKey = @"path";
static NSString *kPhotoLatitudeKey = @"lat";
static NSString *kPhotoLongitudeKey = @"long";

@interface DataManager ()

@property (nonatomic, strong) DBDatastore *datastore;
@property (nonatomic, strong) DBTable *table;

@end

@implementation DataManager

+ (instancetype)sharedInstance
{
    static DataManager *_sharedInstance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[DataManager alloc] init];
    });
    
    return _sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    
    self.datastore = [[DBDatastoreManager sharedManager] openDefaultDatastore:nil];
    self.table = [self.datastore getTable:kPhotosTableID];
    
    return self;
}

- (CLLocation *)locationForPath:(DBPath *)path
{
    DBRecord *record = [self recordForPath:path];
    
    if (record) {
        double latitude = [record[kPhotoLatitudeKey] doubleValue];
        double longitude = [record[kPhotoLongitudeKey] doubleValue];
        
        CLLocation *location = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
        
        return location;
    }
    
    return nil;
}

- (void)saveLocation:(CLLocation *)location toPath:(DBPath *)path
{
    CLLocationCoordinate2D coordinate = location.coordinate;
    
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    attributes[kPhotoLatitudeKey] = @(coordinate.latitude);
    attributes[kPhotoLongitudeKey] = @(coordinate.longitude);
    attributes[kPhotoPathKey] = path.name;
    
    NSArray *results = [self.table query:@{ @"name": path.name } error:nil];
    
    DBRecord *record = results.firstObject;
    
    if (record) {
        [record setValuesForKeysWithDictionary:attributes];
    } else {
        record = [self.table insert:attributes];
    }
    
    [self.datastore sync:nil];
}

#pragma mark - Private

- (DBRecord *)recordForPath:(DBPath *)path
{
    NSArray *results = [self.table query:@{ @"name": path.name } error:nil];
    
    return results.firstObject;
}

@end
