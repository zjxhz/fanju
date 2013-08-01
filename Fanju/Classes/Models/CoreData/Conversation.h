//
//  Conversation.h
//  Fanju
//
//  Created by Xu Huanze on 7/23/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class User, UserMessage;

@interface Conversation : NSManagedObject

@property (nonatomic, retain) NSNumber * incoming;
@property (nonatomic, retain) NSString * message;
@property (nonatomic, retain) NSDate * time;
@property (nonatomic, retain) NSNumber * unread;
@property (nonatomic, retain) NSSet *messages;
@property (nonatomic, retain) User *owner;
@property (nonatomic, retain) User *with;
@end

@interface Conversation (CoreDataGeneratedAccessors)

- (void)addMessagesObject:(UserMessage *)value;
- (void)removeMessagesObject:(UserMessage *)value;
- (void)addMessages:(NSSet *)values;
- (void)removeMessages:(NSSet *)values;

@end
