//
//  MessageService.h
//  Fanju
//
//  Created by Xu Huanze on 5/2/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UserMessage.h"

@interface MessageService : NSObject
+(MessageService*)service;
-(void)setup;
-(void)updateConversation:(UserMessage*)message unreadCount:(NSInteger)unreadCount;

@property(nonatomic, strong) NSMutableArray* conversations;
@end

extern NSString* const MessageDidSaveNotification;