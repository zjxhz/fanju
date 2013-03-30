//
//  UserListDataSource.m
//  EasyOrder
//
//  Created by igneus on 3/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UserListDataSource.h"
#import "UserTableItem.h"
#import "UserTableItemCell.h"
#import "LoadMoreTableItem.h"
#import "LoadMoreTableItemCell.h"
@implementation UserListDataSource

- (Class)tableView:(UITableView*)tableView cellClassForObject:(id) object {
    
	if ([object isKindOfClass:[UserTableItem class]]) {  
		return [UserTableItemCell class];  
	} else if([object isKindOfClass:[LoadMoreTableItem class]]){
        return [LoadMoreTableItemCell class];
    }
    
	return [super tableView:tableView
	     cellClassForObject:object];
}

@end
