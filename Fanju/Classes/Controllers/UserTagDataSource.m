//
//  UserTagDataSource.m
//  EasyOrder
//
//  Created by 徐 浣泽 on 1/29/13.
//
//

#import "UserTagDataSource.h"
#import "UserTag.h"
#import "UserTagCell.h"

@implementation UserTagDataSource
-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    return indexPath.row != 0;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    [self.items removeObjectAtIndex:indexPath.row];
    [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (Class)tableView:(UITableView*)tableView cellClassForObject:(id)object{
    if ([object isKindOfClass:[UserTag class]]) {
        return [UserTagCell class];
    }
    return [super tableView:tableView cellClassForObject:object];
}
@end
