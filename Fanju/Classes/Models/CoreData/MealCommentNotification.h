//
//  MealCommentNotification.h
//  Fanju
//
//  Created by Xu Huanze on 7/29/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Notification.h"

@class MealComment;

@interface MealCommentNotification : Notification

@property (nonatomic, retain) MealComment *comment;

@end
