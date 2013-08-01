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
    return section;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    if (section == 0) {
        return nil;
    }
    UIImage* sep = [UIImage imageNamed:@"meal_detail_sep"];
    UIImageView* view = [[UIImageView alloc] initWithImage:sep];
    return view;
}
@end
