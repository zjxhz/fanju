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
#import "PhotoUploadedEvent.h"
#import "JSONKit.h"

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
    NSDictionary* data = [message.payload objectFromJSONString];
    id event = nil;
    if (message.node) {
        if ([message.node hasSuffix:@"/followers"]) {
            event = [[FollowerEvent alloc] init];
        } else if([message.node hasSuffix:@"/participants"] || [message.node hasSuffix:@"/meals"]){
            event = [[JoinMealEvent alloc] init];
        } else if([message.node hasSuffix:@"/visitors"]){
            event = [[VisitorEvent alloc] init];;
        } else if([message.node hasSuffix:@"/photos"]){
            event = [[PhotoUploadedEvent alloc] init];
        }
    }
    
    if (event) {
        EventBase* eb = event;
        eb.time = message.time;
    }
    
    if ([event isKindOfClass:[SimpleUserEvent class]]) {
        SimpleUserEvent* sue = event;
        sue.userID = [data valueForKey:sue.userFieldName];
        NSString* avatarURL = [data valueForKey:@"avatar"];
        sue.avatar = [avatarURL hasPrefix:@"http"] ? avatarURL : [NSString stringWithFormat:@"http://%@%@", EOHOST, avatarURL];
        sue.userName = [data valueForKey:@"name"];
        sue.eventDescription =  [data valueForKey:@"event"];
    }
    
    if([event isKindOfClass:[JoinMealEvent class]]){
        JoinMealEvent* je = event;
        NSString* participantID = [data valueForKey:@"participant"];
        je.participantID = participantID;
        je.mealID =  [[data valueForKey:@"meal"] integerValue];
        je.mealTopic = [data valueForKey:@"topic"];
        je.eventDescription =  [data valueForKey:@"event"];
        NSString* mealPhoto = [data valueForKey:@"meal_photo"];
        je.mealPhoto = [mealPhoto hasPrefix:@"http"] ? mealPhoto : [NSString stringWithFormat:@"http://%@%@", EOHOST,mealPhoto];
    } else if([event isKindOfClass:[PhotoUploadedEvent class]]){
        PhotoUploadedEvent* pe = event;
        pe.photo = [NSString stringWithFormat:@"http://%@%@", EOHOST,[data valueForKey:@"photo"]];
    }  

        
        
    return event;
}

@end
