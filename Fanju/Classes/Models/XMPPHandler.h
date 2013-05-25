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
    UserProfile* _currentUser;
}
@property(nonatomic, strong) XMPPStream* xmppStream;
-(void)setup;
-(void)tearDown;
+(XMPPHandler*)sharedInstance;
@end

extern NSString* const EOMessageDidSaveNotification;
extern NSString * const EOMessageDidDeleteNotification;
extern NSString* const EOCurrentContact;
extern NSString* const EOUnreadMessageCount;
extern NSString* const EOUnreadNotificationCount;