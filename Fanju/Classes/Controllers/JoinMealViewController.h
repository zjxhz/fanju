//
//  JoinMealViewController.h
//  Fanju
//
//  Created by Xu Huanze on 4/13/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MealInfo.h"

@interface JoinMealViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate>{
    IBOutlet UITableView* _tableView;
    IBOutlet UIButton* _confirmButton;
}
@property(nonatomic, strong) MealInfo* mealInfo;
@property(nonatomic) NSInteger numberOfPersons;
-(IBAction)joinMeal:(id)sender;
@end
