//
//  OrderListDataSource.m
//  Fanju
//
//  Created by Xu Huanze on 4/17/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import "OrderListDataSource.h"
#import "LoadMoreTableItem.h"
#import "LoadMoreTableItemCell.h"
#import "MealThumbnailTableItemCell.h"

@implementation OrderListDataSource

- (Class)tableView:(UITableView*)tableView cellClassForObject:(id) object {
	if ([object isKindOfClass:[OrderInfo class]]) {
		return [MealThumbnailTableItemCell class];
	} else if ([object isKindOfClass:[LoadMoreTableItem class]]){
        return [LoadMoreTableItemCell class];
    }
    
	return [super tableView:tableView
	     cellClassForObject:object];
}

-(void)addOrder:(OrderInfo*)orderInfo{
    if (orderInfo.status == 1) {
        if (!_payingOrders) {
            _payingOrders = [NSMutableArray array];
        }
        [_payingOrders addObject:orderInfo];
    } else if ([orderInfo.meal.time timeIntervalSinceNow] < 0){
        if (!_passedOrders) {
            _passedOrders = [NSMutableArray array];
        }
        [_passedOrders addObject:orderInfo];
    } else {
        if (!_upcomingOrders){
            _upcomingOrders = [NSMutableArray array];
        }
        [_upcomingOrders addObject:orderInfo];
    }
}


#pragma mark -
#pragma mark TTTableViewDataSource

- (id)tableView:(UITableView*)tableView objectForRowAtIndexPath:(NSIndexPath*)indexPath {
    return [self dataForSection:indexPath.section][indexPath.row];
}

-(NSArray*)dataForSection:(NSInteger)section{
    NSArray* sectionData = nil;
    if (section == 0) {
        if (_payingOrders.count > 0) {
            sectionData = _payingOrders;
        } else if(_upcomingOrders.count > 0){
            sectionData = _upcomingOrders;
        } else {
            sectionData = _passedOrders;
        }
    } else if(section == 1){
        if(_payingOrders.count > 0){
            sectionData = _upcomingOrders > 0 ? _upcomingOrders : _passedOrders;
        } else{
            sectionData = _passedOrders;
        }
    } else {
        sectionData = _passedOrders;
    }
    return sectionData;
}

- (NSIndexPath*)tableView:(UITableView*)tableView indexPathForObject:(id)object {    
    NSUInteger row = [_payingOrders indexOfObject:object];
    if (row != NSNotFound) {
        return [NSIndexPath indexPathForRow:row inSection:0];
    }
    row = [_upcomingOrders indexOfObject:object];
    if (row != NSNotFound) {
        NSInteger section = _payingOrders.count > 0;
        return [NSIndexPath indexPathForRow:row inSection:section];
    }
    row = [_passedOrders indexOfObject:object];
    NSInteger section = (_payingOrders.count > 0) + (_upcomingOrders.count > 0);
    return [NSIndexPath indexPathForRow:row inSection:section];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self dataForSection:section].count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return (_payingOrders.count > 0) + (_upcomingOrders.count > 0) + (_passedOrders.count > 0);
}

@end