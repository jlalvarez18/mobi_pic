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
#import "PhotoDetailsViewController.h"

#import <Dropbox/Dropbox.h>

@import MapKit;

@interface MapViewController () <MKMapViewDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@property (nonatomic, strong) NSArray *items;
@property (nonatomic, assign) BOOL itemsLoaded;

@end

@implementation MapViewController

- (void)awakeFromNib
{
    self.title = NSLocalizedString(@"Map", nil);
    self.tabBarItem.image = [UIImage imageNamed:@"Compass"];
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
    
    if (!self.itemsLoaded) {
        [[DataManager sharedInstance] getAllPhotoModels:^(NSArray *results, NSError *error) {
            self.items = results;
            
            [self.mapView addAnnotations:self.items];
            
            self.itemsLoaded = YES;
        }];
    }
}

#pragma mark -
#pragma mark MKMapViewDelegate Methods

- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views
{
    [self.mapView showAnnotations:self.items animated:YES];
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
    DBFile *thumbnailFile = [model thumbnailFileForSize:DBThumbSizeS error:nil];
    UIImage *image = [UIImage imageWithData:[thumbnailFile readData:nil]];
    
    view.leftCalloutAccessoryView = [[UIImageView alloc] initWithImage:image];
    
    return view;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    PhotoModel *model = view.annotation;
    
    PhotoDetailsViewController *detailsController = [[PhotoDetailsViewController alloc] initWithPath:model.path];
    
    [self.navigationController pushViewController:detailsController animated:YES];
}

@end
