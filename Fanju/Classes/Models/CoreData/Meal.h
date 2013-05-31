//
//  Meal.h
//  Fanju
//
//  Created by Xu Huanze on 5/30/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Order, Restaurant;

@interface Meal : NSManagedObject

@property (nonatomic, retain) NSNumber * actualPersons;
@property (nonatomic, retain) NSString * introduction;
@property (nonatomic, retain) NSNumber * maxPersons;
@property (nonatomic, retain) NSNumber * mID;
@property (nonatomic, retain) NSString * photoURL;
@property (nonatomic, retain) NSNumber * price;
@property (nonatomic, retain) NSString * startDate;
@property (nonatomic, retain) NSString * startTime;
@property (nonatomic, retain) NSString * topic;
@property (nonatomic, retain) Restaurant *restaurant;
@property (nonatomic, retain) NSSet *orders;
@end

@interface Meal (CoreDataGeneratedAccessors)

- (void)addOrdersObject:(Order *)value;
- (void)removeOrdersObject:(Order *)value;
- (void)addOrders:(NSSet *)values;
- (void)removeOrders:(NSSet *)values;

@end
