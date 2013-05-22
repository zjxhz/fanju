//
//  ArchivedMessageService.h
//  Fanju
//
//  Created by Xu Huanze on 5/7/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ArchivedMessageService : NSObject
+(ArchivedMessageService*)service;
-(void)retrieveConversations;
-(void)setup;
-(void)tearDown;

@property(nonatomic, readonly) BOOL retrievingConversations; //TODO received messages while retrieving

@end
