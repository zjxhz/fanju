//
//  MealService.m
//  Fanju
//
//  Created by Xu Huanze on 5/13/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import "MealService.h"
#import "RestKit.h"
#import "Meal.h"
#import "DateUtil.h"
#import "Order.h"

static NSDateFormatter *_dateFormatter;

@implementation MealService{
    NSManagedObjectContext* _contex;
    NSFetchRequest* _fetchRequest;
}

+(void)initialize{
    if (!_dateFormatter) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateFormat:@"YYYY年M月d日 HH:mm"];
    }
}

+(MealService*)service{
    static dispatch_once_t onceToken;
    static MealService* instance = nil;
    dispatch_once(&onceToken,^{
        instance = [[MealService alloc] init];
    });
    return instance;
}

-(id)init{
    self = [super init];
    RKManagedObjectStore* store = [RKObjectManager sharedManager].managedObjectStore;
    _contex = store.mainQueueManagedObjectContext;
    _fetchRequest = [[NSFetchRequest alloc] init];
    _fetchRequest.entity = [NSEntityDescription entityForName:@"Meal" inManagedObjectContext:_contex];
    return self;
}

-(Meal*)getOrFetchMeal:(NSString*)mealID success:(fetch_meal_success)success failure:(void (^)(void))failure{
    _fetchRequest.predicate = [NSPredicate predicateWithFormat:@"mID=%@", mealID];
    NSError* error = nil;
    NSArray* objects = [_contex executeFetchRequest:_fetchRequest error:&error];
    if (error) {
        DDLogError(@"ERROR: failed to fetch meal(%@) from coredata", mealID);
    } else if(objects.count == 0){
        DDLogVerbose(@"meal %@ not found in core data, fetching from server", mealID);
        [self fetchMealWithID:mealID success:success failure:failure];
    } else if(objects.count  > 0){
        NSAssert(objects.count == 1, @"find more than one meal with same ID: %@", mealID);
        return objects[0];
    }
    return nil;
}

-(void)fetchMealWithID:(NSString*)mID success:(fetch_meal_success)success failure:(void (^)(void))failure{
    RKObjectManager *manager = [RKObjectManager sharedManager];
    [manager getObjectsAtPath:@"meal/"
                   parameters:@{@"id":mID}
                      success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                          DDLogVerbose(@"results from /meal/");
                          NSArray* fetchedMeals = mappingResult.array;
                          NSAssert(fetchedMeals.count == 1, @"fetched not exact one meal for ID: %@", mID);
                          Meal* meal = fetchedMeals[0];
                          success(meal);
                      }
                      failure:^(RKObjectRequestOperation *operation, NSError *error) {
                          DDLogError(@"failed from /meal/: %@", error);
                          failure();
                      }];
}

//fetch meal from core data, nil if not exist
-(Meal*)mealWithID:(NSString*)mID{
    _fetchRequest.predicate = [NSPredicate predicateWithFormat:@"mID=%@", mID];
    NSError* error = nil;
    NSArray* objects = [_contex executeFetchRequest:_fetchRequest error:&error];
    if (error) {
        DDLogError(@"ERROR: failed to fetch meal(%@) from coredata", mID);
    } else if(objects.count  > 0){
        NSAssert(objects.count == 1, @"find more than one meal with same ID: %@", mID);
        return objects[0];
    }
    return nil;
}

+(NSDate*)dateOfMeal:(Meal*)meal{
    NSString *t = [NSString stringWithFormat:@"%@T%@", meal.startDate, meal.startTime];
    return [DateUtil dateFromString:t];
}

+(NSString*)dateTextOfMeal:(Meal*)meal{
    NSDate* date = [MealService dateOfMeal:meal];
    return [NSString stringWithFormat: @"%@ %@", [DateUtil weekday:date], [_dateFormatter stringFromDate:date]];
}

+(NSArray*)participantsOfMeal:(Meal*)meal{
    NSMutableArray* participants = [NSMutableArray array];
    for (Order* order in meal.orders) {
        [participants addObject:order.user];
        for (NSInteger i = 1; i < [order.numberOfPersons integerValue]; ++i) {
            [participants addObject:[UserService createGuestOf:order.user]];
        }
    }
    return participants;
}
@end
