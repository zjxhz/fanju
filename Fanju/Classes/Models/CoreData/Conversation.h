//
//  Conversation.h
//  Fanju
//
//  Created by Xu Huanze on 5/6/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class User;

@interface Conversation : NSManagedObject

@property (nonatomic, retain) NSNumber * incoming;
@property (nonatomic, retain) NSString * message;
@property (nonatomic, retain) NSDate * time;
@property (nonatomic, retain) NSNumber * unread;
@property (nonatomic, retain) User *owner;
@property (nonatomic, retain) User *with;

@end
