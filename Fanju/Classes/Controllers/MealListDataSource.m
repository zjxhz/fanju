//
//  MealListDataSource.m
//  EasyOrder
//
//  Created by 浣泽 徐 on 6/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MealListDataSource.h"
#import "MealCell.h"
#import "Meal.h"
#import "MealService.h"

@implementation MealListDataSource
-(id)init{
    if (self = [super init]) {
        _mealsForThisWeek = [NSMutableArray array];
        _mealsAfterThisWeek = [NSMutableArray array];
        _passedMeals = [NSMutableArray array];
    }
    return self;
}

- (Class)tableView:(UITableView*)tableView cellClassForObject:(id) object {
    
	if ([object isKindOfClass:[Meal class]]) {
		return [MealCell class];
	}
    
	return [super tableView:tableView
	     cellClassForObject:object];
}

- (NSInteger) numberOfMealsForThisWeek{
    return _mealsForThisWeek.count;
}

-(NSInteger) numberOfMealsAfterThisWeek{
    return _mealsAfterThisWeek.count;
}

-(BOOL) isWithinThisWeek:(NSDate *)date{
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *comps = [cal components:NSYearCalendarUnit | NSWeekCalendarUnit fromDate:[NSDate date]];
    [comps setWeekday:1]; //Last Sunday is the first day in a week for westners 
    [comps setHour:23];
    [comps setMinute:59];
    [comps setSecond:59];//23:59:59 is the last moment in a day
    [comps setWeek:(comps.week + 1)]; //This Sunday for Chinese...
    NSDate *thisSunday = [cal dateFromComponents:comps];
    return [date timeIntervalSinceDate:thisSunday] <= 0;
}


- (void)addMeal:(Meal*)meal{
    NSDate* time = [MealService dateOfMeal:meal];
    if([time timeIntervalSinceNow] < 0 ){
        [_passedMeals addObject:meal];
        DDLogVerbose(@"added out of dated meal at: %@", time);
        [_passedMeals sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            return [[MealService dateOfMeal:obj1] compare:[MealService dateOfMeal:obj2]];
        }];
    } else if([self isWithinThisWeek:time]){
        [_mealsForThisWeek addObject:meal];
        DDLogVerbose(@"added a meal to this week: %@", time);
        [_mealsForThisWeek sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            return [[MealService dateOfMeal:obj1] compare:[MealService dateOfMeal:obj2]];
        }];
    } else {
        [_mealsAfterThisWeek addObject:meal];
        DDLogVerbose(@"added a meal to next week: %@", time);
        [_mealsAfterThisWeek sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            return [[MealService dateOfMeal:obj1] compare:[MealService dateOfMeal:obj2]];
        }];
    }
}

#pragma mark -
#pragma mark TTTableViewDataSource

- (id)tableView:(UITableView*)tableView objectForRowAtIndexPath:(NSIndexPath*)indexPath {
    return [self mealsForSection:indexPath.section][indexPath.row];
//    int row = indexPath.row;	
//    int section = indexPath.section;
//    if (section == 0) {
//        if ([self numberOfMealsForThisWeek] > 0 && row < _mealsForThisWeek.count) {
//            return [_mealsForThisWeek objectAtIndex:row];
//        } else if(row < _mealsAfterThisWeek.count) {
//            return [_mealsAfterThisWeek objectAtIndex:row];
//        }
//    }
//    else { // section == 1 means there are meals both for this week and after this week
//        return [_mealsAfterThisWeek objectAtIndex:row];
//    }
//    return nil;
}

-(NSArray*)mealsForSection:(NSInteger)section{
    if (section == 0) {
        if (_mealsForThisWeek.count > 0) {
            return _mealsForThisWeek;
        } else if(_mealsAfterThisWeek.count > 0){
            return _mealsAfterThisWeek;
        } else {
            return _passedMeals;
        }
    } else if (section == 1) {
        if(_mealsForThisWeek.count == 0){
            return _passedMeals;
        } else if(_mealsAfterThisWeek.count > 0) {
            return _mealsAfterThisWeek;
        }
        return _passedMeals;
    } else {
        return _passedMeals;
    }
}

- (NSIndexPath*)tableView:(UITableView*)tableView indexPathForObject:(id)object {
    NSUInteger objectIndex = [_mealsForThisWeek indexOfObject:object];
    if (objectIndex != NSNotFound) {
        return [NSIndexPath indexPathForRow:objectIndex inSection:0];
    }
    objectIndex = [_mealsAfterThisWeek indexOfObject:object];
    if (objectIndex != NSNotFound) {
        return [NSIndexPath indexPathForRow:objectIndex inSection:1];
    }
    objectIndex = [_passedMeals indexOfObject:object];
    if (objectIndex != NSNotFound) {
        return [NSIndexPath indexPathForRow:objectIndex inSection:2];
    }
    return nil;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self mealsForSection:section].count;
//    if (section == 0) {
//        if ([self numberOfMealsForThisWeek] > 0) {
//            return [self numberOfMealsForThisWeek];
//        } else if([self numberOfMealsAfterThisWeek] > 0){
//            return [self numberOfMealsAfterThisWeek];
//        } else {
//            return _passedMeals.count;
//        }
//    } else if (section == 1) {
//        if([self numberOfMealsAfterThisWeek] > 0){
//            return [self numberOfMealsAfterThisWeek];
//        } else {
//            return _passedMeals.count;
//        }
//    } else {
//        return _passedMeals.count;
//    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    NSInteger count = _mealsForThisWeek.count > 0 ? 1 : 0;
    count += _mealsAfterThisWeek.count > 0 ? 1 : 0;
    count += _passedMeals.count > 0 ? 1 : 0;
    return count;
}

@end
