//
//  Meal.h
//  Fanju
//
//  Created by Xu Huanze on 5/6/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Restaurant, User;

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
@property (nonatomic, retain) User *host;
@property (nonatomic, retain) NSSet *participants;
@property (nonatomic, retain) Restaurant *restaurant;
@end

@interface Meal (CoreDataGeneratedAccessors)

- (void)addParticipantsObject:(User *)value;
- (void)removeParticipantsObject:(User *)value;
- (void)addParticipants:(NSSet *)values;
- (void)removeParticipants:(NSSet *)values;

@end
