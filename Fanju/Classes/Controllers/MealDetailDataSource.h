//
//  MealDetailDataSource.h
//  EasyOrder
//
//  Created by 浣泽 徐 on 6/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Three20/Three20.h>
#import "Meal.h"

@interface MealDetailDataSource : TTTableViewDataSource
@property(nonatomic, strong) Meal* meal;
@property(nonatomic, weak) UIViewController* controller;
-(void)tableView:(UITableView*)tableView contentOffsetDidChange:(CGFloat)offset;
@end
