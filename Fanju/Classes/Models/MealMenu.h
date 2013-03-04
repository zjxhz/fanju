//
//  MealMenu.h
//  EasyOrder
//
//  Created by 浣泽 徐 on 8/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MealMenu : NSObject{
    NSMutableArray* _groupedDishes;
}
@property NSInteger averagePrice;
@property NSInteger mID;
@property NSInteger numberOfPersons;
@property(nonatomic, strong) NSMutableArray* dishes;
@property(nonatomic, strong) NSMutableArray* categories;

- (MealMenu *)initWithData:(NSDictionary *)data;
+ (MealMenu *)mealMenuWithData:(NSDictionary *)data;
- (NSArray*) groupedDishes;
@end
