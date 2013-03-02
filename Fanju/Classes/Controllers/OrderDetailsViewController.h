//
//  OrderDetailsViewController.h
//  EasyOrder
//
//  Created by 浣泽 徐 on 7/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Three20/Three20.h"
#import "MealInfo.h"

@interface OrderDetailsViewController : TTViewController

@property (weak, nonatomic) IBOutlet UILabel *restaurant;
@property (weak, nonatomic) IBOutlet UILabel *time;
@property (strong, nonatomic) TTImageView *mealImage;
@property (weak, nonatomic) MealInfo* meal;
@property (weak, nonatomic) IBOutlet UILabel* codeLabel;
@property (copy, nonatomic) NSString* code;
@property NSInteger numerOfPersons;
@end
