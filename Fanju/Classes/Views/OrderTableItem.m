//
//  OrderTableItem.m
//  EasyOrder
//
//  Created by 浣泽 徐 on 6/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OrderTableItem.h"

@implementation OrderTableItem
@synthesize orderInfo = _orderInfo;

+(id)itemWithOrderInfo:(OrderInfo *)orderInfo{
    OrderTableItem *item = [[self alloc] init];
    item.orderInfo = orderInfo;
    return item;
}

-(id) initWithCoder:(NSCoder *)aDecoder{
    if( self = [super initWithCoder:aDecoder]) {
        self.orderInfo = [aDecoder decodeObjectForKey:@"orderInfo"];
    }
    
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder{
    [super encodeWithCoder:aCoder];
    
    if(self.orderInfo){
        [aCoder encodeObject:self.orderInfo forKey:@"orderInfo"];
    }
}
@end
