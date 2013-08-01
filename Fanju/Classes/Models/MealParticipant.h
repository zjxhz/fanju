//
//  MealParticipant.h
//  Fanju
//
//  Created by Xu Huanze on 7/30/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Meal.h"
#import "User.h"

@interface MealParticipant : NSObject
@property(nonatomic, strong) Meal* meal;
@property(nonatomic, strong) User* user;
@property(nonatomic, strong) NSNumber* mpID;
@end
