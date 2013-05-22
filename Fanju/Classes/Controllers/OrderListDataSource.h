//
//  OrderListDataSource.h
//  Fanju
//
//  Created by Xu Huanze on 4/17/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import "TTSectionedDataSource.h"
#import "Order.h"
#import "LoadMoreTableItem.h"

@interface OrderListDataSource : TTTableViewDataSource
@property(nonatomic, readonly) NSMutableArray* payingOrders;
@property(nonatomic, readonly) NSMutableArray* upcomingOrders;
@property(nonatomic, readonly) NSMutableArray* passedOrders;
-(void)addOrder:(Order*)orderInfo;
@property(nonatomic, strong) LoadMoreTableItem* loadMoreItem;
@end
