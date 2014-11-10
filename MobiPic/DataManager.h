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

@interface DataManager : NSObject

+ (instancetype)sharedInstance;

- (CLLocation *)locationForPath:(DBPath *)path;
- (void)saveLocation:(CLLocation *)location toPath:(DBPath *)path;

@end
