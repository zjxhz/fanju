//
//  MealListDataSource.m
//  EasyOrder
//
//  Created by 浣泽 徐 on 6/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MealListDataSource.h"
#import "MealTableItemCell.h"
@implementation MealListDataSource

- (id)init{
    return [self initWithItems:[[NSMutableArray alloc]init]] ;
}
- (id)initWithItems:(NSArray*)items {
	self = [super init];
    if (self) {
        _items = [items mutableCopy];
        [self groupMeals];
    }
    return self;
}

- (Class)tableView:(UITableView*)tableView cellClassForObject:(id) object {
    
	if ([object isKindOfClass:[MealTableItem class]]) {  
		return [MealTableItemCell class];  
	}
    
	return [super tableView:tableView
	     cellClassForObject:object];
}

//Group meals by weeks, i.e. this week and after this week
-(void) groupMeals{
    _mealsForThisWeek = [[NSMutableArray alloc] init];
    _mealsAfterThisWeek = [[NSMutableArray alloc] init];
    for(NSObject *obj in _items){
        MealTableItem *meal = (MealTableItem *)obj;
        [self addMeal:meal];
    }
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


- (void)addMeal:(MealTableItem*)meal{
    if([meal.mealInfo.time timeIntervalSinceNow] < 0 ){
//        NSLog(@"ignore out of dated meal at: %@", meal.mealInfo.time);
        return;
    }
    if([self isWithinThisWeek:meal.mealInfo.time]){
        [_mealsForThisWeek addObject:meal];
        [_mealsForThisWeek sortUsingSelector:@selector(compare:)];
    } else {
        [_mealsAfterThisWeek addObject:meal];
        [_mealsAfterThisWeek sortUsingSelector:@selector(compare:)];
    }
}

#pragma mark -
#pragma mark TTTableViewDataSource

- (id)tableView:(UITableView*)tableView objectForRowAtIndexPath:(NSIndexPath*)indexPath {
    int row = indexPath.row;	
    int section = indexPath.section;
    if (section == 0) {
        if ([self numberOfMealsForThisWeek] > 0 && row < _mealsForThisWeek.count) {
            return [_mealsForThisWeek objectAtIndex:row];
        } else if(row < _mealsAfterThisWeek.count) {
            return [_mealsAfterThisWeek objectAtIndex:row];
        }
    }
    else { // section == 1 means there are meals both for this week and after this week
        return [_mealsAfterThisWeek objectAtIndex:row];
    }
    return nil;
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
    return nil;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        if ([self numberOfMealsForThisWeek] > 0) {
            return [self numberOfMealsForThisWeek];
        } else {
            return [self numberOfMealsAfterThisWeek];
        }
    }
    else { // section == 1 means there are meals both for this week and after this week
        return [self numberOfMealsAfterThisWeek];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    NSInteger count = _mealsForThisWeek.count > 0 ? 1 : 0;
    count += _mealsAfterThisWeek.count > 0 ? 1 : 0;
    return count;
}

@end
