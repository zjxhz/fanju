//
//  OrderDetailsViewController.h
//  EasyOrder
//
//  Created by 浣泽 徐 on 7/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
#import "MealInfo.h"
#import "OrderInfo.h"
#import "NINetworkImageView.h"
#import <MapKit/MapKit.h>

@interface OrderDetailsViewController : UIViewController<UIGestureRecognizerDelegate, MKMapViewDelegate>
@property (weak, nonatomic) IBOutlet UIScrollView* scrollView;
@property (weak, nonatomic) IBOutlet UILabel *restaurant;
@property (weak, nonatomic) IBOutlet UILabel *topic;
@property (weak, nonatomic) IBOutlet UILabel *time;
@property (weak, nonatomic) IBOutlet UIImageView *mealBg;
@property (strong, nonatomic) NINetworkImageView *mealImage;
@property (weak, nonatomic) MealInfo* meal;
@property (weak, nonatomic) IBOutlet UILabel* codeLabel;
@property (weak, nonatomic) IBOutlet UILabel* numerOfPersons;
@property(nonatomic, nonatomic) IBOutlet MKMapView* mapView;
@property (nonatomic, weak) OrderInfo* order;
@end
