//
//  JoinMealViewController.h
//  Fanju
//
//  Created by Xu Huanze on 4/13/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Meal.h"

@interface JoinMealViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate, UIWebViewDelegate, UITextFieldDelegate>{
    IBOutlet UITableView* _tableView;
    IBOutlet UIButton* _confirmButton;
}
@property(nonatomic, strong) Meal* meal;
@property(nonatomic) NSInteger numberOfPersons;
-(IBAction)joinMeal:(id)sender;
@end
