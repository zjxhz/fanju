//
//  RestaurantListViewController.m
//  EasyOrder
//
//  Created by igneus on 12/3/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "RestaurantListViewController.h"
#import "LocationProvider.h"
#import "Const.h"
#import "NetworkHandler.h"
#import "RestaurantInfo.h"
#import <Three20/Three20+Additions.h>
#import "AppDelegate.h"

@interface RestaurantListViewController() <UITableViewDelegate>

@property (nonatomic, strong) MKMapView* myMapView;
@property (nonatomic, strong) NSMutableArray *restaurants;

-(void)displayMap;
-(void)switchListMode;
@end

@implementation RestaurantListViewController

@synthesize myMapView = _myMapView;
@synthesize restaurants = _restaurants;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    displayListMode = YES;
    TTButton *btn = [TTButton buttonWithStyle:@"embossedButton:" title:NSLocalizedString(@"MapMode", nil)];
    [btn addTarget:self 
            action:@selector(switchListMode) 
  forControlEvents:UIControlEventTouchDown];
    btn.font = [UIFont systemFontOfSize:13];
    [btn sizeToFit];
    UIBarButtonItem *temporaryBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:btn];
    self.navigationItem.rightBarButtonItem = temporaryBarButtonItem;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (!self.restaurants) {
        double longtitude = 120.163314;
        double latitude = 30.273025;
        if ([LocationProvider sharedProvider].lastLocation) {
            longtitude = [[LocationProvider sharedProvider].lastLocation coordinate].longitude;
            latitude = [[LocationProvider sharedProvider].lastLocation coordinate].latitude;
        }
        
        NSString *requestStr = [NSString stringWithFormat:@"%@://%@/get_restaurant_list_by_geo/?longitude=%g&latitude=%g&range=5000", HTTPS, EOHOST, longtitude, latitude];
        NetworkHandler *handler = [[NetworkHandler alloc] init];
        [handler requestFromURL:requestStr
                         method:GET
                        success:^(id obj) {
                            if (obj && [obj isKindOfClass:[NSArray class]]) {
                                self.restaurants = [NSMutableArray array];
                                TTListDataSource *ds = [[TTListDataSource alloc] init];
                               
                                for (NSDictionary *dict in obj) {
                                    RestaurantInfo *info = [RestaurantInfo restaurantWithData:dict];
                                    if (info) {
                                        [self.restaurants addObject:info];
                                       
                                        [ds.items addObject:[TTTableMessageItem itemWithTitle:info.title
                                                                                      caption:info.tel
                                                                                         text:info.subtitle
                                                                                    timestamp:nil
                                                                                          URL:@"eo://detail/detail"]];
                                    }
                                }
                               
                                self.dataSource = ds;
                            } else {
                               
                            }
                        } failure:^{
                           
                        }];
    }
    
    //tabbar
    CGRect applicationFrame = [UIScreen mainScreen].applicationFrame;
    TTTabBar *tabBar = [[TTTabBar alloc] initWithFrame:CGRectMake(0, 0, applicationFrame.size.width, 40)];
    tabBar.tabItems = [NSArray arrayWithObjects:
                       [[TTTabItem alloc] initWithTitle:NSLocalizedString(@"SortByDistance", nil)],
                       [[TTTabItem alloc] initWithTitle:NSLocalizedString(@"SortByRating", nil)],
                       [[TTTabItem alloc] initWithTitle:NSLocalizedString(@"SortByPrice", nil)],
                       nil];
    tabBar.selectedTabIndex = 0;
    self.tableView.tableHeaderView = tabBar;
}

-(void)switchListMode {
    if (displayListMode) {
        // get the view that's currently showing
        UIView *currentView = self.tableView;
        // get the the underlying UIWindow, or the view containing the current view view
        UIView *theWindow = [currentView superview];
        
        if (!self.myMapView) {
            self.myMapView = [[MKMapView alloc] initWithFrame:self.view.bounds]; 
            self.myMapView.delegate=self; 
        }
        
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft
                               forView:theWindow cache:YES];
        [UIView setAnimationDuration:0.5];
        [currentView removeFromSuperview];
        [theWindow addSubview:self.myMapView];
        [UIView commitAnimations];
        
        [(TTButton*)self.navigationItem.rightBarButtonItem.customView setTitle:NSLocalizedString(@"ListMode", nil)
                                                                      forState:UIControlStateNormal];
        
        [NSThread detachNewThreadSelector:@selector(displayMap) toTarget:self withObject:nil]; 
    } else {
        // get the view that's currently showing
        UIView *currentView = self.myMapView;
        // get the the underlying UIWindow, or the view containing the current view view
        UIView *theWindow = [currentView superview];
        
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight
                               forView:theWindow cache:YES];
        [UIView setAnimationDuration:0.5];
        [currentView removeFromSuperview];
        [theWindow addSubview:self.tableView];
        [UIView commitAnimations];
        
        [(TTButton*)self.navigationItem.rightBarButtonItem.customView setTitle:NSLocalizedString(@"MapMode", nil)
                                                                      forState:UIControlStateNormal];
    }
    
    displayListMode = !displayListMode;
}

-(void)displayMap
{
    @autoreleasepool {
        MKCoordinateRegion region; 
        MKCoordinateSpan span; 
        span.latitudeDelta=0.1; 
        span.longitudeDelta=0.1; 
        
        CLLocationCoordinate2D location; 
        if ([LocationProvider sharedProvider].lastLocation) {
            location = [LocationProvider sharedProvider].lastLocation.coordinate;
        } else {
            location.latitude = 30.273025;
            location.longitude = 120.163314;   
        }
        
        region.span=span; 
        region.center=location; 
        
        [self.myMapView setRegion:region animated:TRUE]; 
        [self.myMapView regionThatFits:region]; 
        [self.myMapView addAnnotations:self.restaurants];
    }
}

- (id<UITableViewDelegate>)createDelegate {
    return self;
}

#pragma mark UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    AppDelegate *delegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    [delegate setSharedObject:[self.restaurants objectAtIndex:indexPath.row]];
    
    TTOpenURL(@"eo://detail/detail");
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
@end
