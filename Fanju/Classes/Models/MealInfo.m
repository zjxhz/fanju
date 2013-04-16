//
//  MealInfo.m
//  EasyOrder
//
//  Created by igneus on 3/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MealInfo.h"
#import "NSDictionary+ParseHelper.h"
#import "DateUtil.h"

@implementation MealInfo

@synthesize mID = _mID;
@synthesize type = _type;
@synthesize topic = _topic, intro = _intro, restaurant = _restaurant, time = _time, maxPersons = _maxPersons, actualPersons=_actualPersons, participants = _participants, likes = _likes, host = _host, photoURL = _photoURL, price = _price;

static NSDateFormatter *_dateFormatter;

+(void)initialize{
    if (!_dateFormatter) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateFormat:@"YYYY年M月d日 HH:mm"];
    }
}

- (MealInfo *)initWithData:(NSDictionary *)data {
    if (self = [super init]) {
        _mID = [[data objectForKey:@"id"] intValue];
        _type = [[data objectForKey:@"type"] intValue];
        _topic = [data objectForKey:@"topic"];
        _intro = [data objectForKey:@"introduction"];
        _restaurant = [RestaurantInfo restaurantWithData:[data objectForKey:@"restaurant"]];
//        NSString *t = [data objectForKey:@"time"];
        NSString *t = [NSString stringWithFormat:@"%@T%@", [data objectForKey:@"start_date"], [data objectForKey:@"start_time"]];
        _time = [DateUtil dateFromString:t];
        _maxPersons = [[data objectForKey:@"max_persons"] intValue];
        _actualPersons = [[data objectForKey:@"actual_persons"] intValue];
        _host = [UserProfile profileWithData:[data objectForKey:@"host"]];
        _participants = [[NSMutableArray alloc] init];
        _likes = [[NSMutableArray alloc] init];
        _photoURL = [data objectForKey:@"photo"];
        _price = [[data objectForKey:@"list_price"] doubleValue];
        for (NSDictionary *dict in [data objectForKey:@"participants"]) {
            [_participants addObject: [UserProfile profileWithData:dict]];
        }
        for (NSDictionary *dict in [data objectForKey:@"likes"]) {
            [_likes addObject: [UserProfile profileWithData:dict]];
        }
    }
    
    return self;
}

+ (MealInfo *)mealInfoWithData:(NSDictionary *)data {
    return [[MealInfo alloc] initWithData:data];
}

- (BOOL) hasJoined:(NSString*)userID{
    int uid = [userID intValue];
    if (_host.uID == uid) {
        return YES;
    }
     return [self isPartOf:userID inGroup:_participants];
}

- (BOOL) hasLiked:(NSString*)userID{
    return [self isPartOf:userID inGroup:_likes];
}

- (BOOL) isPartOf:(NSString*)userID inGroup:(NSMutableArray*)group{
    if (!userID) {
        return NO;
    }
    int uid = [userID intValue];
    for(UserProfile *p in group){
        if (p.uID == uid) {
            return YES;
        }
    }
    return NO;
}

- (void) join:(UserProfile*) user{
    [self join:user withTotalNumberOfPersons:1];
}

- (void) join:(UserProfile*)user withTotalNumberOfPersons:(NSInteger)num_persons{
    [_participants addObject:user];
    _actualPersons += num_persons;
}

- (void) like:(UserProfile*) user{
    [self.likes addObject:user];
}

- (void) dontLike:(UserProfile*) user{
    [self.likes removeObject:user];
}

- (NSString*) photoFullUrl{
    if ([self.photoURL hasPrefix:@"http:"] ) {
        return self.photoURL;
    }
    return [NSString stringWithFormat:@"http://%@%@", EOHOST, self.photoURL];
}

- (id)copyWithZone:(NSZone *)zone {
    MealInfo *info = [[MealInfo allocWithZone:zone] init];
    info.mID = _mID;
    info.type = _type;
    info.topic = _topic;
    info.intro = _intro;
    info.restaurant = _restaurant;
    info.time = _time;
    info.maxPersons = _maxPersons;
    info.actualPersons = _actualPersons;
    info.participants = _participants;
    info.host = _host;
    info.photoURL = _photoURL;
    info.price = _price;
    info.likes = _likes;
    info.photo = _photo;
    info.fullPhoto = _fullPhoto;
    return info;
}


- (NSComparisonResult)compare:(MealInfo *)other{
    return [self.time compare:other.time];
}

-(NSString*)timeText{
    return [NSString stringWithFormat: @"%@ %@", [DateUtil weekday:_time], [_dateFormatter stringFromDate:_time]];
}

-(NSString*)description{
    return [NSString stringWithFormat:@"%@ with %d participants", _topic, _participants.count];
}
@end
