//
//  XMPPHandler.m
//  EasyOrder
//
//  Created by 徐 浣泽 on 11/26/12.
//
//

#import "XMPPHandler.h"
#import "Const.h"
#import "RecentContact.h"
#import "AppDelegate.h"
#import "MTStatusBarOverlay.h"
#import "XMPPElement+Delay.h"
#import "RKObjectManager.h"
#import "MessageService.h"
#import "ArchivedMessageService.h"
#import "UserService.h"
#import "NotificationService.h"

#define MAX_RETRIEVE 20


NSString * const EOMessageDidSaveNotification = @"EOMessageDidSaveNotification";
NSString * const EOMessageDidDeleteNotification = @"EOMessageDidDeleteNotification";
NSString * const EOCurrentContact = @"EOCurrentContact";
NSString * const EOUnreadMessageCount = @"EOUnreadMessageCount";
NSString * const EOUnreadNotificationCount = @"EOUnreadNotificationCount";



@implementation XMPPHandler

+(XMPPHandler*)sharedInstance{
    static XMPPHandler* instance = nil;
    if (!instance) {
        instance = [[XMPPHandler alloc] init];
    }
    return instance;
}

-(void)setup{
    if (!_xmppStream) {

        _xmppStream = [[XMPPStream alloc] init];
        [_xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
        _xmppReconnect = [[XMPPReconnect alloc] init];
        [_xmppReconnect activate:_xmppStream];
    }
    _currentUser = [Authentication sharedInstance].currentUser;
    DDLogVerbose(@"setting xmpp jid %@ before logging in", _currentUser.jabberID);
    _xmppStream.myJID = [XMPPJID jidWithString:_currentUser.jabberID];
    _xmppStream.hostName = XMPP_HOST;
    NSError* error = nil;
    if (![_xmppStream connect:&error]) {
        DDLogVerbose(@"Opps, I probably forgot something: %@", error);
    } else {
        DDLogVerbose(@"Probably connected?");
    }
    [[UserService service] setup];
    [[MessageService service] setup];
    [[ArchivedMessageService service] setup];
    [[NotificationService service] setup];
}

-(void)tearDown{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NotificationService service] tearDown];
    [[MessageService service] tearDown];
    [[ArchivedMessageService service] tearDown];
    [[UserService service] tearDown];

    _currentUser = nil;
    [_xmppStream removeDelegate:self];
    
    [_xmppReconnect deactivate];
    [_xmppStream disconnect];
    
    _xmppStream = nil;
    _xmppReconnect = nil;
}

- (SinaWeibo *)sinaweibo{
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    return appDelegate.sinaweibo;
}

#pragma mark XMPPStreamDelegate
-(void)xmppStreamDidConnect:(XMPPStream*)sender{
    NSError* error = nil;
    NSString* password = _currentUser.password ? _currentUser.password : [self sinaweibo].accessToken;
    if (![_xmppStream authenticateWithPassword:password error:&error]) {
        DDLogError(@"login to xmpp server failed: %@", error);
    } else {
        DDLogVerbose(@"XMPP logged in");
        
    }
}

- (void)xmppStream:(XMPPStream *)sender didReceiveError:(NSXMLElement *)error{
    DDLogError(@"did received xmpp error: %@", error);
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender{
    DDLogInfo(@"XMPP authenticated");
    [self goOnline];
    [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(retrieveConversations) userInfo:nil repeats:NO];
}

-(void)retrieveConversations{
    [[ArchivedMessageService service] retrieveConversations];
}

- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)error;{
    DDLogError(@"Opps, authentication failed: %@", error);
}

- (void)goOnline
{
	XMPPPresence *presence = [XMPPPresence presence]; // type="available" is implicit
	[_xmppStream sendElement:presence];
}

#pragma makr XMPPRosterDelegate
- (void)xmppRoster:(XMPPRoster *)sender didReceivePresenceSubscriptionRequest:(XMPPPresence *)presence{
    [sender acceptPresenceSubscriptionRequestFrom:presence.from andAddToRoster:YES];
}
@end
