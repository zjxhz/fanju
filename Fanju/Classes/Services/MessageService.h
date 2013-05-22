//
//  MessageService.h
//  Fanju
//
//  Created by Xu Huanze on 5/2/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UserMessage.h"
#import "User.h"

@interface MessageService : NSObject
@property(nonatomic, strong) NSMutableArray* conversations;
@property(nonatomic, readonly) NSInteger unreadMessageCount;
+(MessageService*)service;
-(void)setup;
-(void)tearDown;
-(Conversation*)getOrCreateConversation:(User*)owner with:(User*)with;
-(void)updateConversation:(Conversation*)conversation withMessage:(UserMessage*)message unreadCount:(NSInteger)unreadCount;
-(void)deleteConversation:(Conversation*)conversation;
-(void)markMessagesReadFrom:(User*)user;
-(void)updateUnreadCount;

@end

extern NSString* const MessageDidSaveNotification;
extern NSString* const CurrentConversation;