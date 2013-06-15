//
//  MealDetailDataSource.m
//  EasyOrder
//
//  Created by 浣泽 徐 on 6/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MealDetailDataSource.h"
#import "MealDetailCell.h"

@implementation MealDetailDataSource{
    BOOL cellHeightCalculated;
}

- (Class)tableView:(UITableView*)tableView cellClassForObject:(id)object{
    if ([object isKindOfClass:[Meal class]]) {
        return [MealDetailCell class];
    }
    return nil;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 1;
}

- (id)tableView:(UITableView*)tableView objectForRowAtIndexPath:(NSIndexPath*)indexPath {
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            return _meal;
        }
    }
    return nil;
}

-(void)tableView:(UITableView *)tableView cell:(UITableViewCell *)cell willAppearAtIndexPath:(NSIndexPath *)indexPath{
    [super tableView:tableView cell:cell willAppearAtIndexPath:indexPath];
    if ([cell isKindOfClass:[MealDetailCell class]]) {
        MealDetailCell* detailCell = (MealDetailCell*)cell;
        detailCell.controller = _controller;
    }
    if (!cellHeightCalculated) {
        [tableView reloadData];
        cellHeightCalculated = YES;
    }
}

-(void)tableView:(UITableView*)tableView contentOffsetDidChange:(CGFloat)offset{
    for (id cell in tableView.visibleCells) {
        if ([cell isKindOfClass:[MealDetailCell class]]) {
            MealDetailCell* detailCell = cell;
            [detailCell tableView:tableView contentOffsetDidChange:offset];
            break;
        }
    }
}
@end
