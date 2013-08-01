//
//  Order.h
//  Fanju
//
//  Created by Xu Huanze on 7/23/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Meal, User;

@interface Order : NSManagedObject

@property (nonatomic, retain) NSString * code;
@property (nonatomic, retain) NSDate * createdTime;
@property (nonatomic, retain) NSNumber * numberOfPersons;
@property (nonatomic, retain) NSNumber * oID;
@property (nonatomic, retain) NSDate * paidTime;
@property (nonatomic, retain) NSNumber * status;
@property (nonatomic, retain) Meal *meal;
@property (nonatomic, retain) User *user;

@end
