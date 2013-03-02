//
//  DishImageCell.h
//  EasyOrder
//
//  Created by igneus on 12/17/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Dish.h"
#import "MenuTableView.h"

typedef void (^ImageTappedAction)(void);

@interface DishImageCell : UITableViewCell

@property (nonatomic, strong) Dish *dish;
@property (nonatomic) CellDisplayMode displayMode;
@property (nonatomic, strong) ImageTappedAction imageTappedAction;

@end
