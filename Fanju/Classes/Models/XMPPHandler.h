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

@interface XMPPHandler : NSObject<XMPPStreamDelegate>{
    XMPPReconnect* _xmppReconnect;
    ChatHistoryCoreDataStorage* _messageCoreDataStorage;
    UserProfile* _currentUser;
    XMPPRoster *_xmppRoster;
    NSMutableDictionary* _recentContactsDict;
    NSString* _currentContact;
    NSMutableArray* _cachedMessages;//received messages which the sender is not in my roster,  these messages should be fired only when the roster is ready
    NSInteger _unreadNotifCount;
}
@property(nonatomic, strong) XMPPStream* xmppStream;
@property(nonatomic, strong) NSManagedObjectContext* messageManagedObjectContext;
@property(nonatomic, strong) NSManagedObjectContext* rosterManagedObjectContext;
@property(nonatomic, readonly) NSArray* recentContacts;
@property(nonatomic, readonly) XMPPRosterCoreDataStorage* xmppRosterStorage;
@property(nonatomic, readonly) XMPPvCardCoreDataStorage *xmppvCardStorage;
@property(nonatomic, readonly) XMPPvCardTempModule *xmppvCardTempModule;
@property(nonatomic, readonly) XMPPvCardAvatarModule *xmppvCardAvatarModule;
-(void)setup;
-(void)tearDown;
+(XMPPHandler*)sharedInstance;
-(void)saveMessage:(NSString*)sender receiver:(NSString*)receiver message:(NSString*)message;
-(void)sendMessage:(EOMessage*)message;
-(void)updateUnreadCount;
-(void)deleteRecentContact:(NSString*)jid;
@end

extern NSString* const EOMessageDidSaveNotification;
extern NSString* const EONotificationDidSaveNotification;
extern NSString * const EOMessageDidDeleteNotification;
extern NSString* const EOCurrentContact;
extern NSString* const EOUnreadMessageCount;
extern NSString* const EOUnreadNotificationCount;