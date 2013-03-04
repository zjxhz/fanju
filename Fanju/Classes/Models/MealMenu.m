//
//  MealMenu.m
//  EasyOrder
//
//  Created by 浣泽 徐 on 8/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MealMenu.h"
#import "DishItem.h"
#import "CategoryItem.h"
#import "OrderedObject.h"

@implementation MealMenu
@synthesize averagePrice=_averagePrice, mID=_mID, numberOfPersons=_numberOfPersons, dishes=_dishes, categories=_categories;


- (MealMenu *)initWithData:(NSDictionary *)data {
    if (self = [super init]) {
        _mID = [[data objectForKey:@"id"] intValue];
        _averagePrice = [[data objectForKey:@"average_price"] intValue];
        _numberOfPersons = [[data objectForKey:@"num_persons"] intValue];
        
        _dishes = [NSMutableArray array];
        for (NSDictionary *dict in [data objectForKey:@"dishitem_set"]) {
            [_dishes addObject: [DishItem itemWithData:dict]];
        }
        _categories = [NSMutableArray array];
        for (NSDictionary *dict in [data objectForKey:@"dishcategoryitem_set"]) {
            [_categories addObject: [CategoryItem itemWithData:dict]];
        }
    }
    
    return self;
}

+ (MealMenu *)mealMenuWithData:(NSDictionary *)data {
    return [[MealMenu alloc] initWithData:data];
}

-(NSArray*) groupedDishes{
    if (!_groupedDishes) {
        NSMutableArray* dishesAndCategories = [NSMutableArray arrayWithArray:_dishes];
        [dishesAndCategories addObjectsFromArray:_categories];
        [dishesAndCategories sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            id<OrderedObject> oo1 = obj1;
            id<OrderedObject> oo2 = obj2;
            return [oo1 orderNo] - [oo2 orderNo];
        }];
        _groupedDishes = [NSMutableArray array];
        NSMutableArray* group = [NSMutableArray array];
        for (id obj in dishesAndCategories) {
            if ([obj isKindOfClass:[CategoryItem class]]) {
                group = [NSMutableArray array];
                [_groupedDishes addObject:group];
            } else {
                [group addObject:obj];
            }
        }
    }         
      
    return _groupedDishes;
}


@end
