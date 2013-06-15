//
//  MealDetailCell.h
//  Fanju
//
//  Created by Xu Huanze on 6/14/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import "TTTableViewCell.h"
#import "NINetworkImageView.h"

@interface MealDetailCell : TTTableViewCell
@property(nonatomic, strong) UIButton *mapButton;
@property(nonatomic, strong) NINetworkImageView* mealImageView;
+(CGFloat) cellHeight;
@property(nonatomic, weak) UIViewController* controller;
-(void)tableView:(UITableView*)tableView contentOffsetDidChange:(CGFloat)offset;
@end
