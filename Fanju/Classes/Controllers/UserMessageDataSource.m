//
//  UserMessageDataSource.m
//  EasyOrder
//
//  Created by 徐 浣泽 on 11/6/12.
//
//

#import "UserMessageDataSource.h"
#import "UserMessageTableItem.h"
#import "EOMessage.h"
#import "UserMessageCell.h"

@implementation UserMessageDataSource
- (Class)tableView:(UITableView*)tableView cellClassForObject:(id) object {
	if ([object isKindOfClass:[UserMessageTableItem class]]) {
		return [UserMessageCell class];
	} else if ([object isKindOfClass:[EOMessage class]]){
        return [UserMessageCell class];
    }
    
	return [super tableView:tableView
	     cellClassForObject:object];
}
@end
