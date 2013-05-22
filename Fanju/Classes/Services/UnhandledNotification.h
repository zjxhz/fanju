//
//  UnhandledNotification.h
//  Fanju
//
//  Created by Xu Huanze on 5/14/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMPPFramework.h"

@interface UnhandledNotification : NSObject
@property(nonatomic, strong) XMPPMessage* notification;
@property(nonatomic, strong) NSDate* time;
@property(nonatomic) BOOL read;
@end
