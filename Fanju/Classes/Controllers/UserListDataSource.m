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

@implementation UserListDataSource

- (Class)tableView:(UITableView*)tableView cellClassForObject:(id) object {
    
	if ([object isKindOfClass:[UserTableItem class]]) {  
		return [UserTableItemCell class];  
	}
    
	return [super tableView:tableView
	     cellClassForObject:object];
}

@end
