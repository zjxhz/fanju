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

#define MAX_RETRIEVE 20


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
        _background_queue = dispatch_queue_create("MessageRetrievingQueue", DISPATCH_QUEUE_SERIAL);
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
        _lastRetrievedTimes = [NSMutableDictionary dictionary];
    }
    _xmppStream.myJID = [XMPPJID jidWithString:_currentUser.jabberID];
    _xmppStream.hostName = XMPP_HOST;
    NSError* error = nil;
    if (![_xmppStream connect:&error]) {
        DDLogVerbose(@"Opps, I probably forgot something: %@", error);
    } else {
        DDLogVerbose(@"Probably connected?");
    }
    [self loadRecentContacts];
    [self loadLatestNotificationDate];
    [[MessageService service] setup];
}

-(void)loadLatestNotificationDate{
    NSFetchRequest *req = [[NSFetchRequest alloc] init];
    req.entity = [NSEntityDescription entityForName:@"EOMessage" inManagedObjectContext:_messageManagedObjectContext];
    req.predicate = [NSPredicate predicateWithFormat:@"node != ''"];
    NSSortDescriptor *sortByTime = [[NSSortDescriptor alloc] initWithKey:@"time" ascending:NO];
    req.sortDescriptors = @[sortByTime];
    req.fetchLimit = 1;
    NSArray* objects = [_messageManagedObjectContext executeFetchRequest:req error:nil];
    if (objects && objects.count > 0) {
        EOMessage* message = objects[0];
        _latestNotificationDate = message.time;
    }
}
-(NSManagedObjectContext*)backgroundMessageManagedObjectContext{
    if (_backgroundMessageManagedObjectContext) {
        return _backgroundMessageManagedObjectContext;
    }
    dispatch_block_t block = ^{
        _backgroundMessageManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSConfinementConcurrencyType];
        NSPersistentStoreCoordinator* coordinator = [_messageCoreDataStorage persistentStoreCoordinator];
        _backgroundMessageManagedObjectContext.persistentStoreCoordinator = coordinator;
        _backgroundMessageManagedObjectContext.undoManager = nil;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(managedObjectContextDidSave:)
                                                     name:NSManagedObjectContextDidSaveNotification
                                                   object:nil];
    };
    if( dispatch_get_current_queue() == _background_queue){
        block();
    } else {
        dispatch_sync(_background_queue, block);
    }
    
    return _backgroundMessageManagedObjectContext;
}

- (void)managedObjectContextDidSave:(NSNotification *)notification
{
	NSManagedObjectContext *sender = (NSManagedObjectContext *)[notification object];
	
	if ((sender != _backgroundMessageManagedObjectContext) &&
	    (sender.persistentStoreCoordinator == _backgroundMessageManagedObjectContext.persistentStoreCoordinator))
	{	
		dispatch_async(_background_queue, ^{
			[_backgroundMessageManagedObjectContext mergeChangesFromContextDidSaveNotification:notification];
		});
    }
}


-(void)loadRecentContacts{
    _recentContactsDict = [NSMutableDictionary dictionary];
    NSFetchRequest *req = [[NSFetchRequest alloc] init];
    req.entity = [NSEntityDescription entityForName:@"RecentContact" inManagedObjectContext:_messageManagedObjectContext];
    NSError* error;
    NSArray* objects = [_messageManagedObjectContext executeFetchRequest:req error:&error];
    for (RecentContact *contact in objects) {
        [_recentContactsDict setObject:contact forKey:contact.contact];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(currentContactChanged:)
                                                 name:EOCurrentContact
                                               object:nil];
}

-(NSDate*)latestMessageDate{
    NSDate* latest = nil;
    for (RecentContact *contact in [_recentContactsDict allValues]) {
        if (!latest || [contact.time compare:latest] == NSOrderedDescending ) {
            latest = [contact.time copy];
        }
    }
    return latest ? latest : [self twoWeeksAgo];
}

-(void)updateRecentMessages:(EOMessage*)message hasRead:(BOOL)read{
    RecentContact* contact = nil;
    if ([_recentContactsDict objectForKey:message.sender] ) { //someone i know sent me a message
        contact = [_recentContactsDict objectForKey:message.sender];
        if (![message.sender isEqualToString:_currentContact]) {
            contact.unread = [NSNumber numberWithInteger:([contact.unread integerValue] + 1)];
        } else { //a message from the one i'm currently talking to
            [self markMessagesReadFrom:contact.contact]; //mark all messages from this one as read
        }
    } else if ([_recentContactsDict objectForKey:message.receiver]) { //i send a message
        contact = [_recentContactsDict objectForKey:message.receiver];
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
        }
        [self addContactToCoreData:contact.contact];
        
        [_recentContactsDict setValue:contact forKey:contact.contact];
    }
    contact.message = message.message;
    contact.time = message.time;
    [_recentContactsDict setValue:contact forKey:contact.contact];
    if (read) {
        contact.unread = [NSNumber numberWithInteger:0]; // got a read message, set all older message as read
    }
}

-(void)addContactToCoreData:(NSString*)contactJID{
//    NSString* username = [contactJID componentsSeparatedByString:@"@"][0];
//    [[RKObjectManager sharedManager] getObjectsAtPath:@"/api/v1/user/" parameters:@{@"username":username} success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
//        DDLogVerbose(@"successed fetching and adding user(%@) to core data", username);
//    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
//        DDLogError(@"failed to fetch and add user(%@) to core data", username);
//    }];
}
-(void)markMessagesReadFrom:(NSString*)contactJID{
    XMPPMessage* message = [[XMPPMessage alloc] init];
    [message addAttributeWithName:@"to" stringValue:contactJID];
    NSXMLElement* receivedElement = [[NSXMLElement alloc] initWithName:@"received" xmlns:@"urn:xmpp:receipts"];
    [message addChild:receivedElement];
    
    [_xmppStream sendElement:message];
}

//-(void)updateStatusBarFrom:(NSString*)jid withMessage:(NSString*)message{
//    MTStatusBarOverlay* status = [MTStatusBarOverlay sharedInstance];
//    status.animation = MTStatusBarOverlayAnimationShrink;
//    
//    NSString* username = [[jid componentsSeparatedByString:@"@"] objectAtIndex:0];
//    
//    NSString* url = [NSString stringWithFormat:@"http://%@/api/v1/user/?user__username=%@&format=json", EOHOST, username];
//    __block NSString* strMessage = message;
//    [[NetworkHandler getHandler] requestFromURL:url method:GET cachePolicy:TTURLRequestCachePolicyDefault success:^(id obj) {
//        NSArray *users = [obj objectForKeyInObjects];
//        if (users && users.count > 0) {
//            UserProfile* user = users[0];
//            [status postMessage:[NSString stringWithFormat:@"%@: %@", user.name, strMessage] duration:1.5];
//        }
//    } failure:^{
//        [status postMessage:[NSString stringWithFormat:@"%@: %@", username, strMessage] duration:1.5];
//    }];
//}

-(void)updateStatusBarFrom:(NSString*)jid withMessage:(NSString*)message{
    MTStatusBarOverlay* status = [MTStatusBarOverlay sharedInstance];
    status.animation = MTStatusBarOverlayAnimationShrink;
    XMPPUserCoreDataStorageObject *user = [_xmppRosterStorage userForJID:[XMPPJID jidWithString:jid]
                                                              xmppStream:_xmppStream
                                                    managedObjectContext:_rosterManagedObjectContext];
        
    NSString* name  = user ? user.nickname : [[jid componentsSeparatedByString:@"@"] objectAtIndex:0];
    [status postMessage:[NSString stringWithFormat:@"%@: %@", name, message] duration:1.5];
}

-(void)updateUnreadCount{
    int totoalUnread = 0;
    for(RecentContact* c in [_recentContactsDict allValues]){
        NSInteger unread = [c.unread integerValue];
        totoalUnread += unread;
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
        DDLogError(@"login to xmpp server failed: %@", error);
    } else {
        DDLogVerbose(@"XMPP logged in");
        
    }
}

- (void)xmppStream:(XMPPStream *)sender didSendMessage:(XMPPMessage *)message{
//    DDLogVerbose(@"XMPP Message sent: %@", message);
//    if ([message isMessageWithBody]) {
//        NSString* strMessage = [[message elementForName:@"body"] stringValue];
//        [self saveMessage:message.fromStr receiver:message.toStr message:strMessage time:[NSDate date] hasRead:NO];
//    }
}

- (void)xmppStream:(XMPPStream *)sender didReceiveError:(NSXMLElement *)error{
    DDLogVerbose(@"did received xmpp error: %@", error);
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender{
    [self goOnline];
//    [self retrieveMessageHistory];
    [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(retrieveMessageHistory) userInfo:nil repeats:NO];
}

-(void)retrieveMessageHistory{
    [[ArchivedMessageService shared] retrieveConversations];
//    NSDate* latest = [self latestMessageDate];
//    _messageRetrieveDate = [latest copy];
//    _lastRetrievedTimes = [NSMutableDictionary dictionary];
//    [self retrieveConversationsStartFrom:_messageRetrieveDate after:-1];
}

-(void)retrieveConversationsStartFrom:(NSDate*)date after:(NSInteger)index{
    NSXMLElement *list = [NSXMLElement elementWithName:@"list" xmlns:@"urn:xmpp:archive"];
    NSString* strDate = [self.formatter stringFromDate:date];
	[list addAttributeWithName:@"start" stringValue:strDate];
	
    NSXMLElement *set = [NSXMLElement elementWithName:@"set" xmlns:@"http://jabber.org/protocol/rsm"];
    NSXMLElement *max = [NSXMLElement elementWithName:@"max"];
    [max setStringValue:[NSString stringWithFormat:@"%d", MAX_RETRIEVE]];
    if (index != -1) {
        NSXMLElement *after = [NSXMLElement elementWithName:@"after"];
        [after setStringValue:[NSString stringWithFormat:@"%d", index]];
        [set addChild:after];
    }
    [list addChild:set];
    [set addChild:max];
    
    XMPPIQ *iq = [XMPPIQ iqWithType:@"get"];
	[iq addChild:list];
	
	[_xmppStream sendElement:iq];
}


 -(NSDate*)twoWeeksAgo{
     NSCalendar *cal = [NSCalendar currentCalendar];
     NSDateComponents *components = [cal components:( NSEraCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:[[NSDate alloc] init]];
     [components setDay:([components day] - 14)];
     return [cal dateFromComponents:components];
 }

- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)error;{
    DDLogVerbose(@"Opps, authentication failed: %@", error);
}

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message{
//    if ([message wasDelayed]) {
//        DDLogVerbose(@"ignoring offline messages as we are handling archived messages only");
//        return;
//    }
//    if ([message isChatMessageWithBody]){
//        DDLogVerbose(@"Received a chat message from %@", sender);
//        if (![self addSenderIfNeeded:message]) { // no need to add the user, already in roster
//            [self handleReceivedMessage:message];
//        };
//    } else {
//        NSXMLElement *event = [message elementForName:@"event"];
//        if (event) {
//            DDLogVerbose(@"Received notification");
//            [self handleReceivedNotification:message];
//        } else {
//            DDLogVerbose(@"WARN: unknow message: %@", message);
//        }
//    }
}

-(void)handleReceivedNotification:(XMPPMessage*)message{
    NSXMLElement *event = [message elementForName:@"event"];
    [self saveNotification:[self nodeNameFrom:event] payload:[self payloadFrom:event]];
}

-(void) saveNotification:(NSString*)node payload:(NSString*)payload{
    EOMessage* message = [NSEntityDescription insertNewObjectForEntityForName:@"EOMessage" inManagedObjectContext:_messageManagedObjectContext];
    message.time = [NSDate date];
    message.node = node;
    message.payload = payload;
    
//    [self updateRecentMessages:messageMO]; TODO unread count
    
    NSError* error;
    if(![_messageManagedObjectContext save:&error]){
        DDLogError(@"failed to save a message");
    } else {
        if ([message.time compare:_latestNotificationDate] > 0 ) {
            _latestNotificationDate = message.time;
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:EONotificationDidSaveNotification
                                                            object:message
                                                          userInfo:nil];
        _unreadNotifCount++;
        [[NSNotificationCenter defaultCenter] postNotificationName:EOUnreadNotificationCount
                                                            object:[NSNumber numberWithInteger:_unreadNotifCount]
                                                          userInfo:nil];
    }

}

-(void)handleReceivedMessage:(XMPPMessage*)message{
    NSString* strMessage = [[message elementForName:@"body"] stringValue];
    [self saveMessage:message.fromStr receiver:message.toStr message:strMessage  time:[NSDate date] hasRead:NO];
    if (![message.from.bare isEqualToString:_currentContact]){
        [self updateStatusBarFrom:message.fromStr withMessage:strMessage];
    }
}

-(EOMessage*)insertMessage:(NSString*)sender receiver:(NSString*)receiver message:(NSString*)message time:(NSDate*)time inContext:(NSManagedObjectContext*)context{
    EOMessage* messageMO  = [NSEntityDescription insertNewObjectForEntityForName:@"EOMessage" inManagedObjectContext:context];
    XMPPJID *senderJID = [XMPPJID jidWithString:sender];
    XMPPJID *receiverJID = [XMPPJID jidWithString:receiver];
    sender = senderJID.bare;
    receiver = receiverJID.bare;
    messageMO.sender = sender;
    messageMO.receiver = receiver;
    messageMO.time = time;
    messageMO.message = message;
    messageMO.type = @"chat";
    return messageMO;
}

//save message from the main thread and post notifications, update unread count immediately
-(void)saveMessage:(NSString*)sender receiver:(NSString*)receiver message:(NSString*)message time:(NSDate*)time hasRead:(BOOL)read{
    EOMessage* messageMO = [self insertMessage:sender receiver:receiver message:message time:time inContext:_messageManagedObjectContext];
    [self updateRecentMessages:messageMO hasRead:read];
    [self updateUnreadCount];
    NSError* error;
    if(![_messageManagedObjectContext save:&error]){
        DDLogError(@"failed to save a message");
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:EOMessageDidSaveNotification
                                                        object:messageMO
                                                      userInfo:nil];
    }

}

-(void)addReceiverBeforeSendingIfNeeded:(XMPPJID*)jID{
    XMPPUserCoreDataStorageObject *user = [_xmppRosterStorage userForJID:jID
                                                              xmppStream:_xmppStream
                                                    managedObjectContext:_rosterManagedObjectContext];
    if (!user) {
        
        XMPPvCardTemp* vCard = [_xmppvCardTempModule fetchvCardTempForJID:jID];
        [_xmppRoster addUser:jID withNickname:vCard.nickname];
        DDLogVerbose(@"got a message with no roster item, adding sender %@ with nickname: %@", jID, vCard.nickname);
    }
}


-(BOOL)addSenderIfNeeded:(XMPPMessage*)message{
    BOOL added = [self addUserToRosterIfNeeded:message.from];
    if (added) {
        [_cachedMessages addObject:message];
    }
    return added;
}

-(BOOL)addUserToRosterIfNeeded:(XMPPJID*) jID{
    XMPPUserCoreDataStorageObject *user = [_xmppRosterStorage userForJID:jID
                                                              xmppStream:_xmppStream
                                                    managedObjectContext:_rosterManagedObjectContext];
    if (!user) {
        XMPPvCardTemp* vCard = [_xmppvCardTempModule fetchvCardTempForJID:jID];
        [_xmppRoster addUser:jID withNickname:vCard.nickname];
        DDLogVerbose(@"got a message with no roster item, adding sender %@ with nickname: %@", jID, vCard.nickname);
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq{
    if ([iq.type isEqualToString:@"result"] ){
        NSXMLElement *child = [iq childElement];
//        if([[iq attributeStringValueForName:@"id"] rangeOfString:@"roster"].location != NSNotFound ) {
//            NSMutableArray* messagesGotUserInRoster = [NSMutableArray array];
//            for (XMPPMessage* message in _cachedMessages) {
//                XMPPJID* jID = message.from;
//
//                XMPPUserCoreDataStorageObject *user = [_xmppRosterStorage userForJID:jID
//                                                                          xmppStream:_xmppStream
//                                                                managedObjectContext:_rosterManagedObjectContext];
//                if (user){
//                    [messagesGotUserInRoster addObject:message];
//                    [self handleReceivedMessage:message];
//                }
//            }
//            [_cachedMessages removeObjectsInArray:messagesGotUserInRoster];
//        } else
//        if([child.name isEqual:@"list" ] && [child.xmlns isEqual:@"urn:xmpp:archive"] ){
//            for (NSXMLElement* element in child.children)  {
//                if ([element.name isEqual:@"chat"]) {
//                    DDLogVerbose(@"conversation with chat: %@", element);
//                    NSString* after = [element attributeStringValueForName:@"start"];
//                    NSTimeInterval interval = [[self.formatter dateFromString:after] timeIntervalSince1970] - 0.001; //1 millisec earlier so the oldest one can be retrieved
//                    [self retrieveMessagesWith:[element attributeStringValueForName:@"with"] after:interval retrievingFromList:YES];
//                }
//                 else if([element.name isEqual:@"set"] && [element.xmlns isEqual:@"http://jabber.org/protocol/rsm"]){
//                    NSInteger firstIndex = [[[element elementForName:@"first"] attributeStringValueForName:@"index"] integerValue];
//                    NSInteger last = [[element elementForName:@"last"] stringValueAsInt];
//                    NSInteger count = [[element elementForName:@"count"] stringValueAsInt];
//                    if (firstIndex + MAX_RETRIEVE < count) {
//                        [self retrieveConversationsStartFrom:_messageRetrieveDate after:last];
//                    } else {
//                        //no more to retrieve
//                    }
//                }
//            }
//        } else if([child.name isEqual:@"chat"] && [child.xmlns isEqual:@"urn:xmpp:archive"]){
//            [self handleRetrievedMessages:child after:[child attributeStringValueForName:@"start"]];
//        }
    }
    
    return NO;
}

-(NSDateFormatter*)formatter{
    if (!_formatter) {
        _formatter = [[NSDateFormatter alloc] init];
        [_formatter setDateFormat: @"yyyy-MM-dd'T'HH:mm:ss.SSS'+08:00'"];
    }
    return _formatter;
}

//retrievingFromList: conversations with same ownerjid and withjid exist in the list only the oldest need to be used
-(void)retrieveMessagesWith:(NSString*)with after:(NSTimeInterval)interval retrievingFromList:(BOOL)retrievingFromList{
    NSDate* retrieveDateAfter = [NSDate dateWithTimeIntervalSince1970:interval];
    NSDate* lastRetrievedTime = [_lastRetrievedTimes valueForKey:with];
    if (retrievingFromList && lastRetrievedTime && [retrieveDateAfter compare:lastRetrievedTime] == NSOrderedDescending) {
        //retrieving from list can have duplicated entries for the same person, so we only use the oldest time
        DDLogVerbose(@"retrieving messages with %@, but the latest local messages are newer than the retrieve date %@, skip", with, retrieveDateAfter);
        return;
    }
    double intervalInMilliSeconds = interval * 1000;
    NSXMLElement *retrieve = [NSXMLElement elementWithName:@"retrieve" xmlns:@"urn:xmpp:archive"];
	[retrieve addAttributeWithName:@"with" stringValue:with];	
    NSXMLElement *set = [NSXMLElement elementWithName:@"set" xmlns:@"http://jabber.org/protocol/rsm"];
    NSXMLElement *max = [NSXMLElement elementWithName:@"max"];
    [max setStringValue:[NSString stringWithFormat:@"%d", MAX_RETRIEVE]];
    NSXMLElement* afterElement = [NSXMLElement elementWithName:@"after"];
    [afterElement setStringValue:[NSString stringWithFormat:@"%.0f", intervalInMilliSeconds]];
    
    [set addChild:max];
    [set addChild:afterElement];
    [retrieve addChild:set];
    XMPPIQ *iq = [XMPPIQ iqWithType:@"get"];
    [iq addChild:retrieve];
    [_xmppStream sendElement:iq];
    [_lastRetrievedTimes setValue:retrieveDateAfter forKey:with];
}

-(void)handleRetrievedMessages:(NSXMLElement*)chatElement after:(NSString*)after{
    dispatch_async(_background_queue, ^(void){
        NSDate* date = [self.formatter dateFromString:after];
        NSDate* endDate = [self.formatter dateFromString:[chatElement attributeStringValueForName:@"end"]];
        
        NSString* with = [XMPPJID jidWithString:[chatElement attributeStringValueForName:@"with"]].bare;
        EOMessage* messageMO = nil;
        NSInteger unread = 0;
        for (int i = 0; i < chatElement.children.count; ++i) {
            NSXMLElement* element = chatElement.children[i];
            NSString* from = nil;
            NSString* to = nil;
            
            if ([element.name isEqual:@"to"] ) {
                from =  [_currentUser jabberID];
                to = with;
            } else if([element.name isEqual:@"from"]){
                to = [_currentUser jabberID];
                from = with;
            }
            
            if ([element.name isEqual:@"from"] || [element.name isEqual:@"to"]){
                NSString* strMessage = [[element elementForName:@"body"] stringValue];
                NSInteger seconds = [[element attributeStringValueForName:@"secs"] integerValue];
                NSDate* messageDate = i == chatElement.children.count - 1 ? endDate : [date dateByAddingTimeInterval:seconds];//last message time must be accurate(in ms), others are in seconds
                
                if ([self isValiedMessage:with messageDate:messageDate message:strMessage]) {
                    if ([with isEqual:PUBSUB_SERVICE]){
                        _latestNotificationDate = messageDate;
                    }
                } else {
                    continue;
                }
                
                BOOL read = [element attributeBoolValueForName:@"isRead"];
                if (!read && ![from isEqual:[_currentUser jabberID]]) {
                    unread++;
                }
                
                if ([with isEqual:PUBSUB_SERVICE]) {
                    NSXMLElement* bodyElement = [element elementForName:@"body"] ;
                    NSXMLElement *event = [[NSXMLElement alloc] initWithXMLString:[bodyElement stringValue] error:nil];
                    messageMO = [NSEntityDescription insertNewObjectForEntityForName:@"EOMessage" inManagedObjectContext:[self backgroundMessageManagedObjectContext]];
                    messageMO.time = messageDate;
                    messageMO.node = [self nodeNameFrom:event];
                    messageMO.payload = [self payloadFrom:event];
                    _unreadNotifCount++;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[NSNotificationCenter defaultCenter] postNotificationName:EONotificationDidSaveNotification
                                                                            object:messageMO
                                                                          userInfo:nil];
                    });
                } else {
                    messageMO = [self insertMessage:from receiver:to message:strMessage time:messageDate inContext:[self backgroundMessageManagedObjectContext]];
                }               
            }
        }
        if (messageMO) {
            NSError* error;
            if(![[self backgroundMessageManagedObjectContext] save:&error]){
                DDLogError(@"failed to save messages in background");
            }
            if ([with isEqual:PUBSUB_SERVICE]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:EOUnreadNotificationCount
                                                                        object:[NSNumber numberWithInteger:_unreadNotifCount]
                                                                      userInfo:nil];
                });
            } else {
                RecentContact* contact = [_recentContactsDict valueForKey:with];
                if (!contact) {
                    contact = [NSEntityDescription insertNewObjectForEntityForName:@"RecentContact" inManagedObjectContext:[self backgroundMessageManagedObjectContext]];
                    UserProfile* currentUser = [Authentication sharedInstance].currentUser;
                    BOOL iamSender = [messageMO.sender hasPrefix:currentUser.jabberID];
                    if (iamSender) {
                        contact.contact = messageMO.receiver;
                    } else {
                        contact.contact = messageMO.sender;
                    }
                    [self addContactToCoreData:contact.contact];
                    [_recentContactsDict setValue:contact forKey:contact.contact];
                }
                contact.message = messageMO.message;
                contact.time = messageMO.time;
                contact.unread = [NSNumber numberWithInteger:([contact.unread integerValue] + unread)];
                [_recentContactsDict setValue:contact forKey:contact.contact];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self updateUnreadCount];
                    [[NSNotificationCenter defaultCenter] postNotificationName:EOMessageDidSaveNotification
                                                                        object:messageMO
                                                                      userInfo:nil];
                });
            }

        }
        NSInteger more = [[chatElement attributeStringValueForName:@"more"] integerValue];
        if (more > 0) {
            DDLogVerbose(@"retrieving more messages after %@", endDate);
            [self retrieveMessagesWith:with after:[endDate timeIntervalSince1970] retrievingFromList:NO];
        }
        [NSThread sleepForTimeInterval:0.1];//slow down the background saving as it might block GUIs

    });
}

-(BOOL)isValiedMessage:(NSString*)with messageDate:(NSDate*)messageDate message:(NSString*)strMessage{
    if ([with isEqual:PUBSUB_SERVICE]) {
        return !_latestNotificationDate || [messageDate compare:_latestNotificationDate] > 0;
    } else {
        RecentContact* contact = [_recentContactsDict objectForKey:with];
        if (contact){
            NSTimeInterval delta = [messageDate timeIntervalSinceDate:contact.time];
            if ((delta < 5 && [strMessage isEqual:contact.message]) || delta < 0) {
                DDLogVerbose(@"ignoring message(%@ - at:%@) that is either too old or has same time(%@) and same content with the latest one", strMessage, messageDate, contact.time);
                return NO;
            }
        }
    }
    return YES;
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
        DDLogVerbose(@"setting nickname %@ for user %@", user.nickname, user.jid.user);
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
        DDLogError(@"failed to delete messages for %@", jid);
    }
    [self updateUnreadCount];

}

#pragma makr XMPPRosterDelegate
- (void)xmppRoster:(XMPPRoster *)sender didReceivePresenceSubscriptionRequest:(XMPPPresence *)presence{
    [sender acceptPresenceSubscriptionRequestFrom:presence.from andAddToRoster:YES];
}
@end
