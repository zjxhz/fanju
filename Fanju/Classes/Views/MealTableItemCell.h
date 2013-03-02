//
//  MealTableItemCell.h
//  EasyOrder
//
//  Created by igneus on 3/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Three20/Three20.h>
#import "UserProfile.h"

@interface MealTableItemCell : TTTableLinkedItemCell
-(void)setMealImage:(UIImage*)mealImage;
-(void)setAvatar:(UIImage*)image forUser:(UserProfile*)user;
@end
