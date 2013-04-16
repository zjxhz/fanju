//
//  OrderDetailsViewController.m
//  EasyOrder
//
//  Created by 浣泽 徐 on 7/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OrderDetailsViewController.h"
#import "Const.h"
#import "WidgetFactory.h"
#import "Location.h"
#import "MealDetailViewController.h"
#import "MapHelper.h"

@interface OrderDetailsViewController ()

@end

@implementation OrderDetailsViewController
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _mealImage = [[NINetworkImageView alloc] initWithFrame:CGRectMake(4, 3.5, 72, 72)];
    }
    return self;
}

-(void)viewDidLoad{
    [super viewDidLoad];
    [self.mealBg addSubview:_mealImage];
    self.navigationItem.titleView  = [[WidgetFactory sharedFactory] titleViewWithTitle:@"订单详情"];
    [self buildUI];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    _mapView.layer.borderWidth = 1;
    _mapView.layer.borderColor = [UIColor grayColor].CGColor;
}

-(void)setOrder:(OrderInfo *)order{
    _order = order;
    _meal = _order.meal;
}

-(void)buildUI{
    _topic.text = _meal.topic;
    _codeLabel.text = _order.code;
    _numerOfPersons.text = [NSString stringWithFormat:@"（供%d人使用）", _order.numerOfPersons];
    _time.text = _meal.timeText;
    _restaurant.text = [NSString stringWithFormat:@"%@ %@", _meal.restaurant.name, _meal.restaurant.address];
    [_mealImage setPathToNetworkImage:[_meal photoFullUrl] forDisplaySize:CGSizeMake(72, 72) contentMode:UIViewContentModeScaleAspectFill];
//    _mealImage.userInteractionEnabled = YES;
    UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showMealDetails:)];
    tap.delegate = self;
//    [_mealImage addGestureRecognizer:tap];
    _mealBg.userInteractionEnabled = YES;
    [_mealBg addGestureRecognizer:tap];
    [NSThread detachNewThreadSelector:@selector(displayMap) toTarget:self withObject:nil];
}

-(void)displayMap
{
    @autoreleasepool {
        MKCoordinateRegion region;
        MKCoordinateSpan span;
        span.latitudeDelta=0.01;
        span.longitudeDelta=0.01;
        
        CLLocationCoordinate2D location = _meal.restaurant.coordinate;
        
        region.span=span;
        region.center=location;
        
        [_mapView setRegion:region animated:TRUE];
        [_mapView regionThatFits:region];
        _mapView.delegate = self;
        Location* annotation = [[Location alloc] initWithName:_meal.restaurant.name address:_meal.restaurant.address coordinate:_meal.restaurant.coordinate];
        [_mapView addAnnotation:annotation];
    }
}

-(IBAction)showMealDetails:(id)sender{
    MealDetailViewController *detail = [[MealDetailViewController alloc] init];
    detail.mealInfo = _meal;
    [self.navigationController pushViewController:detail animated:YES];

}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    return YES;
}


#pragma mark -
#pragma mark mapkit delegae
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation{
    MKPinAnnotationView *annotationView = (MKPinAnnotationView *)[_mapView dequeueReusableAnnotationViewWithIdentifier:@"Restaurant"];
    if (annotationView == nil) {
        annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"Restaurant"];
        annotationView.canShowCallout = YES;
        
        UIButton *rightButton= [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        annotationView.rightCalloutAccessoryView = rightButton;
        [rightButton addTarget:self action:@selector(launchRoute) forControlEvents:UIControlEventTouchDown];
    } else {
        annotationView.annotation = annotation;
    }
    
    annotationView.enabled = YES;
    annotationView.canShowCallout = YES;
    return annotationView;
}


-(void)launchRoute {
    RestaurantInfo* restaurant = self.order.meal.restaurant;
    CLLocationCoordinate2D coordinate =
    CLLocationCoordinate2DMake(restaurant.coordinate.latitude, restaurant.coordinate.longitude);
    [MapHelper launchRouteTo:coordinate withName:restaurant.name];
}
@end
