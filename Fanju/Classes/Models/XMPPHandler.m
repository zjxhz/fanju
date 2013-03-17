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

NSString * const EOMessageDidSaveNotification = @"EOMessageDidSaveNotification";
NSString * const EONotificationDidSaveNotification = @"EONotificationDidSaveNotification";
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
        _currentUser = [Authentication sharedInstance].currentUser;
        _xmppStream = [[XMPPStream alloc] init];
        [_xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
        _xmppReconnect = [[XMPPReconnect alloc] init];
        [_xmppReconnect activate:_xmppStream];
        _messageCoreDataStorage = [[ChatHistoryCoreDataStorage alloc] initWithDatabaseFilename:[NSString stringWithFormat:@"ChatHistory_%d.sqlite", _currentUser.uID]];
        _messageManagedObjectContext = [_messageCoreDataStorage mainThreadManagedObjectContext];
        _xmppRosterStorage = [[XMPPRosterCoreDataStorage alloc] initWithDatabaseFilename:[NSString stringWithFormat:@"XMPPRoster_%d.sqlite", _currentUser.uID]];
        _rosterManagedObjectContext = [_xmppRosterStorage mainThreadManagedObjectContext];
        
        _xmppRoster = [[XMPPRoster alloc] initWithRosterStorage:_xmppRosterStorage];
        
        _xmppRoster.autoFetchRoster = YES;
        _xmppRoster.autoAcceptKnownPresenceSubscriptionRequests = YES;
        [_xmppRoster activate:_xmppStream];
        [_xmppRoster addDelegate:self delegateQueue:dispatch_get_main_queue()];
        
        // Setup vCard support
        //
        // The vCard Avatar module works in conjuction with the standard vCard Temp module to download user avatars.
        // The XMPPRoster will automatically integrate with XMPPvCardAvatarModule to cache roster photos in the roster.
        
        _xmppvCardStorage = [XMPPvCardCoreDataStorage sharedInstance];
        _xmppvCardTempModule = [[XMPPvCardTempModule alloc] initWithvCardStorage:_xmppvCardStorage];
        _xmppvCardAvatarModule = [[XMPPvCardAvatarModule alloc] initWithvCardTempModule:_xmppvCardTempModule];
        [_xmppvCardTempModule   activate:_xmppStream];
        [_xmppvCardTempModule addDelegate:self delegateQueue:dispatch_get_main_queue()];
        [_xmppvCardAvatarModule activate:_xmppStream];
        _cachedMessages = [NSMutableArray array];
        _unreadNotifCount = [[NSUserDefaults standardUserDefaults] integerForKey:UNREAD_MESSAGE_COUNT];
    }
    _xmppStream.myJID = [XMPPJID jidWithString:_currentUser.jabberID];
    _xmppStream.hostName = EOHOST;
    NSError* error = nil;
    if (![_xmppStream connect:&error]) {
        NSLog(@"Opps, I probably forgot something: %@", error);
    } else {
        NSLog(@"Probably connected?");
    }
    [self loadRecentContacts];
}

-(void)loadRecentContacts{
    _recentContactsDict = [NSMutableDictionary dictionary];
    NSFetchRequest *req = [[NSFetchRequest alloc] init];
    NSManagedObjectContext* context = _messageManagedObjectContext;
    req.entity = [NSEntityDescription entityForName:@"RecentContact" inManagedObjectContext:context];
    NSError* error;
    NSArray* objects = [context executeFetchRequest:req error:&error];
    for (RecentContact *contact in objects) {
        [_recentContactsDict setObject:contact forKey:contact.contact];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(currentContactChanged:)
                                                 name:EOCurrentContact
                                               object:nil];
}

-(void)updateRecentMessages:(EOMessage*)message{
    RecentContact* contact = nil;
    if ([_recentContactsDict objectForKey:message.sender] ) { //someone i know sent me a message
        contact = [_recentContactsDict objectForKey:message.sender];
        if (![message.sender isEqualToString:_currentContact]) {
            contact.unread = [NSNumber numberWithInteger:([contact.unread integerValue] + 1)];
            NSLog(@"unread message from %@: %@", message.sender, contact.unread);
            [self updateStatusBar:message];
        }
    } else if ([_recentContactsDict objectForKey:message.receiver]) { //i send a message
        contact = [_recentContactsDict objectForKey:message.receiver];
        NSLog(@"a message sent to %@", message.receiver);
    } else { //a message between i and a user i have never talked to
        contact = [NSEntityDescription insertNewObjectForEntityForName:@"RecentContact" inManagedObjectContext:_messageManagedObjectContext];
        UserProfile* currentUser = [Authentication sharedInstance].currentUser;
        BOOL iamSender = [message.sender hasPrefix:currentUser.jabberID];
        if (iamSender) {
            contact.contact = message.receiver;
            contact.unread = 0;
        } else {
            contact.contact = message.sender;
            contact.unread = [NSNumber numberWithInteger:1];
            [self updateStatusBar:message];
        }
        [_recentContactsDict setValue:contact forKey:contact.contact];
        NSLog(@"a message betwen %@ who i have never talked to", contact.contact);
    }
    contact.message = message.message;
    contact.time = message.time;
    [_recentContactsDict setValue:contact forKey:contact.contact];
    [self updateUnreadCount];
}

-(void)updateStatusBar:(EOMessage*)message{
    MTStatusBarOverlay* status = [MTStatusBarOverlay sharedInstance];
    status.animation = MTStatusBarOverlayAnimationShrink;
    XMPPUserCoreDataStorageObject *user = [_xmppRosterStorage userForJID:[XMPPJID jidWithString:message.sender]
                                                              xmppStream:_xmppStream
                                                    managedObjectContext:_rosterManagedObjectContext];
    
    NSString* name  = user ? user.nickname : [[message.sender componentsSeparatedByString:@"@"] objectAtIndex:0];
    [status postMessage:[NSString stringWithFormat:@"%@: %@", name, message.message] duration:2];
}

-(void)updateUnreadCount{
    int totoalUnread = 0;
    for(RecentContact* c in [_recentContactsDict allValues]){
        totoalUnread += [c.unread integerValue];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:EOUnreadMessageCount
                                                        object:[NSNumber numberWithInteger:totoalUnread]
                                                      userInfo:nil];
    [UIApplication sharedApplication].applicationIconBadgeNumber = totoalUnread;
}

-(NSArray*)recentContacts{
    return [_recentContactsDict allValues];
}

-(void)tearDown{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_xmppStream removeDelegate:self];
    [_xmppRoster removeDelegate:self];
    [_xmppvCardTempModule removeDelegate:self];
    
    [_xmppReconnect deactivate];
    [_xmppRoster deactivate];
    [_xmppvCardTempModule deactivate];
    [_xmppvCardAvatarModule deactivate];
    [_xmppStream disconnect];
    
    _xmppStream = nil;
    _xmppReconnect = nil;
    _xmppRoster = nil;
    _xmppRosterStorage = nil;
    _xmppvCardTempModule = nil;
    _xmppvCardAvatarModule = nil;
    _messageCoreDataStorage = nil;   
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
        NSLog(@"Opps, login to xmpp server failed: %@", error);
    } else {
        NSLog(@"XMPP logged in");
        
    }
}

- (void)xmppStream:(XMPPStream *)sender didSendMessage:(XMPPMessage *)message{
    NSLog(@"XMPP Message sent: %@", message);
}

- (void)xmppStream:(XMPPStream *)sender didReceiveError:(NSXMLElement *)error{
    NSLog(@"did received xmpp error: %@", error);
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender{
    [self goOnline];
}

- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)error;{
    NSLog(@"Opps, authentication failed: %@", error);
}

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message{
    if ([message isChatMessageWithBody]){
        NSLog(@"Received a chat message from %@", sender);
        if (![self addSenderIfNeeded:message]) { // no need to add the user, already in roster
            [self handleReceivedMessage:message];
        };
    } else {
        NSLog(@"Received notification");
        [self handleReceivedNotification:message];
    }
}

-(void)handleReceivedNotification:(XMPPMessage*)message{
    NSXMLElement *event = [message elementForName:@"event"];
    NSXMLElement *items = [event elementForName:@"items"];
    NSString* node = [items attributeStringValueForName:@"node"];
    NSXMLElement *entry = [[items elementForName:@"item"] elementForName:@"entry"];
    NSString* payload = [entry stringValue];
    [self saveNotification:node payload:payload];
}

-(void) saveNotification:(NSString*)node payload:(NSString*)payload{
    EOMessage* message = [NSEntityDescription insertNewObjectForEntityForName:@"EOMessage" inManagedObjectContext:_messageManagedObjectContext];
    message.time = [NSDate date];
    message.node = node;
    message.payload = payload;
    
//    [self updateRecentMessages:messageMO]; TODO unread count
    
    NSError* error;
    if(![_messageManagedObjectContext save:&error]){
        NSLog(@"failed to save a message");
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:EONotificationDidSaveNotification
                                                            object:message
                                                          userInfo:nil];
        _unreadNotifCount = [[NSUserDefaults standardUserDefaults] integerForKey:UNREAD_NOTIFICATION_COUNT];
        _unreadNotifCount++;
        [[NSNotificationCenter defaultCenter] postNotificationName:EOUnreadNotificationCount
                                                            object:[NSNumber numberWithInteger:_unreadNotifCount]
                                                          userInfo:nil];
    }

}

-(void)handleReceivedMessage:(XMPPMessage*)message{
    NSString* strMessage = [[message elementForName:@"body"] stringValue];
    [self saveMessage:message.fromStr receiver:message.toStr message:strMessage];
}

-(void)saveMessage:(NSString*)sender receiver:(NSString*)receiver message:(NSString*)message {
    EOMessage* messageMO  = [NSEntityDescription insertNewObjectForEntityForName:@"EOMessage" inManagedObjectContext:_messageManagedObjectContext];
    XMPPJID *senderJID = [XMPPJID jidWithString:sender];
    XMPPJID *receiverJID = [XMPPJID jidWithString:receiver];
    sender = senderJID.bare;
    receiver = receiverJID.bare;
    messageMO.sender = sender;
    messageMO.receiver = receiver;
    messageMO.time = [NSDate date];
    messageMO.message = message;
    messageMO.type = @"chat";
 
    [self updateRecentMessages:messageMO];
    
    NSError* error;
    if(![_messageManagedObjectContext save:&error]){
        NSLog(@"failed to save a message");
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:EOMessageDidSaveNotification
                                                            object:messageMO
                                                          userInfo:nil];
    }

}

-(void)sendMessage:(EOMessage*)message{
    [self addReceiverBeforeSendingIfNeeded:[XMPPJID jidWithString:message.receiver] ];
    NSLog(@"sending message: %@", message);
    NSString* messageStr =message.message;
    NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
    [body setStringValue:messageStr];
    NSXMLElement *messageElement = [NSXMLElement elementWithName:@"message"];
    [messageElement addAttributeWithName:@"to" stringValue:message.receiver];
    [messageElement addAttributeWithName:@"type" stringValue:@"chat"];
    [messageElement addChild:body];
    [_xmppStream sendElement:messageElement];
}

-(void)addReceiverBeforeSendingIfNeeded:(XMPPJID*)jID{
    XMPPUserCoreDataStorageObject *user = [_xmppRosterStorage userForJID:jID
                                                             xmppStream:_xmppStream
                                                   managedObjectContext:_rosterManagedObjectContext];
    if (!user) {
        
        XMPPvCardTemp* vCard = [_xmppvCardTempModule fetchvCardTempForJID:jID];
        [_xmppRoster addUser:jID withNickname:vCard.nickname];
        NSLog(@"got a message with no roster item, adding sender %@ with nickname: %@", jID, vCard.nickname);
    }
}

-(BOOL)addSenderIfNeeded:(XMPPMessage*)message{
    XMPPJID* jID = message.from;
    XMPPUserCoreDataStorageObject *user = [_xmppRosterStorage userForJID:jID
                                                              xmppStream:_xmppStream
                                                    managedObjectContext:_rosterManagedObjectContext];
    if (!user) {
        
        XMPPvCardTemp* vCard = [_xmppvCardTempModule fetchvCardTempForJID:jID];
        [_xmppRoster addUser:jID withNickname:vCard.nickname];
        NSLog(@"got a message with no roster item, adding sender %@ with nickname: %@", jID, vCard.nickname);
        [_cachedMessages addObject:message];
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq{
    if ([iq.type isEqualToString:@"result"] && [[iq attributeStringValueForName:@"id"] rangeOfString:@"roster"].location != NSNotFound ) {
        NSMutableArray* messagesGotUserInRoster = [NSMutableArray array];
        for (XMPPMessage* message in _cachedMessages) {
            XMPPJID* jID = message.from;

            XMPPUserCoreDataStorageObject *user = [_xmppRosterStorage userForJID:jID
                                                                      xmppStream:_xmppStream
                                                            managedObjectContext:_rosterManagedObjectContext];
            if (user){
                [messagesGotUserInRoster addObject:message];
                [self handleReceivedMessage:message];
            }
        }
        [_cachedMessages removeObjectsInArray:messagesGotUserInRoster];
    }
    
    return NO;
}

- (void)goOnline
{
	XMPPPresence *presence = [XMPPPresence presence]; // type="available" is implicit
	[_xmppStream sendElement:presence];
}

- (void)xmppvCardTempModule:(XMPPvCardTempModule *)vCardTempModule
        didReceivevCardTemp:(XMPPvCardTemp *)vCardTemp
                     forJID:(XMPPJID *)jid{
    XMPPUserCoreDataStorageObject *user = [_xmppRosterStorage userForJID:jid xmppStream:_xmppStream managedObjectContext:_rosterManagedObjectContext];
    if (user) {
        [_xmppRoster setNickname:vCardTemp.nickname forUser:user.jid];
        NSLog(@"setting nickname %@ for user %@", user.nickname, user.jid.user);
    }
}

-(void)currentContactChanged:(NSNotification*)notif {
    _currentContact = notif.object;
}

-(void)deleteRecentContact:(NSString*)jid{
    NSFetchRequest *req = [[NSFetchRequest alloc] init];
    NSManagedObjectContext* context = _messageManagedObjectContext;
    req.entity = [NSEntityDescription entityForName:@"EOMessage" inManagedObjectContext:context];
    req.predicate = [NSPredicate predicateWithFormat:@"receiver BEGINSWITH %@ OR sender BEGINSWITH %@", jid, jid];
    NSError* error;
    NSArray* objects = [context executeFetchRequest:req error:&error];
    for (EOMessage *message in objects) {
        [context deleteObject:message];
    }
    
    req.entity = [NSEntityDescription entityForName:@"RecentContact" inManagedObjectContext:context];
    req.predicate = [NSPredicate predicateWithFormat:@"contact BEGINSWITH %@", jid];
    objects = [context executeFetchRequest:req error:&error];
    for (RecentContact *contact in objects) {
        [context deleteObject:contact];
    }
    
    [_recentContactsDict removeObjectForKey:jid];
    if(![context save:&error]){
        NSLog(@"failed to delete messages for %@", jid);
    }
    [self updateUnreadCount];

}

#pragma makr XMPPRosterDelegate
- (void)xmppRoster:(XMPPRoster *)sender didReceivePresenceSubscriptionRequest:(XMPPPresence *)presence{
    [sender acceptPresenceSubscriptionRequestFrom:presence.from andAddToRoster:YES];
}
@end
