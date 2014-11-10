//
//  MapViewController.m
//  MobiPic
//
//  Created by Juan Alvarez on 11/10/14.
//  Copyright (c) 2014 Alvarez Productions. All rights reserved.
//

#import "MapViewController.h"

#import "DataManager.h"
#import "PhotoModel.h"
#import <Dropbox/Dropbox.h>

@import MapKit;

@interface MapViewController () <MKMapViewDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@property (nonatomic, strong) NSArray *items;

@end

@implementation MapViewController

- (void)awakeFromNib
{
    self.title = NSLocalizedString(@"Map", nil);
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.mapView.delegate = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.items = [[DataManager sharedInstance] getAllPhotoModels];
    
//    DBFilesystem *fileSystem = [DBFilesystem sharedFilesystem];
//    
//    [self.items enumerateObjectsUsingBlock:^(PhotoModel *model, NSUInteger idx, BOOL *stop) {
//        model.thumbnailFile;
//    }];
    
    [self.mapView addAnnotations:self.items];
    [self.mapView showAnnotations:self.items animated:YES];
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    [mapView setCenterCoordinate:userLocation.coordinate animated:YES];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    }
    
    static NSString *idstring = @"";
    
    MKPinAnnotationView *view = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:idstring];
    
    if (view == nil) {
        view = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:idstring];
    }
    
    view.pinColor = MKPinAnnotationColorRed;
    view.canShowCallout = YES;
    view.animatesDrop = YES;
    view.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeInfoDark];
    
    PhotoModel *model = annotation;
    UIImage *image = [UIImage imageWithData:[model.thumbnailFile readData:nil]];
    view.leftCalloutAccessoryView = [[UIImageView alloc] initWithImage:image];
    
    return view;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    NSLog(@"Tapped");
}

@end
