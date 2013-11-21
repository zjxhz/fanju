
//
//  AppDelegate.m
//  EasyOrder
//
//  Created by igneus on 11/30/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//
#import <Three20/Three20.h>
#import "AppDelegate.h"

#import "MyCustomStylesheet.h"
#import "Const.h"
#import "LocationProvider.h"
#import "RestaurantInfo.h"
#import "MealListViewController.h"
#import "MyMealsViewController.h"
#import "AccountViewController.h"
#import "MFSideMenu.h"
#import "Authentication.h"
#import "OverlayViewController.h"
#import "CrittercismSDK/Crittercism.h"
#import "Const.h"
#import "NewSidebarViewController.h"
#import "RKLog.h"
#import "AlixPay.h"
#import "DictHelper.h"
#import "DDLog.h"
#import "DDTTYLogger.h"
#import "DDFileLogger.h"
#import "DDASLLogger.h"
#import "RestKit.h"
#import "DateUtil.h"
#import "FJLoggerFormatter.h"
#import "UINavigationController+MFSideMenu.h"
#import "WXApi.h"

@interface AppDelegate() {
    UINavigationController* _navigationController;
}
@end

@implementation AppDelegate

@synthesize window = _window;
@synthesize bgImage;
@synthesize managedObjectContext = __managedObjectContext;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;
@synthesize sharedObject = _sharedObject;

- (UIImage*)bgImage {
    if (!bgImage) {
        bgImage = TTIMAGE(@"bundle://bg.png");
    }
    
    return bgImage;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    dispatch_async(dispatch_get_main_queue(), ^{
        extern CFAbsoluteTime StartTime;
        DDLogVerbose(@"App finished launching in %f seconds", CFAbsoluteTimeGetCurrent() - StartTime);
    });
    
    [self configureLogger];
    [[RestKitService service] setup];
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    

    [TTStyleSheet setGlobalStyleSheet:[[MyCustomStylesheet alloc] init]];
    
    [[LocationProvider sharedProvider] obtainCurrentLocation:[Authentication sharedInstance]];
    [[TTURLRequestQueue mainQueue] setMaxContentLength:0];
    MealListViewController *meal = [[MealListViewController alloc] initWithNibName:@"MealListViewController" bundle:nil];
    [self configureSideMenu:meal];
    

    UIRemoteNotificationType allowedNotifications = UIRemoteNotificationTypeAlert |  UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound;
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:allowedNotifications];
    
    if([[[NSBundle mainBundle] objectForInfoDictionaryKey:@"AutoSendCrashReport"] boolValue]){
        [Crittercism enableWithAppID:@"50ac205641ae503e5c000004"];
    }
    
    if (![WXApi registerApp:WEIXIN_APP_KEY]) {//@"wxd930ea5d5a258f4f"];
        DDLogError(@"failed to register app to weixin");
    }
    [self initSinaweibo];
    self.window.rootViewController = _navigationController;
    [_navigationController.view addSubview:[OverlayViewController sharedOverlayViewController].view];
    [self customNavigationBar];
    [self.window makeKeyAndVisible];
    [meal viewDidAppear:NO];
    [[Authentication sharedInstance] relogin];
//    [UMSocialData setAppKey:UM_SOCIAL_APP_KEY];
    return YES;
}

-(void)configureSideMenu:(MealListViewController*)mealListViewController{
    _navigationController = [[UINavigationController alloc] initWithRootViewController:mealListViewController];
    // make sure to display the navigation controller before calling this
    NewSidebarViewController *sideMenuViewController = [NewSidebarViewController sideBar];
    sideMenuViewController.mealListViewController = mealListViewController;
    MFSideMenu* sideMenu = [MFSideMenu menuWithNavigationController:_navigationController leftSideMenuController:sideMenuViewController rightSideMenuController:nil panMode:0];//no pan
    sideMenuViewController.sideMenu = sideMenu;
    MFSideMenuStateEventBlock b = ^(MFSideMenuStateEvent event){
        if (event == MFSideMenuStateEventMenuDidOpen) {
            NSIndexPath* selectedRow = [sideMenuViewController.tableView indexPathForSelectedRow];
            [sideMenuViewController.tableView reloadData];
            [sideMenuViewController.tableView selectRowAtIndexPath:selectedRow animated:NO scrollPosition:NO];
        }
    };
    sideMenu.menuStateEventBlock = b;
}

-(void)configureLogger{
    RKLogConfigureByName("*", RKLogLevelOff); //disable RK logs, for now, it's annoying
    id<DDLogFormatter> formatter = [[FJLoggerFormatter alloc] init];
    [DDLog addLogger:[DDASLLogger sharedInstance]];
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    DDFileLogger* fileLogger = [[DDFileLogger alloc] init];
    fileLogger.rollingFrequency = 60 * 60 * 24 * 7; // a week rolling
    fileLogger.logFileManager.maximumNumberOfLogFiles = 4;// 4 weeks
    [DDLog addLogger: fileLogger];
    [[DDTTYLogger sharedInstance] setLogFormatter:formatter];
    [[DDASLLogger sharedInstance] setLogFormatter:formatter];
    [fileLogger setLogFormatter:formatter];
    [[DDTTYLogger sharedInstance] setColorsEnabled:YES];
    [[DDTTYLogger sharedInstance] setForegroundColor:[UIColor blueColor] backgroundColor:nil forFlag:LOG_FLAG_INFO];
}

-(void)initSinaweibo{
    self.sinaweibo = [[SinaWeibo alloc] initWithAppKey:WEIBO_APP_KEY appSecret:WEIBO_APP_SECRET appRedirectURI:WEIBO_APP_REDIRECT_URI ssoCallbackScheme:APP_SCHEME andDelegate:nil];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *sinaweiboInfo = [defaults objectForKey:@"SinaWeiboAuthData"];
    if ([sinaweiboInfo objectForKey:@"AccessTokenKey"] && [sinaweiboInfo objectForKey:@"ExpirationDateKey"] && [sinaweiboInfo objectForKey:@"UserIDKey"])
    {
        self.sinaweibo.accessToken = [sinaweiboInfo objectForKey:@"AccessTokenKey"];
        self.sinaweibo.expirationDate = [sinaweiboInfo objectForKey:@"ExpirationDateKey"];
        self.sinaweibo.userID = [sinaweiboInfo objectForKey:@"UserIDKey"];
    }
}

-(void)customNavigationBar{
    UIImage* backImg = [[UIImage imageNamed:@"toplf"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 14, 0, 15)];
    UIImage* backImgPush = [[UIImage imageNamed:@"toplf_push"]  resizableImageWithCapInsets:UIEdgeInsetsMake(0, 14, 0, 15)];
    [[UINavigationBar appearance]setBackgroundImage:[UIImage imageNamed:@"topbar_bg"] forBarMetrics:UIBarMetricsDefault];
    if (![VersionUtil isiOS7]) {
        [[UIBarButtonItem appearance] setBackButtonBackgroundImage:backImg forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
        [[UIBarButtonItem appearance] setBackButtonBackgroundImage:backImgPush forState:UIControlStateSelected | UIControlStateHighlighted barMetrics:UIBarMetricsDefault];
        [[UIBarButtonItem appearance] setTitleTextAttributes:@{UITextAttributeTextColor:[UIColor whiteColor],
                                                               UITextAttributeFont:[UIFont systemFontOfSize:12]} forState:UIControlStateNormal];
    } else {
        [[UIBarButtonItem appearance] setTitleTextAttributes:@{UITextAttributeTextColor:[UIColor whiteColor]} forState:UIControlStateNormal];
        [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
        self.window.tintColor = [UIColor whiteColor];
    }
}

-(void)popupViewController{
    [_navigationController popViewControllerAnimated:YES];
}
- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [self.sinaweibo applicationDidBecomeActive];
}


- (void)parseAlixPayUrl:(NSURL *)url application:(UIApplication *)application {
	AlixPay *alixpay = [AlixPay shared];
	AlixPayResult *result = [alixpay handleOpenURL:url];
	if (result) {
		//是否支付成功
		if (9000 == result.statusCode) {
            NSString* url = [NSString stringWithFormat:@"http://%@/pay/alipay/app/back/sync/", EOHOST];
            NSArray* params = @[[DictHelper dictWithKey:@"alipay_result" andValue:result.resultString],
                                [DictHelper dictWithKey:@"sign" andValue:result.signString]];
            [[NetworkHandler getHandler] requestFromURL:url method:POST parameters:params cachePolicy:TTURLRequestCachePolicyNone success:^(id obj) {
                DDLogVerbose(@"result: %@", obj);
                [[NSNotificationCenter defaultCenter] postNotificationName:ALIPAY_PAY_RESULT object:obj userInfo:nil];
            } failure:^{
                DDLogError(@"failed to pay");
                NSDictionary* dic = @{@"status": @"NOK", @"message":@"支付已经成功，但是同步服务器产生了网络错误，请联系客服"};
                [[NSNotificationCenter defaultCenter] postNotificationName:ALIPAY_PAY_RESULT object:dic userInfo:nil];
            }];
        } else {
            DDLogVerbose(@"alixpay failed with status message: %@", result.statusMessage);
            NSDictionary* dic = @{@"status": @"NOK", @"message":result.statusMessage};
            [[NSNotificationCenter defaultCenter] postNotificationName:ALIPAY_PAY_RESULT object:dic userInfo:nil];
        }
    }
}


- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    DDLogInfo(@"hanlding url: %@, source: %@, annotation: %@", url, sourceApplication, annotation);
    if ([[url host] isEqualToString:@"safepay"]) {
        [self parseAlixPayUrl:url application:application];
        return YES;
    } else if([[url scheme] isEqualToString:WEIXIN_APP_KEY]){
        return [WXApi handleOpenURL:url delegate:self];
    }
    return [self.sinaweibo handleOpenURL:url];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

- (void)saveContext
{
    RKManagedObjectStore* store = [RKObjectManager sharedManager].managedObjectStore;
    NSManagedObjectContext* context = store.mainQueueManagedObjectContext;
    
    NSError *error = nil;
    if (![context saveToPersistentStore:&error]) {
        DDLogError(@"failed to save context before terminating: %@", error);
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application{
    DDLogVerbose(@"enter to background"); //TODO is this needed? it seems entering background cannot receive messages
	if ([XMPPHandler sharedInstance].xmppStream) {
        [[XMPPHandler sharedInstance].xmppStream disconnect];
    }
}

-(void)applicationWillEnterForeground:(UIApplication *)application{
    DDLogVerbose(@"entering to foreground");
	if ([XMPPHandler sharedInstance].xmppStream) {
        NSError* error = nil;
        if (![[XMPPHandler sharedInstance].xmppStream connect:&error]) {
            DDLogVerbose(@"Opps, I probably forgot something: %@", error);
        } else {
            DDLogVerbose(@"Probably connected?");
        }
    }
}
#pragma mark - Application's Documents directory

/**
 Returns the URL to the application's Documents directory.
 */
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

-(void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken{
    self.apnsToken = [[[deviceToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]] stringByReplacingOccurrencesOfString:@" " withString:@""];
    DDLogVerbose(@"registered token: %@", self.apnsToken);
    
}

-(void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error{
    DDLogVerbose(@"error in registration. Error: %@", error);
}

#pragma mark WXApiDelegate
-(void) onResp:(BaseResp*)resp
{
    DDLogInfo(@"weixin resp code: %d", resp.errCode);
}

-(void) onReq:(BaseReq*)req
{
    DDLogInfo(@"request from weixin: %@", req);
    
}

@end
