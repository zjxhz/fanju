//
//  MealNotification.h
//  Fanju
//
//  Created by Xu Huanze on 5/17/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Notification.h"

@class Meal;

@interface MealNotification : Notification

@property (nonatomic, retain) Meal *meal;

@end
