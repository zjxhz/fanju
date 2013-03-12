//
//  FollowerEvent.m
//  Fanju
//
//  Created by Xu Huanze on 3/5/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import "FollowerEvent.h"

@implementation FollowerEvent
-(id)init{
    if (self = [super init]) {
        self.eventDescription = @"关注了你";
        self.userFieldName = @"follower";
    }
    return self;
}

@end
