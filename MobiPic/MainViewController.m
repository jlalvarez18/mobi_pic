//
//  ViewController.m
//  MobiPic
//
//  Created by Juan Alvarez on 11/8/14.
//  Copyright (c) 2014 Alvarez Productions. All rights reserved.
//

#import "MainViewController.h"

@interface MainViewController () <UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, strong) UIImagePickerController *pickerController;

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = NSLocalizedString(@"My Photos", nil);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        self.navigationController.toolbarHidden = NO;
    } else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Camera Missing"
                                                                       message:@"This app is pretty boring without a camera :("
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:@"Dismiss"
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction *action) {
                                                                  [alert dismissViewControllerAnimated:YES completion:nil];
                                                              }];

        [alert addAction:dismissAction];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
}

#pragma mark -
#pragma mark Action Methods

- (IBAction)takePicture:(id)sender
{
    [self presentViewController:self.pickerController animated:YES completion:nil];
}

#pragma mark -
#pragma mark UICollectionViewDelegateFlowLayout Methods

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(CGRectGetWidth(self.view.bounds), 320);
}

#pragma mark -
#pragma mark UIImagePickerControllerDelegate Methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
//    UIImage *image = info[UIImagePickerControllerOriginalImage];
    
    NSLog(@"%@", info);
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
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
