//
//  MealListDataSource.h
//  EasyOrder
//
//  Created by 浣泽 徐 on 6/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Three20/Three20.h>
#import "MealTableItem.h"
#import "Meal.h"

@interface MealListDataSource : TTTableViewDataSource{
    NSMutableArray *_mealsForThisWeek;
    NSMutableArray *_mealsAfterThisWeek;
    NSMutableArray* _passedMeals;
}


- (void) addMeal:(Meal*)meal;
- (NSInteger) numberOfMealsForThisWeek;
- (NSInteger) numberOfMealsAfterThisWeek;

@end
