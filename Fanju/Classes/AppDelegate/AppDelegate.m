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
#import "MapViewController.h"
#import "MyOrdersViewController.h"
#import "OrderDetailViewController.h"
#import "Const.h"
#import "LocationProvider.h"
#import "RestaurantInfo.h"
#import "MealListViewController.h"
#import "MyMealsViewController.h"
#import "SocialNetworkViewController.h"
#import "AccountViewController.h"
#import "MFSideMenu.h"
#import "Authentication.h"
#import "OverlayViewController.h"
#import "CrittercismSDK/Crittercism.h"
#import "Const.h"
#import "NewSidebarViewController.h"

@interface AppDelegate() 
@end

@implementation AppDelegate

@synthesize window = _window;
@synthesize viewController = _viewController;
@synthesize bgImage;
@synthesize managedObjectContext = __managedObjectContext;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;
@synthesize sharedObject = _sharedObject;

- (UIImage*)bgImage {
    if (!bgImage) {
        bgImage = TTIMAGE(@"bundle://background.png");
    }
    
    return bgImage;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    dispatch_async(dispatch_get_main_queue(), ^{
        extern CFAbsoluteTime StartTime;
        NSLog(@"App finished launching in %f seconds", CFAbsoluteTimeGetCurrent() - StartTime);
    });
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    [TTStyleSheet setGlobalStyleSheet:[[MyCustomStylesheet alloc] init]]; 
    MealListViewController *meal = [[MealListViewController alloc] initWithNibName:@"MealListViewController" bundle:nil];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:meal];
    NewSidebarViewController *sideMenuViewController = [NewSidebarViewController sideBar];
    sideMenuViewController.mealListViewController = meal;
    
    [[LocationProvider sharedProvider] obtainCurrentLocation:[Authentication sharedInstance]];
#warning check if below line is really needed
    [[TTURLRequestQueue mainQueue] setMaxContentLength:0];
    
    // make sure to display the navigation controller before calling this
    MFSideMenu* sideMenu = [MFSideMenu menuWithNavigationController:navigationController leftSideMenuController:sideMenuViewController rightSideMenuController:nil];
    sideMenuViewController.sideMenu = sideMenu;
    
    UIRemoteNotificationType allowedNotifications = UIRemoteNotificationTypeAlert |  UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound;
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:allowedNotifications];
    
    [Crittercism enableWithAppID:@"50ac205641ae503e5c000004"];
    
    [self initSinaweibo];
    [[Authentication sharedInstance] relogin];
    
    [self.window addSubview:[OverlayViewController sharedOverlayViewController].view];
    self.window.rootViewController = navigationController;
    [self.window makeKeyAndVisible];
    [meal viewDidAppear:NO]; 
    return YES;
}

-(void)initSinaweibo{
    self.sinaweibo = [[SinaWeibo alloc] initWithAppKey:WEIBO_APP_KEY appSecret:WEIBO_APP_SECRET appRedirectURI:WEIBO_APP_REDIRECT_URI andDelegate:nil];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *sinaweiboInfo = [defaults objectForKey:@"SinaWeiboAuthData"];
    if ([sinaweiboInfo objectForKey:@"AccessTokenKey"] && [sinaweiboInfo objectForKey:@"ExpirationDateKey"] && [sinaweiboInfo objectForKey:@"UserIDKey"])
    {
        self.sinaweibo.accessToken = [sinaweiboInfo objectForKey:@"AccessTokenKey"];
        self.sinaweibo.expirationDate = [sinaweiboInfo objectForKey:@"ExpirationDateKey"];
        self.sinaweibo.userID = [sinaweiboInfo objectForKey:@"UserIDKey"];
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [self.sinaweibo applicationDidBecomeActive];
}

- (BOOL)application:(UIApplication*)application handleOpenURL:(NSURL*)url {
//    [[TTNavigator navigator] openURLAction:[TTURLAction actionWithURLPath:url.absoluteString]];
    return [self.sinaweibo handleOpenURL:url];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    return [self.sinaweibo handleOpenURL:url];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil)
    {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error])
        {
            /*
             Replace this implementation with code to handle the error appropriately.
             
             abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
             */
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
    }
}

- (void)showLogin {
//    if (![[Authentication sharedInstance] isLoggedIn]) {        
        TTOpenURL(@"eo://login");
//    }
    
}

#pragma mark - Core Data stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)managedObjectContext
{
    if (__managedObjectContext != nil)
    {
        return __managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil)
    {
        __managedObjectContext = [[NSManagedObjectContext alloc] init];
        [__managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return __managedObjectContext;
}

/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created from the application's model.
 */
- (NSManagedObjectModel *)managedObjectModel
{
    if (__managedObjectModel != nil)
    {
        return __managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"DishModel" withExtension:@"momd"];
    __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return __managedObjectModel;
}

/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (__persistentStoreCoordinator != nil)
    {
        return __persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"DM.sqlite"];
    
    NSError *error = nil;
    __persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![__persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error])
    {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter: 
         [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }    
    
    return __persistentStoreCoordinator;
}


- (void)applicationDidEnterBackground:(UIApplication *)application{
    NSLog(@"enter to background"); //TODO is this needed? it seems entering background cannot receive messages
	if ([XMPPHandler sharedInstance].xmppStream) {
        [[XMPPHandler sharedInstance].xmppStream disconnect];
    }
}

-(void)applicationWillEnterForeground:(UIApplication *)application{
    NSLog(@"entering to foreground");
	if ([XMPPHandler sharedInstance].xmppStream) {
        NSError* error = nil;
        if (![[XMPPHandler sharedInstance].xmppStream connect:&error]) {
            NSLog(@"Opps, I probably forgot something: %@", error);
        } else {
            NSLog(@"Probably connected?");
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
    NSLog(@"registered token: %@", self.apnsToken);
    
}

-(void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error{
    NSLog(@"error in registration. Error: %@", error);
}
@end
