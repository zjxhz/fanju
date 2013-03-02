//
//  MealListDataSource.h
//  EasyOrder
//
//  Created by 浣泽 徐 on 6/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Three20/Three20.h>
#import "MealTableItem.h"

//TODO extends from TTSectionedDataSource
@interface MealListDataSource : TTListDataSource{
    NSMutableArray *_mealsForThisWeek;
    NSMutableArray *_mealsAfterThisWeek;
}


- (void) addMeal:(MealTableItem*)meal;
- (NSInteger) numberOfMealsForThisWeek;
- (NSInteger) numberOfMealsAfterThisWeek;

@end
