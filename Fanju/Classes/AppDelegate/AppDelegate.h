//
//  AppDelegate.h
//  EasyOrder
//
//  Created by igneus on 11/30/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SinaWeibo.h"
#import "WXApi.h"
@class ViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate, WXApiDelegate>

@property (strong, nonatomic) IBOutlet UIWindow *window;
@property (strong, nonatomic) UIImage *bgImage;

//for TTURL only passing NSStings
@property (strong, nonatomic) NSObject *sharedObject;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (strong, nonatomic) NSString* apnsToken;
@property (strong, nonatomic) SinaWeibo* sinaweibo;
- (NSURL *)applicationDocumentsDirectory;

@end
