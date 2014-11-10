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

#import "PhotoModel.h"

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

- (void)savePhoto:(PhotoModel *)model
{
    DBRecord *record = [self recordWithPath:model.path];
    
    NSDictionary *attributes = [model attributes];
    
    if (record) {
        [record setValuesForKeysWithDictionary:attributes];
    } else {
        record = [self.table insert:attributes];
    }
    
    [self.datastore sync:nil];
}

- (PhotoModel *)modelForPath:(DBPath *)path
{
    DBRecord *record = [self recordWithPath:path];
    
    PhotoModel *model = [PhotoModel modelForRecord:record];
    
    return model;
}

#pragma mark - Private

- (DBRecord *)recordWithPath:(DBPath *)path
{
    return [self recordWithPathName:path.name];
}

- (DBRecord *)recordWithPathName:(NSString *)pathName
{
    DBError *error;
    NSArray *results = [self.table query:@{ kPhotoPathNameKey: pathName } error:&error];
    
    if (error) {
        NSLog(@"%@", error);
    }
    
    return results.firstObject;
}

@end
