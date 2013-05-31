//
//  MealService.h
//  Fanju
//
//  Created by Xu Huanze on 5/13/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Meal.h"
typedef void(^fetch_meal_success)(Meal*);

@interface MealService : NSObject
+(MealService*)service;
-(Meal*)getOrFetchMeal:(NSString*)mealID success:(fetch_meal_success)success failure:(void (^)(void))failure;
-(Meal*)mealWithID:(NSString*)mID;
+(NSDate*)dateOfMeal:(Meal*)meal;
+(NSString*)dateTextOfMeal:(Meal*)meal;
+(NSArray*)participantsOfMeal:(Meal*)meal;
@end
