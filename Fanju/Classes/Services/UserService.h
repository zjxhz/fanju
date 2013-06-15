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
#import "GuestUser.h"
typedef void(^fetch_user_success)(User*);
typedef void (^service_failure)(void);

//find a user with username from core data and fetch it from web if it does not exist
@interface UserService : NSObject
@property(nonatomic, strong) User* loggedInUser;

+(UserService*)service;
-(void)setup;
-(void)tearDown;
-(User*)getOrFetchUserWithUsername:(NSString*)username success:(fetch_user_success)success failure:(void (^)(void))failure;
-(User*)getOrFetchUserWithJID:(NSString*)jid success:(fetch_user_success)success failure:(void (^)(void))failure;
-(User*)getOrFetchUserWithID:(NSString*)uID success:(fetch_user_success)success failure:(void (^)(void))failure;
-(void)fetchUser:(NSString*)username success:(fetch_user_success)success failure:(void (^)(void))failure;
-(void)fetchUserWithJID:(NSString*)jid success:(fetch_user_success)success failure:(void (^)(void))failure;
-(void)fetchUserWithID:(NSString*)uID success:(fetch_user_success)success failure:(void (^)(void))failure;
-(BOOL)isLoggedIn;
//fetch a user from core data, the user must already exist
-(User*)userWithJID:(NSString*)jid;
-(User*)userWithID:(NSString*)userID;
+(NSString*)avatarURLForUser:(User*)user;
+(NSString*)jidForUser:(User*)user;
+(NSArray*)photosUrlsForUser:(User*)user;
+(UIImage*)genderImageForUser:(User*)user;
+(NSString*)genderTextForUser:(User*)user;
+(NSArray*)sortedPhotosForUser:(User*)user;
+(BOOL)hasAvatar:(User*)user;
+(GuestUser*)createGuestOf:(User*)user;
+(UIImage*)defaultAvatarForUser:(User*)user;
@end
