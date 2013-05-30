//
//  DistanceUtil.m
//  EasyOrder
//
//  Created by 浣泽 徐 on 7/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DistanceUtil.h"
#import "Authentication.h"
#import "User.h"
#import "UserService.h"
#define UNKNOWN_DISTANCE  @"非常遥远"

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

+(NSString*)distanceFrom:(User*)user{
    User *me = [UserService service].loggedInUser;
    CLLocation *myLocation = [DistanceUtil locationOfUser:me];
    CLLocation *userLocation = [DistanceUtil locationOfUser:user];
    double distanceMeters = [userLocation distanceFromLocation:myLocation];
    return [DistanceUtil getUserFriendlyDistance:distanceMeters];
}

+(CLLocation*)locationOfUser:(User*)user{
    return [[CLLocation alloc] initWithLatitude:[user.latitude floatValue] longitude:[user.longitude floatValue]];
}
+(NSString*)getUserFriendlyDistance:(double)meters{
    double kms = meters/1000;
    if (kms > 100) {
        return [NSString stringWithFormat:@"%.0fkm", kms];
    }
    return [NSString stringWithFormat:@"%.2fkm", kms];
}
@end
