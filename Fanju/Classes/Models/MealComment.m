//
//  MealComment.m
//  EasyOrder
//
//  Created by 浣泽 徐 on 6/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MealComment.h"

@implementation MealComment
@synthesize mID = _mID, from_person= _from_person, comment = _comment, time = _time;

- (MealComment*) initWithData:(NSDictionary*)data{
    if (self = [super init]) {
        _mID = [[data objectForKey:@"id"] intValue];
        _from_person = [UserProfile profileWithData:[data objectForKey:@"from_person"]];
        _comment = [data objectForKey:@"comment"];
        NSString *t = [data objectForKey:@"timestamp"];
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
        _time = [df dateFromString:t];

    }
    
    return self;
}

@end
