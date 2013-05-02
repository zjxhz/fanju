//
//  MealInfo.h
//  EasyOrder
//
//  Created by igneus on 3/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RestaurantInfo.h"
#import "UserProfile.h"
#import "Const.h"

@protocol MealInfoDelegate <NSObject>
@optional
- (void) userJoined:(UserProfile*) user;
@end

typedef enum{
    THEMES,
    DATES,
}MealType;

@interface MealInfo : NSObject

@property (nonatomic) int mID;
@property (nonatomic) MealType type;
@property (nonatomic, copy) NSString *topic;
@property (nonatomic, copy) NSString *intro;
@property (nonatomic, copy) RestaurantInfo *restaurant;
@property (nonatomic, copy) NSDate *time;
@property (nonatomic) int maxPersons;
@property (nonatomic) int actualPersons;
@property (nonatomic, retain) NSMutableArray *participants;
@property (nonatomic, retain) NSMutableArray *likes;
@property (nonatomic, copy) UserProfile *host;
@property (nonatomic, copy) NSString *photoURL;
@property (nonatomic) double price;

+ (MealInfo *)mealInfoWithData:(NSDictionary *)data;

- (BOOL) hasJoined:(NSString*)userID;
- (BOOL) hasLiked:(NSString*)userID;

- (void) join:(UserProfile*) user;
- (void) join:(UserProfile*) user withTotalNumberOfPersons:(NSInteger)num_persons;
- (void) like:(UserProfile*) user;
- (void) dontLike:(UserProfile*) user;
- (NSString*) photoFullUrl;
- (NSComparisonResult)compare:(MealInfo *)other;
-(NSString*)timeText;
@end
