//
//  PhotoNotification.h
//  Fanju
//
//  Created by Xu Huanze on 7/23/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Notification.h"

@class Photo;

@interface PhotoNotification : Notification

@property (nonatomic, retain) Photo *photo;

@end
