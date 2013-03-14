//
//  MealDetailsViewDelegate.m
//  EasyOrder
//
//  Created by Xu Huanze on 2/23/13.
//
//

#import "MealDetailsViewDelegate.h"
#import "MealDetailViewController.h"

@implementation MealDetailsViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return section > 1 ? 20 : 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    if (section > 1) {
        UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 20)];
        UILabel *separator = [[UILabel alloc] initWithFrame:CGRectMake(8, 10, 300, 2)];
        separator.backgroundColor = [UIColor colorWithRed:1 green:0x55/255.0 blue:0 alpha:1];
        [header addSubview:separator];
        return header;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    int section = indexPath.section;
    if(section == 0){
        return 140;
    } else if(section == 1){
        return _detailsHeight;
    }
    else {
        return 110;
    }
}

@end
