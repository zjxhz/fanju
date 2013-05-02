//
//  MenuViewController.h
//  Fanju
//
//  Created by Xu Huanze on 5/1/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MealMenu.h"
@interface MenuViewController : UIViewController<UITableViewDataSource, UITableViewDelegate>
@property(nonatomic, strong) MealMenu* mealMenu;
@property(nonatomic, weak) IBOutlet UITableView* tableView;
@property(nonatomic, weak) IBOutlet UIButton* closeButton;
@end
