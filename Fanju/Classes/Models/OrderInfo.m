//
//  OrderInfo.m
//  EasyOrder
//
//  Created by 浣泽 徐 on 6/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OrderInfo.h"
#import "ModelHelper.h"
#import "ModelHelper.h"

@implementation OrderInfo

+(OrderInfo*) orderInfoWithData:(NSDictionary*) data{
    return [[OrderInfo alloc] initWithData:data];
}

- (OrderInfo *)initWithData:(NSDictionary *)data {
    if (self = [super init]) {
        _oID = [[data objectForKey:@"id"] intValue];
        _meal = [MealInfo mealInfoWithData:[data objectForKey:@"meal"]];
        _numerOfPersons =  [[data objectForKey:@"num_persons"] intValue];
        _code = [ModelHelper stringValueForKey:@"code" inDictionary:data];
        _customer = [UserProfile profileWithData:[data objectForKey:@"customer"]];
        _createdTime = [ModelHelper dateValueForKey:@"created_time" inDictionary:data];
    }
    
    return self;
}

-(id)copyWithZone:(NSZone*) zone{
    OrderInfo *info = [[OrderInfo allocWithZone:zone] init];
    info.oID = _oID;
    info.meal = _meal;
    info.numerOfPersons = _numerOfPersons;
    info.code = _code;
    info.customer = _customer;
    info.createdTime = _createdTime;
    return info;
}
@end
