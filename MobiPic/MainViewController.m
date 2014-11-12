//
//  ViewController.m
//  MobiPic
//
//  Created by Juan Alvarez on 11/8/14.
//  Copyright (c) 2014 Alvarez Productions. All rights reserved.
//

#import "MainViewController.h"

#import <Dropbox/Dropbox.h>
#import <UIImage-Resize/UIImage+Resize.h>
#import <INTULocationManager/INTULocationManager.h>
#import <SVProgressHUD/SVProgressHUD.h>

#import "MainDatasource.h"

#import "DataManager.h"
#import "PhotoModel.h"

#import "PhotoDetailsViewController.h"

@interface MainViewController () <UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, strong) MainDatasource *datasource;

@property (nonatomic, strong) UIImagePickerController *pickerController;

@property (nonatomic, strong) CLLocation *location;
@property (nonatomic, strong) CLGeocoder *geocoder;
@property (nonatomic, strong) NSString *cityLocation;

@property (nonatomic) BOOL viewAppeared;

@end

@implementation MainViewController

- (void)awakeFromNib
{
    self.title = NSLocalizedString(@"Photos", nil);
    self.tabBarItem.image = [UIImage imageNamed:@"Photos"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.datasource = [[MainDatasource alloc] initWithCollectionView:self.collectionView];

    if ([self hasCamera]) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(takePicture:)];
    }
    
    self.geocoder = [[CLGeocoder alloc] init];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationController.toolbarHidden = YES;
    
    DBAccount *account = [[DBAccountManager sharedManager] linkedAccount];
    
    if (account) {
        if (!self.viewAppeared) {
            // we only want to call this once when view appears
            [self.datasource reloadData];
            
            if ([self hasCamera]) {
                [self retrieveUserLocation];
            } else {
                [self presentMissingCameraAlert];
            }
            
            self.viewAppeared = YES;
        }
    }
}

#pragma mark -
#pragma mark Action Methods

- (void)takePicture:(id)sender
{
    [self.tabBarController presentViewController:self.pickerController animated:YES completion:nil];
}

#pragma mark -
#pragma mark UICollectionViewDelegate Methods

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    
    DBFile *file = [self.datasource fileAtIndexPath:indexPath];
    DBPath *path = file.info.path;
    
    PhotoDetailsViewController *controller = [[PhotoDetailsViewController alloc] initWithPath:path];
    
    [self.navigationController pushViewController:controller animated:YES];
}

#pragma mark -
#pragma mark UIImagePickerControllerDelegate Methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSLog(@"%@", info);
    
    // resize and compress image to save on size :)
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    UIImage *resizedImage = [image resizedImageToFitInSize:CGSizeMake(640, 640) scaleIfSmaller:NO];
    
    NSData *imageData = UIImageJPEGRepresentation(resizedImage, 0.7);
    
    NSString *imageId = [NSUUID UUID].UUIDString;
    NSString *imageName = [imageId stringByAppendingPathExtension:@"jpg"];
    
    NSError *error;
    DBPath *imagePath = [[DBPath root] childPath:imageName];
    DBFile *imageFile = [[DBFilesystem sharedFilesystem] createFile:imagePath error:&error];
    
    if (error) {
        NSLog(@"%@", error);
    } else {
        [SVProgressHUD show];
        
        if ([imageFile writeData:imageData error:&error]) {
            [imageFile close];
            
            PhotoModel *model = [PhotoModel new];
            model.path = imagePath;
            model.city = self.cityLocation;
            model.location = self.location;
            model.modifiedDate = [NSDate date];
            
            [[DataManager sharedInstance] savePhoto:model];
            
            [SVProgressHUD dismiss];
            
            [picker dismissViewControllerAnimated:YES completion:^{
                // the file system observer block will get called
                // so no need to manually call reloadFiles
            }];
        } else {
            NSLog(@"%@", error);
        }
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -
#pragma mark Private Methods

- (void)retrieveUserLocation
{
    [[INTULocationManager sharedInstance] requestLocationWithDesiredAccuracy:INTULocationAccuracyNeighborhood timeout:5.0 block:^(CLLocation *currentLocation, INTULocationAccuracy achievedAccuracy, INTULocationStatus status) {
        if (status == INTULocationStatusSuccess || status == INTULocationStatusTimedOut) {
            NSLog(@"%@", currentLocation);
            
            self.location = currentLocation;
            
            [self.geocoder reverseGeocodeLocation:self.location completionHandler:^(NSArray *placemarks, NSError *error) {
                CLPlacemark *placemark = placemarks.firstObject;
                
                if (placemark) {
                    self.cityLocation = placemark.locality;
                }
            }];
        }
    }];
}

- (void)presentMissingCameraAlert
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Camera Missing"
                                                                   message:@"This app is pretty boring without a camera :("
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [alert dismissViewControllerAnimated:YES completion:nil];
    }];
    
    [alert addAction:dismissAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (BOOL)hasCamera
{
    return [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
}

#pragma mark -
#pragma mark Accessor Methods

- (UIImagePickerController *)pickerController
{
    if (_pickerController) {
        return _pickerController;
    }
    
    _pickerController = [[UIImagePickerController alloc] init];
    _pickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
    _pickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    _pickerController.delegate = self;
    
    return _pickerController;
}

@end
