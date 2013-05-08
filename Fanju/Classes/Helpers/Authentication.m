//
//  Authentication.m
//  EasyOrder
//
//  Created by 浣泽 徐 on 6/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Authentication.h"
#import "NetworkHandler.h"
#import "Const.h"
#import "DictHelper.h"
#import "DateUtil.h"
#import "AppDelegate.h"
#import "DictHelper.h"
#import "NewSidebarViewController.h"
#import "UserService.h"

NSString * const EODidLoginNotification = @"EODidLoginNotification";
NSString * const EODidLogoutNotification = @"EODidLogoutNotification";

@implementation Authentication
@synthesize delegate;
@synthesize currentUser = _currentUser;

+(Authentication*)sharedInstance{
    static Authentication* instance;
    if (!instance) {
        instance = [[Authentication alloc] init];
    }
    return instance;    
}

//never call this method if you need an instance, call sharedInstance instead
-(id) init{
    if (self = [super init]) {
        NSData *archivedData = [[NSUserDefaults standardUserDefaults] objectForKey:LOGGED_USER_PROFILE];
        if (archivedData) {
            _currentUser = [NSKeyedUnarchiver unarchiveObjectWithData:archivedData];
        }
    }
    return self;
}

- (SinaWeibo *)sinaweibo{
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    appDelegate.sinaweibo.delegate = self;
    return appDelegate.sinaweibo;
}

-(BOOL)isLoggedIn{
    return _currentUser != nil;
}

-(void) synchronize{
    if (_currentUser) {
        NSData *archivedData = [NSKeyedArchiver archivedDataWithRootObject:_currentUser];
        [[NSUserDefaults standardUserDefaults] setObject:archivedData forKey:LOGGED_USER_PROFILE];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [[NSNotificationCenter defaultCenter] postNotificationName:EODidLoginNotification
                                                            object:nil
                                                          userInfo:nil];
    } else {
        [[NSUserDefaults standardUserDefaults] setValue:nil forKey:LOGGED_USER_PROFILE];
        [[NSNotificationCenter defaultCenter] postNotificationName:EODidLogoutNotification
                                                            object:nil
                                                          userInfo:nil];
    }
}

-(void)loginWithUserName:(NSString*)username password:(NSString*)password{
    NSArray *params = [NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:username, @"value", @"username", @"key", nil], [NSDictionary dictionaryWithObjectsAndKeys:password, @"value", @"password", @"key", nil], nil];
    [[NetworkHandler getHandler] requestFromURL:[NSString stringWithFormat:@"%@://%@/api/v1/login/", HTTPS, EOHOST]
                                         method:POST
                                     parameters:params
                                    cachePolicy:TTURLRequestCachePolicyNone
                                        success:^(id obj) {
                                            if (obj && [obj isKindOfClass:[NSDictionary class]]) {
                                                if ([[obj objectForKey:@"status"] isEqualToString:@"OK"]) {
                                                    NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithDictionary:obj];
                                                    [dict setValue:password forKey:@"password"];
                                                    [self userDidLoginWithData:dict];
                                                    DDLogVerbose(@"user logged in");
                                                } else {
                                                    [self.delegate userFailedToLogInWithError:[obj objectForKey:@"info"]];
                                                    [self logout];
                                                }
                                            } else {
                                                [self.delegate userFailedToLogInWithError:@"登录失败"];
                                                [self logout];
                                            }
                                        } failure:^{
                                            [self.delegate userFailedToLogInWithError:@"登录失败"];
                                            [self logout];
                                        }];

}

//re-login may be needed as the cookie can be invalid(e.g. password was changed somewhere else), and if it's invalid then the cookies 
//should be deleted by logging out
-(void)relogin{
    if (_currentUser && _currentUser.username && _currentUser.password) {
        DDLogVerbose(@"logging in with username and password");
        [[Authentication sharedInstance] loginWithUserName:_currentUser.username password:_currentUser.password];
    } else if([[self sinaweibo] isLoggedIn]) {
        DDLogVerbose(@"weibo logged in, continue to log in as an app user");
        [self logInToApp];
    } else{
        //not logged in either as an app user or weibo user, logout to clear data
        [self logout];
    }
}

-(void)userRegisteredWithData:(NSDictionary*)data{
    [self userDidLoginWithData:data];
}

-(void) userDidLoginWithData:(NSDictionary*)data{
    NSString* username = data[@"username"];
    [[UserService shared] getOrFetchUserWithUsername:username success:^(User *user) {
        DDLogVerbose(@"fetched logged in user and stored to core data");
    } failure:^{
        NSAssert(NO, @"failed to fetch logged in user info with username: %@", username);
    }];
    _currentUser = [UserProfile profileWithData:data];
    [self registerToken];
    [[XMPPHandler sharedInstance] setup];
    [self synchronize];
    [self.delegate userDidLogIn:_currentUser];
    if(![_currentUser hasCompletedRegistration]){
//        [[NewSidebarViewController sideBar] showRegistrationWizard]; disable for now
    }
}

-(void)registerToken{
    AppDelegate *appDelegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    DDLogVerbose(@"updating token to server...");
    if (appDelegate.apnsToken) {
        NSDictionary *dict = @{@"apns_token":appDelegate.apnsToken};
        [[NetworkHandler getHandler] sendJSonRequest:[NSString stringWithFormat:@"%@://%@/api/v1/user/%d/", HTTPS, EOHOST, _currentUser.uID]
                                              method:PATCH
                                          jsonObject:dict
                                             success:^(id obj) {
                                                 DDLogVerbose(@"update token %@ for uid: %d", appDelegate.apnsToken, _currentUser.uID);
                                                 appDelegate.apnsToken = nil;
                                             } failure:^{
                                                  DDLogError(@"failed to update token %@ for uid: %d", appDelegate.apnsToken, _currentUser.uID);
                                             }];

    }
}

-(void) logout{
    _currentUser = nil;
    [self synchronize];
    [[XMPPHandler sharedInstance] tearDown];
    //logout from server
    [[NetworkHandler getHandler] requestFromURL:[NSString stringWithFormat:@"http://%@/api/v1/logout/", EOHOST]
                                         method:POST
                                        success:^(id obj) {
                                            DDLogVerbose(@"logged out");
                                        } failure:^{
                                            DDLogError(@"failed to logout from server");
                                        }];
    //remove cookie
    for (NSHTTPCookie *cookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies]) {
        DDLogVerbose(@"%@", cookie.domain);
        if ([cookie.domain isEqualToString:EOHOST]) {
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
        }
    } 
    
    if ([self sinaweibo]  && [[self sinaweibo]  isLoggedIn]) {
        [[self sinaweibo]  logOut];
    }
    
    DDLogVerbose(@"user logged out");
    [self.delegate userDidLogout:_currentUser];
    
}


-(void)loginAsSinaWeiboUser:(UIViewController*)rootViewController{
    if (![[self sinaweibo]  isLoggedIn] || [[self sinaweibo] isAuthorizeExpired]) {
        [[self sinaweibo]  logIn];
    } else {
        [self sinaweiboDidLogIn:[self sinaweibo] ];
    }
}

- (void)storeAuthData
{
    SinaWeibo *sinaweibo = [self sinaweibo];
    
    NSDictionary *authData = [NSDictionary dictionaryWithObjectsAndKeys:
                              sinaweibo.accessToken, @"AccessTokenKey",
                              sinaweibo.expirationDate, @"ExpirationDateKey",
                              sinaweibo.userID, @"UserIDKey",
                              sinaweibo.refreshToken, @"refresh_token", nil];
    [[NSUserDefaults standardUserDefaults] setObject:authData forKey:@"SinaWeiboAuthData"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark _
#pragma mark - SinaWeibo Delegate
- (void)sinaweiboDidLogIn:(SinaWeibo *)sinaweibo{
    DDLogInfo(@"logged in ok using weibo account, continue to log in as an ordinary user...");
    if ([self.delegate respondsToSelector:@selector(sinaweiboDidLogin:)]) {
        [self.delegate sinaweiboDidLogin:sinaweibo];
    }
    [self storeAuthData];
    [self logInToApp];
}

-(void)sinaweibo:(SinaWeibo *)sinaweibo logInDidFailWithError:(NSError *)error{
    [self.delegate userFailedToLogInWithError:[NSString stringWithFormat:@"登陆微博失败：%@", error.description]];
    DDLogWarn(@"failed to login to sina weibo: %@", error.description);
}

-(void)sinaweiboDidLogOut:(SinaWeibo *)sinaweibo{
    DDLogVerbose(@"sinaweiboDidLogout");
    [self removeAuthData];
}

-(void)sinaweibo:(SinaWeibo *)sinaweibo accessTokenInvalidOrExpired:(NSError *)error{
    [self removeAuthData];
}

-(void)removeAuthData{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"SinaWeiboAuthData"];
}

-(void) logInToApp{    
    NSTimeInterval expires_in = [[self sinaweibo].expirationDate timeIntervalSince1970];
    NSArray* params = @[
            [DictHelper dictWithKey:@"access_token" andValue:[self sinaweibo].accessToken],
            [DictHelper dictWithKey:@"expires_in" andValue:[NSString stringWithFormat:@"%.0f", expires_in]]
    ];
    [[NetworkHandler getHandler] requestFromURL:[NSString stringWithFormat:@"%@://%@/api/v1/weibo_user_login/", HTTPS, EOHOST]
                                         method:POST
                                     parameters:params
                                    cachePolicy:TTURLRequestCachePolicyNone
                                        success:^(id obj) {
                                            if (obj && [obj isKindOfClass:[NSDictionary class]]) {
                                                if ([[obj objectForKey:@"status"] isEqualToString:@"OK"]) {
                                                    [self userDidLoginWithData:obj];
                                                } else {
                                                    [self.delegate userFailedToLogInWithError:[obj objectForKey:@"info"]];
                                                    [self logout];
                                                }
                                            } else {
                                                [self.delegate userFailedToLogInWithError:@"微博登录失败"];
                                                [self logout];
                                            }
                                        } failure:^{
                                            [self.delegate userFailedToLogInWithError:@"微博登录失败"];
                                            [self logout];
                                        }];
}

#warning check if this method can be replaced by relogin
-(void)refreshUserInfo:(retrieved_t)success failure:(retrieve_failed_t)failure{
    if (_currentUser) {
        [[NetworkHandler getHandler] requestFromURL:[NSString stringWithFormat:@"%@://%@/api/v1/user/%d/?format=json", HTTPS, EOHOST, _currentUser.uID]
                                             method:GET
                                        cachePolicy:TTURLRequestCachePolicyNone
                                            success:^(id obj) {
                                                _currentUser = [UserProfile profileWithData:obj];
                                                [self synchronize];
                                                success(_currentUser);
                                            } failure:^{
                                                failure();
                                            }];
    }
}

#pragma mark LocationProviderDelegate
-(void)finishObtainingLocation:(CLLocation*)location {
    DDLogVerbose(@"obtained location: %@", location);
    if (_currentUser) {
        _currentUser.coordinate = location.coordinate;
        _currentUser.locationUpdatedTime = [[NSDate alloc] init];    
        [self synchronize];
        NSArray *params = @[[DictHelper dictWithKey:@"lat" andValue:[NSString stringWithFormat:@"%f", _currentUser.coordinate.latitude]],
        [DictHelper dictWithKey:@"lng" andValue:[NSString stringWithFormat:@"%f", _currentUser.coordinate.longitude]]];

        NSString *requestStr = [NSString stringWithFormat:@"%@://%@/api/v1/user/%d/location/", HTTPS, EOHOST, _currentUser.uID];
        [[NetworkHandler getHandler] requestFromURL:requestStr
                                             method:POST
                                         parameters:params
                                        cachePolicy:TTURLRequestCachePolicyNoCache
                                            success:^(id obj) {
                                                DDLogVerbose(@"location stored to server");
                                            }
                                            failure:^{
                                                DDLogVerbose(@"Warning: failed to store user location to the server.");
                                            }];
    }
}

-(void)failedObtainingLocation {
    DDLogVerbose(@"location obtain failed");
}
@end
