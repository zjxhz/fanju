//
//  MealDetailDataSource.m
//  EasyOrder
//
//  Created by 浣泽 徐 on 6/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MealDetailDataSource.h"
#import "MealDetailCell.h"
#import "MealCommentCell.h"


@implementation MealDetailDataSource{
    BOOL cellHeightCalculated;
}

- (Class)tableView:(UITableView*)tableView cellClassForObject:(id)object{
    if ([object isKindOfClass:[Meal class]]) {
        return [MealDetailCell class];
    } else if([object isKindOfClass:[MealComment class]]){
        return [MealCommentCell class];
    }
    return [super tableView:tableView cellClassForObject:object];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 2;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (section == 0) {
        return 1;
    }
    if (_comments.count > 0) {
        return _comments.count;
    } else {
        return 1; //loading comments or no commets
    }
}

- (id)tableView:(UITableView*)tableView objectForRowAtIndexPath:(NSIndexPath*)indexPath {
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            return _meal;
        }
    } else if(indexPath.section == 1) {
        if (!_comments) {
            if (_loadFail) {
                return [TTTableActivityItem itemWithText:@"评论加载失败"];
            }
            return [TTTableActivityItem itemWithText:@"加载中……"];
        } else if(_comments.count == 0){
            return [TTTableTextItem itemWithText:@"还没有评论，写下你的问题或期望吧"];
        }
        return _comments[indexPath.row];
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
    if ([cell isKindOfClass:[MealCommentCell class]]) {
        MealCommentCell* commentCell = (MealCommentCell*)cell;
        commentCell.parentController = _controller;
    }
    if ([cell isKindOfClass:[TTTableTextItemCell class]]) {
        cell.textLabel.font = [UIFont systemFontOfSize:12];
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

- (NSIndexPath*)tableView:(UITableView*)tableView indexPathForObject:(id)object{
    if ([object isKindOfClass:[MealComment class]]) {
        NSInteger objectIndex = [_comments indexOfObject:object];
        if (objectIndex != NSNotFound) {
            return [NSIndexPath indexPathForRow:objectIndex inSection:1];
        } else {
            return nil;
        }
    }
    if ([object isKindOfClass:[Meal class]]) {
        return [NSIndexPath indexPathForRow:0 inSection:0];
    }
    return [NSIndexPath indexPathForRow:0 inSection:1];
    
}
@end
