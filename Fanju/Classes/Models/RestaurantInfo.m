//
//  RestaurantInfo.m
//  EasyOrder
//
//  Created by igneus on 2/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RestaurantInfo.h"
#import "NSDictionary+ParseHelper.h"

@implementation RestaurantInfo

@synthesize coordinate = _coordinate, address = _address, name = _name;   
@synthesize tel = _tel, rID = _rID;

- (id)initWithData:(NSDictionary *)data {
    if (self = [super init]) {
        _name = [data objectForKey:@"name"];
        _address = [data objectForKey:@"address"];
        id obj = [data objectForKey:@"longitude"];
        if (obj && ![obj isKindOfClass:[NSNull class]]) {
            _coordinate.longitude = [obj doubleValue];
        }
        obj = [data objectForKey:@"latitude"];
        if (obj && ![obj isKindOfClass:[NSNull class]]) {
            _coordinate.latitude = [obj doubleValue];
        }
        _tel = [data objectForKey:@"tel"];
        _rID = [[data objectForKey:@"id"] intValue];
    }
    
    return self;
}

+ (RestaurantInfo *)restaurantWithData:(NSDictionary *)data {
    return [[RestaurantInfo alloc] initWithData:data];
}

- (id)copyWithZone:(NSZone *)zone {
    RestaurantInfo *info = [[RestaurantInfo allocWithZone:zone] init];
    info.name = _name;
    info.address = _address;
    info.tel = _tel;
    info.rID = _rID;
    info.coordinate = _coordinate;
    return info;
}

@end
