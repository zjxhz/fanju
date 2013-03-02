//
//  MealInvitation.h
//  EasyOrder
//
//  Created by 浣泽 徐 on 4/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UserProfile.h"
#import "MealInfo.h"

@interface MealInvitation : NSObject
@property (nonatomic) int mID;
@property (nonatomic, copy) UserProfile *from;
@property (nonatomic, copy) UserProfile *to;
@property (nonatomic, copy) MealInfo *meal;
@property (nonatomic, copy) NSDate *timestamp;

+ (MealInvitation *) mealInvitationWithData:(NSDictionary *) data;
@end