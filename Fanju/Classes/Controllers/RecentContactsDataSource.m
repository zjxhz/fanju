//
//  RecentContactsDataSource.m
//  EasyOrder
//
//  Created by 徐 浣泽 on 11/4/12.
//
//

#import "RecentContactsDataSource.h"
#import "UserMessageTableItem.h"
#import "XMPPRecentContactCell.h"
#import "RecentContact.h"
#import "XMPPHandler.h"

@implementation RecentContactsDataSource
- (Class)tableView:(UITableView*)tableView cellClassForObject:(id) object {
	if ([object isKindOfClass:[RecentContact class]]){
        return [XMPPRecentContactCell class];
    }
    
	return [super tableView:tableView
	     cellClassForObject:object];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}


-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    RecentContact *contact = [self.items objectAtIndex:indexPath.row];
    [self.items removeObjectAtIndex:indexPath.row];
    [[XMPPHandler sharedInstance] deleteRecentContact:contact.contact];
    [tableView reloadData];
}
@end
