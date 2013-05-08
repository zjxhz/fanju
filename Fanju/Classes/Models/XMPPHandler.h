//
//  XMPPHandler.h
//  EasyOrder
//
//  Created by 徐 浣泽 on 11/26/12.
//
//

#import <Foundation/Foundation.h>
#import "XMPPFramework.h"
#import "EOMessage.h"
#import "ChatHistoryCoreDataStorage.h"
#import "Authentication.h"
#define PUBSUB_SERVICE [NSString stringWithFormat:@"pubsub.%@", XMPP_HOST]

@interface XMPPHandler : NSObject<XMPPStreamDelegate>{
    XMPPReconnect* _xmppReconnect;
    ChatHistoryCoreDataStorage* _messageCoreDataStorage;
    UserProfile* _currentUser;
    XMPPRoster *_xmppRoster;
    NSMutableDictionary* _recentContactsDict;
    NSString* _currentContact;
    NSMutableArray* _cachedMessages;//received messages which the sender is not in my roster,  these messages should be fired only when the roster is ready
//    NSDate* _lastMessageDate;
    NSDate* _messageRetrieveDate;//current retrieve time as there may be several pages when retrieving
    NSDateFormatter* _formatter;
    NSMutableDictionary* _lastRetrievedTimes; //time of last retrieving messages for a contact to avoid duplicate retrieves
    dispatch_queue_t _background_queue;
    NSDate* _latestNotificationDate;
}
@property(nonatomic, strong) XMPPStream* xmppStream;
@property(nonatomic, strong) NSManagedObjectContext* messageManagedObjectContext;
@property(nonatomic, strong) NSManagedObjectContext* backgroundMessageManagedObjectContext;
@property(nonatomic, strong) NSManagedObjectContext* rosterManagedObjectContext;
@property(nonatomic, readonly) NSArray* recentContacts;
@property(nonatomic, readonly) XMPPRosterCoreDataStorage* xmppRosterStorage;
@property(nonatomic, readonly) XMPPvCardCoreDataStorage *xmppvCardStorage;
@property(nonatomic, readonly) XMPPvCardTempModule *xmppvCardTempModule;
@property(nonatomic, readonly) XMPPvCardAvatarModule *xmppvCardAvatarModule;
@property(nonatomic) NSInteger unreadNotifCount;
-(void)setup;
-(void)tearDown;
+(XMPPHandler*)sharedInstance;
-(void)updateUnreadCount;
-(void)deleteRecentContact:(NSString*)jid;
-(void)markMessagesReadFrom:(NSString*)contactJID;
-(void)retrieveMessagesWith:(NSString*)with after:(NSTimeInterval)interval retrievingFromList:(BOOL)retrievingFromList;
-(BOOL)addUserToRosterIfNeeded:(XMPPJID*)jID;
@end

extern NSString* const EOMessageDidSaveNotification;
extern NSString* const EONotificationDidSaveNotification;
extern NSString * const EOMessageDidDeleteNotification;
extern NSString* const EOCurrentContact;
extern NSString* const EOUnreadMessageCount;
extern NSString* const EOUnreadNotificationCount;