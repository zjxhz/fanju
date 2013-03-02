//
//  OrderTableItem.h
//  EasyOrder
//
//  Created by 浣泽 徐 on 6/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Three20/Three20.h>
#import "OrderInfo.h"


@interface OrderTableItem : TTTableImageItem
@property(nonatomic, copy) OrderInfo *orderInfo;
+(id)itemWithOrderInfo:(OrderInfo*)orderInfo;
@end
