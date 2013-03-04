//
//  CategoryItem.m
//  EasyOrder
//
//  Created by 浣泽 徐 on 8/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CategoryItem.h"

@implementation CategoryItem
@synthesize orderNo=_orderNo, name=_name;

-(CategoryItem*)initWithData:(NSDictionary*)data{
    if (self = [super init]) {
        _orderNo = [[data objectForKey:@"order_no"] intValue];
        NSDictionary* categoryData = [data objectForKey:@"category"];
        _name = [categoryData objectForKey:@"name"];

    }
    return self;
}

+(CategoryItem*) itemWithData:(NSDictionary*)data{
    return [[CategoryItem alloc] initWithData:data];
}
@end
