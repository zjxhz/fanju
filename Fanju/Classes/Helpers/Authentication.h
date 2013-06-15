//
//  Authentication.h
//  EasyOrder
//
//  Created by 浣泽 徐 on 6/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UserProfile.h"
#import "Const.h"
#import "SinaWeibo.h"
#import "NetworkHandler.h"
#import "LocationProvider.h"
#import "XMPPHandler.h"

@protocol AuthenticationDelegate <NSObject>
@optional
-(void)userDidLogIn:(UserProfile*) user;
-(void)userFailedToLogInWithError:(NSString*)error;
-(void)userDidLogout:(UserProfile*)user;
-(void)sinaweiboDidLogin:(SinaWeibo*)sinaweibo;
- (void)sinaweiboLogInDidCancel:(SinaWeibo *)sinaweibo;
@end

@interface Authentication : NSObject<SinaWeiboDelegate, SinaWeiboRequestDelegate, LocationProviderDelegate>{
    BOOL isLoggedIn;
}
@property(nonatomic, weak) id<AuthenticationDelegate> delegate;
@property(nonatomic, readonly)    UserProfile* currentUser;
+(Authentication*)sharedInstance;

-(void)loginWithUserName:(NSString*)username password:(NSString*)password;
-(void)loginAsSinaWeiboUser:(UIViewController*)rootViewController;
-(void)logout;
-(BOOL)isLoggedIn;
-(void)synchronize;
-(void)userRegisteredWithData:(NSDictionary*)data;
-(void)relogin;
@end

extern NSString * const EODidLoginNotification;
extern NSString * const EODidLogoutNotification;