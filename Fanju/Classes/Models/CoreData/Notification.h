//
//  Notification.h
//  Fanju
//
//  Created by Xu Huanze on 5/22/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class User;

@interface Notification : NSManagedObject

@property (nonatomic, retain) NSString * eventDescription;
@property (nonatomic, retain) NSString * node;
@property (nonatomic, retain) NSString * payload;
@property (nonatomic, retain) NSNumber * read;
@property (nonatomic, retain) NSDate * time;
@property (nonatomic, retain) NSString * nID;
@property (nonatomic, retain) User *owner;
@property (nonatomic, retain) User *user;

@end
