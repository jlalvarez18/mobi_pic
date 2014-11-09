//
//  ImageCellViewModel.m
//  MobiPic
//
//  Created by Juan Alvarez on 11/9/14.
//  Copyright (c) 2014 Alvarez Productions. All rights reserved.
//

#import "ImageCellViewModel.h"

#import <Dropbox/DBFile.h>
#import <Dropbox/DBPath.h>

@implementation ImageCellViewModel

- (instancetype)initWithDBFile:(DBFile *)file
{
    self = [super init];
    
    DBFileStatus *fileStatus = file.status;
    DBFileStatus *newerStatus = file.newerStatus;
    
    NSLog(@"%@", fileStatus);
    
    if (fileStatus.cached) {
        _image = [UIImage imageWithData:[file readData:nil]];
        _progress = 1.0;
    } else {
        if (fileStatus.state == DBFileStateDownloading || fileStatus.state == DBFileStateUploading) {
            _progress = fileStatus.progress;
        }
        else if (newerStatus && newerStatus.state == DBFileStateDownloading) {
            _progress = newerStatus.progress;
        }
        else {
            _progress = 0.0;
        }
    }
    
    return self;
}

@end
