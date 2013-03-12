//
//  EventFactory.m
//  Fanju
//
//  Created by Xu Huanze on 3/12/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import "EventFactory.h"
#import "FollowerEvent.h"
#import "JoinMealEvent.h"
#import "VisitorEvent.h"

@implementation EventFactory
+(EventFactory*)sharedFactory {
    static EventFactory *factory = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        factory = [[EventFactory alloc] init];
    });
    return factory;
}

-(id)createEvent:(EOMessage*)message{
    if (message.node) {
        if ([message.node hasSuffix:@"/followers"]) {
            return [[FollowerEvent alloc] init];
        } else if([message.node hasSuffix:@"/participants"] || [message.node hasSuffix:@"/meals"]){
            return [[JoinMealEvent alloc] init];
        } else if([message.node hasSuffix:@"/visitors"]){
            return [[VisitorEvent alloc] init];;
        }
    }
    return nil;
}

@end
