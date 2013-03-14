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
@interface MapViewController () 
@property (nonatomic, strong) MKMapView* myMapView;
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
    if (self = [super init]) {
        self.title = title;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self customNavigationBar:@"路线"];
    UIBarButtonItem* item = self.navigationItem.rightBarButtonItem;
    UIButton* rightButton = (UIButton*)item.customView;
    [rightButton addTarget:self action:@selector(launchRoute) forControlEvents:UIControlEventTouchUpInside];
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
        Location* annotation = [[Location alloc] initWithName:self.info.name address:self.info.address coordinate:self.info.coordinate];
        [self.myMapView addAnnotation:annotation];
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
    Class mapItemClass = [MKMapItem class];
    if (mapItemClass && [mapItemClass respondsToSelector:@selector(openMapsWithItems:launchOptions:)])
    {
        // Create an MKMapItem to pass to the Maps app
        CLLocationCoordinate2D coordinate =
        CLLocationCoordinate2DMake(self.info.coordinate.latitude, self.info.coordinate.longitude);
        MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:coordinate
                                                       addressDictionary:nil];
        MKMapItem *mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
        [mapItem setName:self.info.name];
        

        NSDictionary *launchOptions = @{MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving};
        MKMapItem *currentLocationMapItem = [MKMapItem mapItemForCurrentLocation];
        [MKMapItem openMapsWithItems:@[currentLocationMapItem, mapItem]
                       launchOptions:launchOptions];
    } else {
        NSString *route = [NSString stringWithFormat:@"http://maps.google.com/maps?saddr=%@&daddr=%g,%g", NSLocalizedString(@"CurrentLocation", nil), self.info.coordinate.latitude, self.info.coordinate.longitude];
        route = [route stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:route]];
    }
}
@end
