//
//  NotificationService.h
//  Fanju
//
//  Created by Xu Huanze on 5/9/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMPPFramework.h"

@interface NotificationService : NSObject
@property(nonatomic, readonly) NSInteger unreadNotifCount;
@property(nonatomic, strong)     NSDate* latestNotificationDate;
+(NotificationService*)service;
-(void)setup;
-(void)tearDown;
-(void)handleArchivedNotificatoin:(NSXMLElement*)event atTime:(NSDate*)time read:(BOOL)read;
-(void)markAllNotificationsRead;
@end

extern NSString* const NotificationDidSaveNotification;
extern NSString* const UnreadNotificationCount;