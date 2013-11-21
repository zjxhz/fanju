//
//  MapViewController.m
//  EasyOrder
//
//  Created by igneus on 12/3/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MapViewController.h"
#import "AppDelegate.h"
#import "Location.h"
#import "UIViewController+CustomNavigationBar.h"
#import "MapHelper.h"

@interface MapViewController () 
@property (nonatomic, strong) MKMapView* myMapView;
-(void)displayMap;
-(void)launchRoute;
@end

@implementation MapViewController
@synthesize myMapView = _myMapView;

- (void)loadView {
    [super loadView];

    self.myMapView = [[MKMapView alloc] initWithFrame:self.view.bounds]; 
    self.myMapView.delegate=self; 
    [self.view addSubview:self.myMapView];
}


-(id)initWithTitle:(NSString*)title {   
    if (self = [super init]) {
        self.navigationItem.titleView = [[WidgetFactory sharedFactory] titleViewWithTitle:title];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if (![VersionUtil isiOS7]) {
        self.navigationItem.leftBarButtonItem = [[WidgetFactory sharedFactory]backButtonWithTarget:self.navigationController action:@selector(popViewControllerAnimated:)];
    }
    self.navigationItem.rightBarButtonItem = [[WidgetFactory sharedFactory] normalBarButtonItemWithTitle:@"路线" target:self action:@selector(launchRoute)];
    [self displayMap];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.myMapView.frame = self.view.frame;
}

-(void)displayMap
{
    MKCoordinateRegion region;
    MKCoordinateSpan span; 
    span.latitudeDelta=0.1;
    span.longitudeDelta=0.1; 

    region.span=span; 
    region.center=[self coordinate];
    
    [self.myMapView setRegion:region animated:TRUE]; 
    [self.myMapView regionThatFits:region];
    Location* annotation = [[Location alloc] initWithName:_restaurant.name address:_restaurant.address coordinate:[self coordinate]];
    [self.myMapView addAnnotation:annotation];
}

-(CLLocationCoordinate2D)coordinate{
    CLLocationCoordinate2D location;
    location.latitude = [_restaurant.latitude floatValue];
    location.longitude = [_restaurant.longitude floatValue];
    return location;
}

#pragma mark MKMapViewDelegate
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id < MKAnnotation >)annotation {
    static NSString *MKAID = @"MKAID";
    MKAnnotationView *aView = [mapView dequeueReusableAnnotationViewWithIdentifier:MKAID];
    
    if (!aView) {
        aView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation
                                                reuseIdentifier:MKAID];
        [aView setCanShowCallout:YES];
    }
    
    aView.annotation = annotation; // yes, this happens twice if no dequeue
    // maybe load up accessory views here (if not too expensive)?
    // or reset them and wait until mapView:didSelectAnnotationView: to load actual data
    return aView;
}

-(void)launchRoute {
    [MapHelper launchRouteTo:[self coordinate] withName:_restaurant.name];
}
@end
