//
//  UserService.h
//  Fanju
//
//  Created by Xu Huanze on 5/2/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UserProfile.h"
#import "User.h"
//typedef void(^retrieved_t)(id);

//find a user with username from core data and fetch it from web if it does not exist
@interface UserService : NSObject
@property(nonatomic, strong) User* loggedInUser;

+(UserService*)shared;
-(User*)getOrFetchUserWithUsername:(NSString*)username success:(void (^)(User* user))success failure:(void (^)(void))failure;
-(User*)getOrFetchUserWithJID:(NSString*)jid success:(void (^)(User* user))success failure:(void (^)(void))failure;
//fetch a user from core data, the user must already exist
-(User*)userWithJID:(NSString*)jid;
+(NSString*)jidForUser:(User*)user;
@end
