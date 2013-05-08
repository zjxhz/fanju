//
//  Notification.h
//  Fanju
//
//  Created by Xu Huanze on 5/6/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class User;

@interface Notification : NSManagedObject

@property (nonatomic, retain) NSString * node;
@property (nonatomic, retain) NSString * payload;
@property (nonatomic, retain) NSString * time;
@property (nonatomic, retain) User *owner;

@end
