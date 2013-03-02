//
//  MealInvitation.m
//  EasyOrder
//
//  Created by 浣泽 徐 on 4/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MealInvitation.h"
#import "NSDictionary+ParseHelper.h"

@implementation MealInvitation
@synthesize mID=_mID, from=_from, to=_to, meal=_meal, timestamp=_timestamp;

-(MealInvitation *) initWithData:(NSDictionary *)data {
    if(self = [self init]){
        _mID = [[data objectForKey:@"id"] intValue];
        _meal = [MealInfo mealInfoWithData:[data objectForKey:@"meal"]];
        _from = [UserProfile profileWithData:[data objectForKey:@"from_person"]];
        _to = [UserProfile profileWithData:[data objectForKey:@"to_person"]];
        NSString *t = [data objectForKey:@"timestamp"];
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
        _timestamp = [df dateFromString:t];
    }
    return self;
}

+ (MealInvitation *)mealInvitationWithData:(NSDictionary *)data {
    return [[MealInvitation alloc] initWithData:data];
}

- (id)copyWithZone:(NSZone *)zone {
    MealInvitation *invitation = [[MealInvitation allocWithZone:zone] init];
    invitation.mID = _mID;
    invitation.from = _from;
    invitation.to = _to;
    invitation.meal = _meal;
    invitation.timestamp = _timestamp;
    return invitation;
}

@end
