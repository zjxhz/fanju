//
//  SimpleUserEvent.h
//  Fanju
//
//  Created by Xu Huanze on 3/12/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import "EventBase.h"
#import "UserProfile.h"
//Simple user event with a user, an event and a time, clicking the user avatar or
// the cell will both direct the user to the user details view
@interface SimpleUserEvent : EventBase
@property(nonatomic, strong) UserProfile* user;
@property(nonatomic, strong) NSString* userID;
@property(nonatomic, strong) NSString* userFieldName; //user id field in the payload
@property(nonatomic, strong) NSString* eventDescription;
@end
