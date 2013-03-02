//
//  CommentListDataSource.m
//  EasyOrder
//
//  Created by 浣泽 徐 on 7/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CommentListDataSource.h"
#import "CommentTableItem.h"
#import "CommentTableItemCell.h"

@implementation CommentListDataSource
- (Class)tableView:(UITableView*)tableView cellClassForObject:(id) object {
	if ([object isKindOfClass:[CommentTableItem class]]) {  
		return [CommentTableItemCell class];  
	}
    
	return [super tableView:tableView
	     cellClassForObject:object];
}
@end
