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
#import "MealCommentNotification.h"
#import "MealParticipant.h"
#import "Photo.h"
#import "MealComment.h"

NSString * const NotificationDidSaveNotification = @"NotificationDidSaveNotification";
NSString * const UnreadNotificationCount = @"UnreadNotificationCount";
@implementation NotificationService{
    XMPPStream* _xmppStream;
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
        NSString* node = [self nodeNameFrom:event];
        NSString* payload = [self payloadFrom:event];
        NSDictionary* data = [payload objectFromJSONString];
        NSString* eventDescription = [data valueForKey:@"event"];
        NSString* nID = [message attributeStringValueForName:@"id"];
        RKObjectManager* manager = [RKObjectManager sharedManager];
        if (node) {
            if ([self isSimpleUserNotificaiton:message]) {
                NSString* path = [NSString stringWithFormat:@"user/%@/",[self stringValueFrom:message key:@"user"]];
                [manager getObject:nil path:path parameters:nil success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult){
                    Notification* notification = [NSEntityDescription insertNewObjectForEntityForName:@"Notification" inManagedObjectContext:_mainQueueContext];
                    notification.user = mappingResult.firstObject;
                    [self saveNotification:notification nID:nID read:read time:time eventDescription:eventDescription];
                } failure:^(RKObjectRequestOperation *operation, NSError *error) {
                    DDLogError(@"failed to handle simple user notification: %@", error);
                }];
            } else if([self isMealNotification:message]){
                NSString* path = [NSString stringWithFormat:@"mealparticipant/%@/",[self stringValueFrom:message key:@"meal_participant"]];
                [manager getObject:nil path:path parameters:nil success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult){
                    Notification* notification = [NSEntityDescription insertNewObjectForEntityForName:@"MealNotification" inManagedObjectContext:_mainQueueContext];
                    MealNotification* mn = (MealNotification*)notification;
                    MealParticipant* mealParticipant = mappingResult.firstObject;
                    mn.meal = mealParticipant.meal;
                    mn.user = mealParticipant.user;
                    [self saveNotification:notification nID:nID read:read time:time eventDescription:eventDescription];
                } failure:^(RKObjectRequestOperation *operation, NSError *error) {
                    DDLogError(@"failed to handle meal notification: %@", error);
                }];
            } else if([self isPhotoNotification:message]){
                NSString* path = [NSString stringWithFormat:@"userphoto/%@/",[self stringValueFrom:message key:@"photo_id"]];
                [manager getObject:nil path:path parameters:nil success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult){
                    Notification* notification = [NSEntityDescription insertNewObjectForEntityForName:@"PhotoNotification" inManagedObjectContext:_mainQueueContext];
                    PhotoNotification* pn = (PhotoNotification*)notification;
                    Photo* photo = mappingResult.firstObject;
                    pn.photo = photo;
                    pn.user = photo.user;
                    [self saveNotification:notification nID:nID read:read time:time eventDescription:eventDescription];
                } failure:^(RKObjectRequestOperation *operation, NSError *error) {
                    DDLogError(@"failed to handle photo notification: %@", error);
                }];
            } else if([self isMealCommentNotification:message]){
                NSString* path = [NSString stringWithFormat:@"mealcomment/%@/",[self stringValueFrom:message key:@"comment_id"]];
                [manager getObject:nil path:path parameters:nil success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                    Notification* notification = [NSEntityDescription insertNewObjectForEntityForName:@"MealCommentNotification" inManagedObjectContext:_mainQueueContext];
                    MealCommentNotification* mcn = (MealCommentNotification*)notification;
                    mcn.comment = mappingResult.firstObject;
                    mcn.user = mcn.comment.user;
                    [self saveNotification:notification nID:nID read:read time:time eventDescription:eventDescription];
                } failure:^(RKObjectRequestOperation *operation, NSError *error) {
                    DDLogError(@"failed to handle meal comment notification: %@", error);
                }];
            } else {
                DDLogWarn(@"unknown notification with node: %@ and payload: %@", node, payload);
                return;
            }
        }
    }
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

-(void)saveNotification:(Notification*)notification nID:(NSString*)nID read:(BOOL)read time:(NSDate*)time eventDescription:(NSString*)eventDescription{
    notification.read = [NSNumber numberWithBool:read];
    notification.time = time;
    notification.owner = [UserService service].loggedInUser;
    notification.eventDescription = eventDescription;
    notification.nID = nID;
    
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

-(BOOL)isSimpleUserNotificaiton:(XMPPMessage*)message{
    return [self regularStringInNode:@"/user/\\d+/followers" message:message] || [self regularStringInNode:@"/user/\\d+/visitors" message:message]
                    || [self regularStringInNode:@"/user/\\d+/photo_request" message:message];
    
}

-(BOOL)isMealCommentNotification:(XMPPMessage*)message{
    return [self regularStringInNode:@"/meal/\\d/comments" message:message] || [self regularStringInNode:@"/user/\\d+/comments/reply" message:message];
}

-(BOOL)regularStringInNode:(NSString*)re message:(XMPPMessage*)message{
    NSXMLElement *event = [message elementForName:@"event"];
    NSString* node = [self nodeNameFrom:event];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:re
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:nil];
    NSUInteger numberOfMatches = [regex numberOfMatchesInString:node
                                                        options:0
                                                          range:NSMakeRange(0, [node length])];
    return numberOfMatches > 0;
}


-(BOOL)isMealNotification:(XMPPMessage*)message{
    return [self regularStringInNode:@"/meal/\\d+/participants" message:message] || [self regularStringInNode:@"/user/\\d+/meals" message:message];
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

-(NSString*)stringValueFrom:(XMPPMessage*)message key:(NSString*)key{
    NSXMLElement *event = [message elementForName:@"event"];
    NSString* payload = [self payloadFrom:event];
    NSDictionary* data = [payload objectFromJSONString];
    return [data valueForKey:key];
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
