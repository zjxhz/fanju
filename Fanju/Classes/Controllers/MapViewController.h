//
//  MapViewController.h
//  EasyOrder
//
//  Created by igneus on 12/3/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Three20/Three20.h>
#import <MapKit/MapKit.h>
#import "RestaurantInfo.h"

@interface MapViewController : TTViewController <MKMapViewDelegate>
@property (nonatomic, strong) RestaurantInfo* info;
-(id)initWithTitle:(NSString*)title;

@end
