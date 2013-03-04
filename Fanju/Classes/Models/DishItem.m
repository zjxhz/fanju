//
//  DishItem.m
//  EasyOrder
//
//  Created by 浣泽 徐 on 8/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DishItem.h"

@implementation DishItem
@synthesize num=_num, orderNo=_orderNo, price=_price, name=_name;

-(DishItem*)initWithData:(NSDictionary*)data{
    if (self = [super init]) {
        _num = [[data objectForKey:@"num"] intValue];
        _orderNo = [[data objectForKey:@"order_no"] intValue];
        
        NSDictionary* dishData = [data objectForKey:@"dish"];
        _name = [dishData objectForKey:@"name"];
        _price = [[dishData objectForKey:@"price"] intValue];
    }
    return self;
}

+(DishItem*) itemWithData:(NSDictionary*)data{
    return [[DishItem alloc] initWithData:data];
}
@end
