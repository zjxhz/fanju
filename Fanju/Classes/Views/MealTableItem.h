//
//  MealTableItem.h
//  EasyOrder
//
//  Created by igneus on 3/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Three20/Three20.h>
#import "MealInfo.h"

@interface MealTableItem : TTTableImageItem

@property (nonatomic, strong) MealInfo *mealInfo;

+ (id)itemWithMealInfo:(MealInfo*)mealInfo;

@end
