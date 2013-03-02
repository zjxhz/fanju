//
//  RestaurantInfo.h
//  EasyOrder
//
//  Created by igneus on 2/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface RestaurantInfo : NSObject <MKAnnotation> 

@property (nonatomic) CLLocationCoordinate2D coordinate;   
@property (nonatomic,copy) NSString *address;
@property (nonatomic,copy) NSString *name;   
@property (nonatomic,copy) NSString *tel;   
@property (nonatomic) int rID;   

+ (RestaurantInfo *)restaurantWithData:(NSDictionary *)data;

@end
