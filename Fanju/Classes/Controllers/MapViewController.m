//
//  MapViewController.m
//  EasyOrder
//
//  Created by igneus on 12/3/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MapViewController.h"
#import "AppDelegate.h"
#import "RestaurantInfo.h"

@interface MapViewController () 
@property (nonatomic, strong) MKMapView* myMapView;
@property (nonatomic, strong) RestaurantInfo* info;

-(void)displayMap;
-(void)launchRoute;
@end

@implementation MapViewController
@synthesize myMapView = _myMapView;
@synthesize info = _info;

- (void)loadView {
    [super loadView];

    self.myMapView = [[MKMapView alloc] initWithFrame:self.view.bounds]; 
    self.myMapView.delegate=self; 
    [self.view addSubview:self.myMapView];
    [NSThread detachNewThreadSelector:@selector(displayMap) toTarget:self withObject:nil]; 
}

-(id)initWithTitle:(NSString*)title {
    AppDelegate *delegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    RestaurantInfo* info = (RestaurantInfo*)delegate.sharedObject;
    
    if (self = [super init]) {
        self.title = info.title;
        self.info = info;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    TTButton *btn = [TTButton buttonWithStyle:@"embossedBackButton:" title:NSLocalizedString(@"Back", nil)];
    [btn addTarget:self.navigationController 
            action:@selector(popViewControllerAnimated:) 
  forControlEvents:UIControlEventTouchDown];
    btn.font = [UIFont systemFontOfSize:13];
    [btn sizeToFit];
    UIBarButtonItem *temporaryBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:btn];
    self.navigationItem.leftBarButtonItem = temporaryBarButtonItem;
    self.navigationItem.hidesBackButton = YES;
    
    btn = [TTButton buttonWithStyle:@"embossedButton:" title:NSLocalizedString(@"Direction", nil)];
    [btn addTarget:self
            action:@selector(launchRoute) 
  forControlEvents:UIControlEventTouchDown];
    btn.font = [UIFont systemFontOfSize:13];
    [btn sizeToFit];
    temporaryBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:btn];
    self.navigationItem.rightBarButtonItem = temporaryBarButtonItem;
}

-(void)displayMap
{
    @autoreleasepool {
        MKCoordinateRegion region; 
        MKCoordinateSpan span; 
        span.latitudeDelta=0.1; 
        span.longitudeDelta=0.1; 
        
        CLLocationCoordinate2D location = self.info.coordinate;         
        
        region.span=span; 
        region.center=location; 
        
        [self.myMapView setRegion:region animated:TRUE]; 
        [self.myMapView regionThatFits:region]; 
        [self.myMapView addAnnotation:self.info];
    }
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
    NSString *route = [NSString stringWithFormat:@"http://maps.google.com/maps?saddr=%@&daddr=%g,%g", NSLocalizedString(@"CurrentLocation", nil), self.info.coordinate.latitude, self.info.coordinate.longitude];
    route = [route stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:route]];
}
@end
