//
//  UserMessage.h
//  Fanju
//
//  Created by Xu Huanze on 5/30/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Conversation;

@interface UserMessage : NSManagedObject

@property (nonatomic, retain) NSNumber * incoming;
@property (nonatomic, retain) NSString * message;
@property (nonatomic, retain) NSString * mID;
@property (nonatomic, retain) NSNumber * read;
@property (nonatomic, retain) NSDate * time;
@property (nonatomic, retain) Conversation *conversation;

@end
