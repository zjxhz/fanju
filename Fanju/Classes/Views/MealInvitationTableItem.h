//
//  MealInvitationTableItem.h
//  EasyOrder
//
//  Created by 浣泽 徐 on 4/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Three20/Three20.h>
#import "MealInvitation.h"


@interface MealInvitationTableItem : TTTableImageItem
@property (nonatomic, copy) MealInvitation *mealInvitation;

+ (id)itemWithMealInvitation:(MealInvitation*) mealInvitation;

@end
