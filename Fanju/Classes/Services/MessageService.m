//
//  MessageService.m
//  Fanju
//
//  Created by Xu Huanze on 5/2/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import "MessageService.h"
#import "XMPPStream.h"
#import "XMPPElement+Delay.h"
#import "XMPPFramework.h"
#import "RestKit.h"
#import "UserService.h"
#import "UserMessage.h"
#import "Conversation.h"
#import "Authentication.h"
#import "MTStatusBarOverlay.h"

NSString * const MessageDidSaveNotification = @"MessageDidSaveNotification";
NSString * const CurrentConversation = @"CurrentConversation";

@implementation MessageService{
    XMPPStream* _xmppStream;
    NSMutableDictionary* _unhandledMessages; // messages not have no user found in core data yet, hanlde it later
    User* _currentContact;
    NSManagedObjectContext* _mainQueueContext;
}

+(MessageService*)service{
    static MessageService* instance = nil;
    if (!instance) {
        instance = [[MessageService alloc] init];
    }
    return instance;
}

-(id)init{
    if (self = [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(currentConversationChanged:)
                                                     name:CurrentConversation
                                                   object:nil];
        RKManagedObjectStore* store = [RKObjectManager sharedManager].managedObjectStore;
        _mainQueueContext = store.mainQueueManagedObjectContext;
    }
    return self;
}

-(void)setup{
    DDLogVerbose(@"setting up %@", [self class]);
    _xmppStream = [XMPPHandler sharedInstance].xmppStream;
    [_xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
    _unhandledMessages = [NSMutableDictionary dictionary];
    _unreadMessageCount = [[NSUserDefaults standardUserDefaults] integerForKey:[self unreadMessageKey]];
    [[NSNotificationCenter defaultCenter] postNotificationName:EOUnreadMessageCount
                                                        object:[NSNumber numberWithInteger:_unreadMessageCount]
                                                      userInfo:nil]; //initial notif to update total
    [self loadConversations];
}

-(NSString*)unreadMessageKey{
    return [NSString stringWithFormat:@"%@_%@", [UserService service].loggedInUser.uID, UNREAD_MESSAGE_COUNT];
}

-(void)tearDown{
    DDLogVerbose(@"tearing down %@", [self class]);
    [_xmppStream removeDelegate:self];
}

-(void)loadConversations{
    _conversations = [NSMutableArray array];
    NSFetchRequest *req = [[NSFetchRequest alloc] init];
    req.entity = [NSEntityDescription entityForName:@"Conversation" inManagedObjectContext:_mainQueueContext];
    req.predicate = [NSPredicate predicateWithFormat:@"owner = %@", [UserService service].loggedInUser];
    NSError* error;
    _conversations = [[_mainQueueContext executeFetchRequest:req error:&error] mutableCopy];
    if (error) {
        DDLogError(@"ERROR: failed to fetch converstations, %@", error);
    }
}

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message{
    if ([message wasDelayed]) {
        DDLogVerbose(@"ignoring offline messages as we are handling archived messages only");
        return;
    }
    if ([message isChatMessageWithBody]){
        DDLogVerbose(@"Received a chat message from %@: %@", message.fromStr, [[message elementForName:@"body"] stringValue]);
        if ([self getOrFetchUser:message.from]) {
            [self doHandleReceivedMessage:message time:[NSDate date]];
        } else {
            DDLogVerbose(@"message with no user info available, cache it to handle later: %@", message);
            _unhandledMessages[message] = [NSDate date];
        }
    } else{
        NSXMLElement* composing = [message elementForName:@"composing" xmlns:@"http://jabber.org/protocol/chatstates"];
        if (composing){
            //TODO and pause
        }
    }
}


-(BOOL)getOrFetchUser:(XMPPJID*)jid{
    User* user = [[UserService service] getOrFetchUserWithJID:jid.bare success:^(User *user) {
        [self handleMessagesFor:user];
    } failure:^{
        DDLogWarn(@"failed to fetch user for jid(%@), unhandled message count: %d", jid.bare, _unhandledMessages.count);
    }];
    return user != nil;
}

-(void)handleMessagesFor:(User*)user{
    NSString* userJID = [NSString stringWithFormat:@"%@@%@", user.username, XMPP_HOST];
    NSMutableArray* handledMessages = [NSMutableArray array];
    for (XMPPMessage* message in [_unhandledMessages allKeys]) {
        if ([message.from.bare isEqualToString:userJID]) {
            NSDate* time = _unhandledMessages[message];
            [self doHandleReceivedMessage:message time:time];
            DDLogInfo(@"message %@ handled", message);
            [handledMessages addObject:message];
        } else if ([message.to.bare isEqualToString:userJID]){
            [self handleSentMessage:message];
            [handledMessages addObject:message];
        }
    }
    [_unhandledMessages removeObjectsForKeys:handledMessages];
    DDLogInfo(@"Remaining unhanlded messages: %d", _unhandledMessages.count);
}

//all info e.g. sender, receiver must be available when calling this method
-(void)doHandleReceivedMessage:(XMPPMessage*)message time:(NSDate*)time{
    User* owner = [UserService service].loggedInUser;
    User* with = [[UserService service] userWithJID:message.from.bare];
    NSAssert(with, @"user not found in core data before calling this method: %@", message.from.bare);
    Conversation* conversation = [self getOrCreateConversation:owner with:with];
    
    UserMessage* messageObject = [NSEntityDescription insertNewObjectForEntityForName:@"UserMessage" inManagedObjectContext:_mainQueueContext];
    messageObject.incoming = [NSNumber numberWithBool:YES];
    messageObject.message = [[message elementForName:@"body"] stringValue];
    messageObject.time = time;

    
    if ([self isMessageFromCurrentConversation:with]){
        messageObject.read = [NSNumber numberWithBool:YES];
    } else {
        messageObject.read = [NSNumber numberWithBool:NO];
        [self updateStatusBar:[NSString stringWithFormat:@"%@: %@", with.name, messageObject.message]];
    }
    messageObject.conversation = conversation;
    [self updateConversation:conversation withMessage:messageObject];
    [self saveMessage:messageObject];
}

-(void)currentConversationChanged:(NSNotification*)notif{
    _currentContact = notif.object;
}

-(void)saveMessage:(UserMessage*)message{
    //save to parent context will perform the save immediately
    NSError* error;
    
    if(![_mainQueueContext saveToPersistentStore:&error]){
        DDLogError(@"failed to save messages or conversations");
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:MessageDidSaveNotification
                                                            object:message
                                                          userInfo:nil];
    }
}

-(void)handleSentMessage:(XMPPMessage*)message{
    if (![message isChatMessageWithBody]) {
        DDLogVerbose(@"ignoring sent message: %@, which is not a chat message with body", message);
        return;
    }
    UserMessage* messageObject = [NSEntityDescription insertNewObjectForEntityForName:@"UserMessage" inManagedObjectContext:_mainQueueContext];
    messageObject.incoming = [NSNumber numberWithBool:NO];
    messageObject.message = [[message elementForName:@"body"] stringValue];
    messageObject.read = [NSNumber numberWithBool:YES];
    messageObject.time = [NSDate date];
    User *owner = [UserService service].loggedInUser;
    User *with = [[UserService service] userWithJID:message.to.bare];
    Conversation* conversation = [self getOrCreateConversation:owner with:with];
    messageObject.conversation = conversation;
    [self saveMessage:messageObject];
    [self updateConversation:conversation withMessage:messageObject];
}

-(void)updateStatusBar:(NSString*)message{
    MTStatusBarOverlay* status = [MTStatusBarOverlay sharedInstance];
    status.animation = MTStatusBarOverlayAnimationShrink;
    [status postMessage:message duration:1.5];
}

-(BOOL)isMessageFromCurrentConversation:(User*)with{
    return [with isEqual:_currentContact];
}

-(Conversation*)getOrCreateConversation:(User*)owner with:(User*)with{
    for (Conversation* c in _conversations) {
        if ([c.with isEqual:with]) {
            return c;
        }
    }
    Conversation* conversation = [NSEntityDescription insertNewObjectForEntityForName:@"Conversation" inManagedObjectContext:_mainQueueContext];
    conversation.owner = owner;
    conversation.with = with;
    [_conversations addObject:conversation];
    return conversation;
}


-(void)updateConversation:(Conversation*)conversation withMessage:(UserMessage*)message{
    [self updateConversation:conversation withMessage:message unreadCount:1];
}

-(void)updateConversation:(Conversation*)conversation withMessage:(UserMessage*)message unreadCount:(NSInteger)unreadCount{
    conversation.incoming = message.incoming;
    conversation.message = message.message;
    conversation.time = message.time;
    message.conversation = conversation;
    NSInteger unread = [conversation.unread integerValue];
    if ([self isMessageFromCurrentConversation:conversation.with]){
        unread = 0;
        [self markMessagesReadFrom:conversation.with];
    } else if(!message.incoming){
        unread  = 0;
    } else {
        unread += unreadCount;
    }
    conversation.unread = [NSNumber numberWithInteger:unread];
    [self updateUnreadCount];
}

-(void)updateUnreadCount{
    int totoalUnread = 0;
    for(Conversation* c in _conversations){
        NSInteger unread = [c.unread integerValue];
        totoalUnread += unread;
    }
    _unreadMessageCount = totoalUnread;
    [[NSUserDefaults standardUserDefaults] setInteger:_unreadMessageCount forKey:[self unreadMessageKey]];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:EOUnreadMessageCount
                                                        object:[NSNumber numberWithInteger:totoalUnread]
                                                      userInfo:nil];
}


-(void)markMessagesReadFrom:(User*)user{
    NSString* jidStr = [NSString stringWithFormat:@"%@@%@", user.username, XMPP_HOST];
    XMPPMessage* message = [[XMPPMessage alloc] init];
    [message addAttributeWithName:@"to" stringValue:jidStr];
    NSXMLElement* receivedElement = [[NSXMLElement alloc] initWithName:@"received" xmlns:@"urn:xmpp:receipts"];
    [message addChild:receivedElement];
    
    [_xmppStream sendElement:message];
}

-(void)deleteConversation:(Conversation*)conversation{
    [_mainQueueContext deleteObject:conversation];
    NSError* error = nil;
    if(![_mainQueueContext saveToPersistentStore:&error]){
        DDLogError(@"failed to delete conversation: %@", conversation);
    }
    [self updateUnreadCount];
}

- (void)xmppStream:(XMPPStream *)sender didSendMessage:(XMPPMessage *)message{
    DDLogVerbose(@"Send a chat message to %@: %@", message.toStr, [[message elementForName:@"body"] stringValue]);
    if (![message isChatMessageWithBody]) {
        DDLogVerbose(@"ignoring sent message: %@", message);
        return;
    }
    if ([self getOrFetchUser:message.to]) {
        [self handleSentMessage:message];
    } else {
        DDLogVerbose(@"senting message with no user info available, cache it to handle later: %@", message);
        _unhandledMessages[message] = [NSDate date];
    }
}

-(BOOL)isPubsubMessage:(XMPPMessage*)message{
    NSString* pubsub = [NSString stringWithFormat:@"pubsub.%@", XMPP_HOST];
    return [message.from.bare isEqual:pubsub] || [message.to.bare isEqual:pubsub];
}


@end
