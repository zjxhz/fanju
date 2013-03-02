//
//  DistanceUtil.m
//  EasyOrder
//
//  Created by 浣泽 徐 on 7/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DistanceUtil.h"
#import "Authentication.h"
#define UNKNOWN_DISTANCE  @"距离未知"

@implementation DistanceUtil
+(NSString*) distanceToMe:(UserProfile*)user{
    if (![[Authentication sharedInstance] isLoggedIn]) {
        return UNKNOWN_DISTANCE;
    }
    
    UserProfile *me = [[Authentication sharedInstance] currentUser];
    CLLocation *myLocation = [[CLLocation alloc] initWithLatitude:me.coordinate.latitude longitude:me.coordinate.longitude];
    CLLocation *userLocation = [[CLLocation alloc] initWithLatitude:user.coordinate.latitude longitude:user.coordinate.longitude];
    double distanceMeters = [userLocation distanceFromLocation:myLocation];
    return [DistanceUtil getUserFriendlyDistance:distanceMeters]; 
}

+(NSString*)getUserFriendlyDistance:(double)meters{
    return [NSString stringWithFormat:@"%.2f公里", meters/1000];
}
@end
