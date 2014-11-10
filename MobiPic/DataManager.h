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

@interface DataManager : NSObject

+ (instancetype)sharedInstance;

- (void)savePhoto:(PhotoModel *)model;
- (PhotoModel *)modelForPath:(DBPath *)path;

@end
