//
//  DataManager.h
//  MobiPic
//
//  Created by Juan Alvarez on 11/9/14.
//  Copyright (c) 2014 Alvarez Productions. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DBPath;
@class CLLocation;
@class PhotoModel;
@class DBDatastore;
@class DBTable;

typedef void(^DMResultsCompletionBlock)(NSArray *results, NSError *error);

@interface DataManager : NSObject

@property (nonatomic, strong, readonly) DBDatastore *datastore;
@property (nonatomic, strong, readonly) DBTable *table;

+ (instancetype)sharedInstance;

- (void)getAllPhotoModels:(DMResultsCompletionBlock)completion;

- (PhotoModel *)modelForPath:(DBPath *)path;

- (void)savePhoto:(PhotoModel *)model;
- (void)deletePhoto:(PhotoModel *)model;

@end
