//
//  FollowerEvent.h
//  Fanju
//
//  Created by Xu Huanze on 3/5/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EOMessage.h"
#import "EventBase.h"
#import "UserProfile.h"

@interface FollowerEvent : EventBase
@property(nonatomic, strong) NSString* followerID;//in CoreData only ID is saved, which will be used to retrive user info from either cache or network
@property(nonatomic, strong) UserProfile* follower;
@end
