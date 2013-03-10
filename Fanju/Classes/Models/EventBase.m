//
//  EventBase.m
//  Fanju
//
//  Created by Xu Huanze on 3/5/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import "EventBase.h"
#import "EOMessage.h"
#import "FollowerEvent.h"
#import "JoinMealEvent.h"

@implementation EventBase
+(Class)eventType:(EOMessage*)message{
    if (message.node) {
        if ([message.node hasSuffix:@"/followers"]) {
            return [FollowerEvent class];
        } else if([message.node hasSuffix:@"/participants"] || [message.node hasSuffix:@"/meals"]){
            return [JoinMealEvent class];
        }
    }
    return nil;
}
@end
