//
//  JoinMealEvent.h
//  Fanju
//
//  Created by Xu Huanze on 3/7/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import "EventBase.h"
#import "UserProfile.h"
#import "MealInfo.h"

@interface JoinMealEvent : EventBase
@property(nonatomic, strong) NSString* participantID;
@property(nonatomic, strong) UserProfile* participant;
@property(nonatomic, strong) NSString* mealID;
@property(nonatomic, strong) MealInfo* meal;
@end