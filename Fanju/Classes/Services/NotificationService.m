//
//  NotificationService.m
//  Fanju
//
//  Created by Xu Huanze on 5/9/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import "NotificationService.h"
#import "User.h"
#import "XMPPHandler.h"
#import "EventFactory.h"
#import "Notification.h"
#import "MealNotification.h"
#import "PhotoNotification.h"
#import "JSONKit.h"
#import "RestKit.h"
#import "UserService.h"
#import "MealService.h"
#import "PhotoService.h"
#import "UnhandledNotification.h"
#import "MTStatusBarOverlay.h"

NSString * const NotificationDidSaveNotification = @"NotificationDidSaveNotification";
NSString * const UnreadNotificationCount = @"UnreadNotificationCount";
@implementation NotificationService{
    XMPPStream* _xmppStream;
    NSMutableArray* _unhandledNotifications; // messages not have no user found in core data yet, hanlde it later
    NSManagedObjectContext* _mainQueueContext;
    BOOL _handlingPendingNotifications;
}

+(NotificationService*)service{
    static dispatch_once_t onceToken;
    static NotificationService* instance = nil;
    dispatch_once(&onceToken,^{
        instance = [[NotificationService alloc] init];
    });
    return instance;
}

-(id)init{
    if (self = [super init]) {
        _xmppStream = [XMPPHandler sharedInstance].xmppStream;
        _unhandledNotifications= [NSMutableArray array];
        RKManagedObjectStore* store = [RKObjectManager sharedManager].managedObjectStore;
        _mainQueueContext = store.mainQueueManagedObjectContext;
    }
    return self;
}

-(void)setup{
    DDLogVerbose(@"setting up %@", [self class]);
    _xmppStream = [XMPPHandler sharedInstance].xmppStream;
    [_xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
    NSString* userSpecificKey = [self unreadNotificationKey];
    _unreadNotifCount = [[NSUserDefaults standardUserDefaults] integerForKey:userSpecificKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:UnreadNotificationCount
                                                        object:[NSNumber numberWithInteger:_unreadNotifCount]
                                                      userInfo:nil];//initial notif
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(handlePendingNotifications) userInfo:nil repeats:YES];
}

-(NSString*)unreadNotificationKey{
    return [NSString stringWithFormat:@"%@_%@", [UserService service].loggedInUser, UNREAD_NOTIFICATION_COUNT];
}

-(void)tearDown{
    DDLogVerbose(@"tearing down %@", [self class]);
    [_xmppStream removeDelegate:self];
}

#pragma mark XMPP Delegate

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message{
    if ([message wasDelayed]) {
        DDLogVerbose(@"ignoring offline messages as we are handling archived messages only: %@", message);
        return;
    }
    [self handleNotification:message at:[NSDate date] read:NO];
}

-(void)handleNotification:(XMPPMessage*)message at:(NSDate*)time read:(BOOL)read{
    NSXMLElement *event = [message elementForName:@"event"];
    if (event) {
        NSString* userID = [self userIDFrom:message];
        DDLogVerbose(@"Received notification");
        BOOL handled = NO;
        if ([self isSimpleUserNotificaiton:message]) {
              if ([[UserService service] userWithID:userID]) {
                [self doHandleNotification:message at:time read:read];
                handled = YES;
            } 
        } else if([self isMealNotification:message]){
            NSString* mealID =  [self mealIDFrom:message];
            if ([[UserService service] userWithID:userID] && [[MealService service] mealWithID:mealID]) {
                [self doHandleNotification:message at:time read:read];
                handled = YES;
            }
        }  else if([self isPhotoNotification:message]){
            NSString* photoID =  [self photoIDFrom:message];
            if ([[UserService service] userWithID:userID] && [[PhotoService service] photoWithID:photoID]){
                [self doHandleNotification:message at:time read:read];
                handled = YES;
            }
        } else {
            DDLogWarn(@"unknown notification: %@", message);
            return;
        }
        if (!handled) {
            UnhandledNotification* un = [[UnhandledNotification alloc] init];
            un.notification = message;
            un.time = time;
            un.read = read;
            [_unhandledNotifications addObject:un];
            DDLogVerbose(@"notification without user in core data cache it(count: %d) to handle later: %@", _unhandledNotifications.count, message);
        }
    }
}

-(void)handlePendingNotifications{
    if (_handlingPendingNotifications) {
        return;
    }
    if (_unhandledNotifications.count > 0) {
        _handlingPendingNotifications = YES;
        DDLogVerbose(@"hanldle pending notifications... remaining: %d", _unhandledNotifications.count);
        UnhandledNotification* un = _unhandledNotifications[0];
        XMPPMessage* message = un.notification;
        NSString* userID = [self userIDFrom:message];
        
        void (^failure)(void) = ^(void) {
            DDLogError(@"failed to handle notif: %@", message);
            [_unhandledNotifications removeObjectAtIndex:0];
            _handlingPendingNotifications = NO;
        };
        
        if ([self isSimpleUserNotificaiton:message]) {
            fetch_user_success success = ^(User *user) {
                [self handleSinglePendingNotification:un];
            };
            User* user = [[UserService service] getOrFetchUserWithID:userID success:success failure:failure];
            if (user) {
                success(user);
            }
        } else if([self isMealNotification:message]){
            NSString* mealID = [self mealIDFrom:message];
            fetch_meal_success meal_success = ^(Meal *meal) {
                [self handleSinglePendingNotification:un];
            };
            
            fetch_user_success user_success = ^(User *user) {
                DDLogInfo(@"user info got, continue to fetch meal");
                Meal* meal = [[MealService service] getOrFetchMeal:mealID success:meal_success failure:failure];
                if (meal) {
                    meal_success(meal);
                }
            };
            User* user = [[UserService service] getOrFetchUserWithID:userID success:user_success failure:failure];
            if (user) {
                user_success(user);
            }
        } else if([self isPhotoNotification:message]){
            NSString* photoID = [self photoIDFrom:message];
            fetch_photo_success photo_success = ^(Photo *photo) {
                photo.user = [[UserService service] userWithID:userID]; //user should be available now when photo is fetched
                [self handleSinglePendingNotification:un];
            };
            
            fetch_user_success user_success = ^(User *user) {
                DDLogInfo(@"user info got, continue to fetch photo");
                Photo* photo = [[PhotoService service] getOrFetchPhoto:photoID success:photo_success failure:failure];
                photo.user = user;
                if (photo) {
                    photo_success(photo);
                }
            };
            User* user = [[UserService service] getOrFetchUserWithID:userID success:user_success failure:failure];
            if (user) {
                user_success(user);
            }
        } else {
            [_unhandledNotifications removeObjectAtIndex:0];
            DDLogWarn(@"ignore other notifications for now... remaining: %d", _unhandledNotifications.count);
            _handlingPendingNotifications = NO;
        }
    }
}

-(void)handleSinglePendingNotification:(UnhandledNotification*)un{
    [self doHandleNotification:un.notification at:un.time read:un.read];
    [_unhandledNotifications removeObject:un];
    DDLogInfo(@"hanlded a pending notification, remaining: %d", _unhandledNotifications.count);
    _handlingPendingNotifications = NO;
}

-(void)handleArchivedNotificatoin:(NSXMLElement*)event atTime:(NSDate*)time read:(BOOL)read{
    if (![self latestNotificationDate] || [time compare:[self latestNotificationDate]] > 0) {
        _latestNotificationDate = time;
    } else {
        DDLogInfo(@"Ignoring too old notification at: %@", time);
        return;
    }
    XMPPMessage* notification = [self createNotification:event];
    [self handleNotification:notification at:time read:read];
}

-(XMPPMessage*)createNotification:(NSXMLElement*)event{
    NSXMLElement *messageElement = [NSXMLElement elementWithName:@"message" xmlns:@"jabber:client"];
    [messageElement addAttributeWithName:@"from" stringValue:PUBSUB_SERVICE];
    [messageElement addAttributeWithName:@"to" stringValue:[UserService jidForUser:[UserService service].loggedInUser]];
    [messageElement addChild:event];
    return [XMPPMessage messageFromElement:messageElement];
}

//must be called when all required information is available, instancing User, Meal, Photo, etc.
-(void)doHandleNotification:(XMPPMessage*)message at:(NSDate*)time read:(BOOL)read{
    NSXMLElement *event = [message elementForName:@"event"];
    NSString* node = [self nodeNameFrom:event];
    NSString* payload = [self payloadFrom:event];
    NSDictionary* data = [payload objectFromJSONString];
    NSString* userId = [data valueForKey:@"user"];
    Notification* notification = nil;
    if (node) {
        if ([self isSimpleUserNotificaiton:message]) {            
            notification = [NSEntityDescription insertNewObjectForEntityForName:@"Notification" inManagedObjectContext:_mainQueueContext];
        } else if([self isMealNotification:message]){
            notification = [NSEntityDescription insertNewObjectForEntityForName:@"MealNotification" inManagedObjectContext:_mainQueueContext];
            MealNotification* mn = (MealNotification*)notification;
            mn.meal = [[MealService service] mealWithID:[self mealIDFrom:message]];
        } else if([self isPhotoNotification:message]){
            notification = [NSEntityDescription insertNewObjectForEntityForName:@"PhotoNotification" inManagedObjectContext:_mainQueueContext];
            PhotoNotification* pn = (PhotoNotification*)notification;
            pn.photo = [[PhotoService service] photoWithID:[self photoIDFrom:message]];
        } else {
            DDLogWarn(@"unknown notification with node: %@ and payload: %@", node, payload);
            return;
        }
        notification.eventDescription = [data valueForKey:@"event"];
    }
    
    if (notification) {
        notification.read = [NSNumber numberWithBool:read];
        notification.time = time;
        notification.owner = [UserService service].loggedInUser;
        notification.user = [[UserService service] userWithID:userId];
        notification.eventDescription = [data valueForKey:@"event"];
        notification.nID = [message attributeStringValueForName:@"id"];
        
        NSError* error;
        if(![_mainQueueContext saveToPersistentStore:&error]){
            DDLogError(@"failed to save notification:%@", notification);
        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:NotificationDidSaveNotification
                                                                object:notification
                                                              userInfo:nil];
            [self updateStatusBar:notification];
            if (![notification.read boolValue]) {
                [self setUnreadNotifCount:_unreadNotifCount + 1];
            }
        }
    }
}

-(void)updateStatusBar:(Notification*)notification{
    //notification is not read and is a recent notification, i.e. not an archived one, and not suspend(notfication view visible)
    if (![notification.read boolValue] && ABS([notification.time timeIntervalSinceNow]) < 5 && !_suspend) {
        MTStatusBarOverlay* status = [MTStatusBarOverlay sharedInstance];
        status.animation = MTStatusBarOverlayAnimationShrink;
        NSString* message = [NSString stringWithFormat:@"%@%@", notification.user.name, notification.eventDescription];
        [status postMessage:message duration:2];
    }
}

-(NSDate*)latestNotificationDate{
    if (_latestNotificationDate) {
        return _latestNotificationDate;
    }
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    fetchRequest.entity = [NSEntityDescription entityForName:@"Notification" inManagedObjectContext:_mainQueueContext];
    fetchRequest.includesSubentities = YES;
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"owner == %@", [UserService service].loggedInUser];
    NSSortDescriptor *sortByTime = [[NSSortDescriptor alloc] initWithKey:@"time" ascending:NO];
    fetchRequest.sortDescriptors = @[sortByTime];
    fetchRequest.fetchLimit = 1;
    NSError* error;
    NSArray* objects = [_mainQueueContext executeFetchRequest:fetchRequest error:&error];
    if (objects.count > 0) {
        Notification* notif = objects[0];
        _latestNotificationDate =  notif.time;
    }
    return _latestNotificationDate;
}

-(BOOL)getOrFetchMeal:(NSString*)mID{
    Meal* meal = [[MealService service] getOrFetchMeal:mID success:^(Meal *meal) {
        [self handleMealNotifications:meal];
    } failure:^{
        DDLogError(@"failed to fetch meal with ID(%@), unhandled message count: %d", mID, _unhandledNotifications.count);
    }];
    return meal != nil;
}

-(BOOL)getOrFetchPhoto:(NSString*)pID{
    Photo* photo = [[PhotoService service] getOrFetchPhoto:pID success:^(Photo *photo) {
        [self handlePhotoNotifications:photo];
    } failure:^{
        DDLogError(@"failed to fetch meal with ID(%@), unhandled message count: %d", pID, _unhandledNotifications.count);
    }];
    return photo != nil;
}

-(BOOL)getOrFetchUser:(NSString*)uID{
    User* user = [[UserService service] getOrFetchUserWithID:uID success:^(User *user) {
        [self handleNotificationsFor:user];
    } failure:^{
        DDLogError(@"failed to fetch user with ID(%@), unhandled message count: %d", uID, _unhandledNotifications.count);
    }];
    return user != nil;
}

-(void)handlePhotoNotifications:(Photo*)photo{
    NSMutableArray* handledMessages = [NSMutableArray array];
    for (UnhandledNotification* un in _unhandledNotifications) {
        XMPPMessage* notification = un.notification;
        NSString* photoID = [NSString stringWithFormat:@"%@", [self photoIDFrom:notification]];
        NSDate* time = un.time;
        if ([photoID isEqualToString:[photo.pID stringValue]]) {
            if ([self isPhotoNotification:notification] && [[UserService service] userWithID:[self userIDFrom:notification]]) {
                [self doHandleNotification:notification at:time read:un.read];
                DDLogInfo(@"message %@ handled", un);
                [handledMessages addObject:un];
            }
        }
    }
    [_unhandledNotifications removeObjectsInArray:handledMessages];
    DDLogInfo(@"Remaining unhanlded messages: %d", _unhandledNotifications.count);
}

-(void)handleMealNotifications:(Meal*)meal{
    NSMutableArray* handledMessages = [NSMutableArray array];
    for (UnhandledNotification* un in _unhandledNotifications) {
        XMPPMessage* message = un.notification;
        NSString* mealID = [NSString stringWithFormat:@"%@", [self mealIDFrom:message]];
        NSDate* time = un.time;
        if ([mealID isEqualToString:[meal.mID stringValue]]) {
            if ([self isMealNotification:message] && [[UserService service] userWithID:[self userIDFrom:message]]) {
                [self doHandleNotification:message at:time read:un.read];
                DDLogInfo(@"message %@ handled", message);
                [handledMessages addObject:message];
            }
        }
    }
    [_unhandledNotifications removeObjectsInArray:handledMessages];
    DDLogInfo(@"Remaining unhanlded messages: %d", _unhandledNotifications.count);
}

-(void)handleNotificationsFor:(User*)user{
    NSMutableArray* handledMessages = [NSMutableArray array];
    for (UnhandledNotification* un in _unhandledNotifications) {
        XMPPMessage* message = un.notification;
        NSString* userId = [NSString stringWithFormat:@"%@", [self userIDFrom:message]];
        NSDate* time = un.time;
        if ([userId isEqualToString:[user.uID stringValue]]) {
            if ([self isSimpleUserNotificaiton:message]
                || ([self isMealNotification:message] && [[MealService service] mealWithID:[self mealIDFrom:message]])
                || ([self isPhotoNotification:message] && [[PhotoService service] photoWithID:[self photoIDFrom:message]])
                ) {
                [self doHandleNotification:message at:time read:un.read];
                DDLogInfo(@"message %@ handled", message);
                [handledMessages addObject:message];
            }
        }
    }
    [_unhandledNotifications removeObjectsInArray:handledMessages];
    DDLogInfo(@"Remaining unhanlded messages: %d", _unhandledNotifications.count);
}

-(BOOL)isSimpleUserNotificaiton:(XMPPMessage*)message{
    NSXMLElement *event = [message elementForName:@"event"];
    NSString* node = [self nodeNameFrom:event];
    return [node hasSuffix:@"/followers"] || [node hasSuffix:@"/visitors"] || [node hasSuffix:@"/photo_requests"];
}

-(BOOL)isMealNotification:(XMPPMessage*)message{
    NSXMLElement *event = [message elementForName:@"event"];
    NSString* node = [self nodeNameFrom:event];
    return [node hasSuffix:@"/participants"] || [node hasSuffix:@"/meals"];
}

-(BOOL)isPhotoNotification:(XMPPMessage*)message{
    NSXMLElement *event = [message elementForName:@"event"];
    NSString* node = [self nodeNameFrom:event];
    return [node hasSuffix:@"/photos"];
}


-(NSString*)nodeNameFrom:(NSXMLElement*)eventElement{
    NSXMLElement *items = [eventElement elementForName:@"items"];
    return [items attributeStringValueForName:@"node"];
}

-(NSString*)payloadFrom:(NSXMLElement*)eventElement{
    NSXMLElement *items = [eventElement elementForName:@"items"];
    NSXMLElement *entry = [[items elementForName:@"item"] elementForName:@"entry"];
    return [entry stringValue];
}

-(NSString*)userIDFrom:(XMPPMessage*)message{
    NSXMLElement *event = [message elementForName:@"event"];
    NSString* payload = [self payloadFrom:event];
    NSDictionary* data = [payload objectFromJSONString];
    return [data valueForKey:@"user"];
}

-(NSString*)mealIDFrom:(XMPPMessage*)message{
    NSXMLElement *event = [message elementForName:@"event"];
    NSString* payload = [self payloadFrom:event];
    NSDictionary* data = [payload objectFromJSONString];
    return [data valueForKey:@"meal"];
}

-(NSString*)photoIDFrom:(XMPPMessage*)message{
    NSXMLElement *event = [message elementForName:@"event"];
    NSString* payload = [self payloadFrom:event];
    NSDictionary* data = [payload objectFromJSONString];
    return [data valueForKey:@"photo_id"];
}

-(void)markAllNotificationsRead{
    XMPPMessage* message = [[XMPPMessage alloc] init];
    [message addAttributeWithName:@"to" stringValue:PUBSUB_SERVICE];
    NSXMLElement* receivedElement = [[NSXMLElement alloc] initWithName:@"received" xmlns:@"urn:xmpp:receipts"];
    [message addChild:receivedElement];
    [_xmppStream sendElement:message];
    [self setUnreadNotifCount:0];
}

-(void)setUnreadNotifCount:(NSInteger)unreadNotifCount{
    if (unreadNotifCount != _unreadNotifCount) {
        _unreadNotifCount = unreadNotifCount;
        [[NSUserDefaults standardUserDefaults] setInteger:_unreadNotifCount forKey:[self unreadNotificationKey]];
        [[NSNotificationCenter defaultCenter] postNotificationName:UnreadNotificationCount
                                                            object:[NSNumber numberWithInteger:_unreadNotifCount]
                                                          userInfo:nil];
    }
}


@end
