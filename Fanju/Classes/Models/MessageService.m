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
NSString * const EOCurrentConversation = @"EOCurrentConversation";

@implementation MessageService{
    XMPPStream* _xmppStream;
    NSMutableDictionary* _unhandledMessages; // messages not have no user found in core data yet, hanlde it later
//    dispatch_queue_t _background_queue;
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
        _xmppStream = [XMPPHandler sharedInstance].xmppStream;
        [_xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    return self;
}

-(void)setup{
    if (!_xmppStream) {
        DDLogError(@"ERROR: stream not initialized");
        return;
    }
    _unhandledMessages = [NSMutableDictionary dictionary];
//    _background_queue = dispatch_queue_create("MessageRetrievingQueue", DISPATCH_QUEUE_SERIAL);
    RKManagedObjectStore* store = [RKObjectManager sharedManager].managedObjectStore;
    _mainQueueContext = store.mainQueueManagedObjectContext;
    [self loadRecentContacts];
}

-(void)tearDown{
    
}

-(void)loadRecentContacts{
    _conversations = [NSMutableArray array];
    NSFetchRequest *req = [[NSFetchRequest alloc] init];
    req.entity = [NSEntityDescription entityForName:@"Conversation" inManagedObjectContext:_mainQueueContext];
    req.predicate = [NSPredicate predicateWithFormat:@"owner.uID == %d", [Authentication sharedInstance].currentUser.uID];
    NSError* error;
    _conversations = [[_mainQueueContext executeFetchRequest:req error:&error] mutableCopy];
    if (error) {
        DDLogError(@"ERROR: failed to fetch converstations, %@", error);
    }
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(currentContactChanged:)
//                                                 name:EOCurrentConversation
//                                               object:nil];
}

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message{
    if ([message wasDelayed]) {
        DDLogVerbose(@"ignoring offline messages as we are handling archived messages only");
        return;
    }
    if ([message isChatMessageWithBody]){
        DDLogVerbose(@"Received a chat message from %@: %@", message.fromStr, [[message elementForName:@"body"] stringValue]);
        if ([self getOrFetchUser:message]) {
            [self handleReceivedMessage:message time:[NSDate date]];
        } else {
            DDLogVerbose(@"message with no user info available, cache it to handle later: %@", message);
            _unhandledMessages[message] = [NSDate date];
        }
    }
}

-(BOOL)getOrFetchUser:(XMPPMessage*)message{
    User* user = [[UserService shared] getOrFetchUserWithJID:message.from.bare success:^(User *user) {
        [self hanldeMessagesFor:user];
    } failure:^{
        DDLogWarn(@"failed to fetch user for jid(%@), unhandled message count: %d", message.from, _unhandledMessages.count);
    }];
    return user != nil;
}

//-(XMPPMessage*)createMessage:(NSString*)message from:(NSString*)from to:(NSString*)to{
//    NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
//    [body setStringValue:message];
//    NSXMLElement *messageElement = [NSXMLElement elementWithName:@"message"];
//    [messageElement addAttributeWithName:@"from" stringValue:from];
//    [messageElement addAttributeWithName:@"to" stringValue:to];
//    [messageElement addAttributeWithName:@"type" stringValue:@"chat"];
//    [messageElement addChild:body];
//    return messageElement;
//}

-(void)hanldeMessagesFor:(User*)user{
    NSString* userJID = [NSString stringWithFormat:@"%@@%@", user.username, XMPP_HOST];
    NSMutableArray* handledMessages = [NSMutableArray array];
    for (XMPPMessage* message in [_unhandledMessages allKeys]) {
        if ([message.from.bare isEqualToString:userJID]) {
            NSDate* time = _unhandledMessages[message];
            [self handleReceivedMessage:message time:time];
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

-(void)handleReceivedMessage:(XMPPMessage*)message time:(NSDate*)time{
    UserMessage* messageObject = [NSEntityDescription insertNewObjectForEntityForName:@"UserMessage" inManagedObjectContext:_mainQueueContext];
    messageObject.incoming = [NSNumber numberWithBool:YES];
    messageObject.message = [[message elementForName:@"body"] stringValue];
    messageObject.time = time;
    messageObject.owner = [UserService shared].loggedInUser;
    messageObject.with = [[UserService shared] userWithJID:message.from.bare];
    
    if ([self isMessageFromCurrentConversation:messageObject]){
        messageObject.read = [NSNumber numberWithBool:YES];
    } else {
        messageObject.read = [NSNumber numberWithBool:NO];
        [self updateStatusBar:messageObject];
    }

    [self updateConversation:messageObject];
    [self saveMessage:messageObject];
    
}

//- (void)xmppStream:(XMPPStream *)sender didSendMessage:(XMPPMessage *)message{
//    DDLogVerbose(@"XMPP Message sent: %@", message);
//    if ([message isMessageWithBody]) {
//        NSString* strMessage = [[message elementForName:@"body"] stringValue];
//        [self saveMessage:message.fromStr receiver:message.toStr message:strMessage time:[NSDate date] hasRead:NO];
//    }
//}

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
    UserMessage* messageObject = [NSEntityDescription insertNewObjectForEntityForName:@"UserMessage" inManagedObjectContext:_mainQueueContext];
    messageObject.incoming = NO;
    messageObject.message = [[message elementForName:@"body"] stringValue];
    messageObject.read = [NSNumber numberWithBool:YES];
    messageObject.time = [NSDate date];
    messageObject.owner = [UserService shared].loggedInUser;
    messageObject.with = [[UserService shared] userWithJID:message.to.bare];
    [self updateConversation:messageObject];
}

-(void)updateStatusBar:(UserMessage*)message{
    MTStatusBarOverlay* status = [MTStatusBarOverlay sharedInstance];
    status.animation = MTStatusBarOverlayAnimationShrink;
    [status postMessage:[NSString stringWithFormat:@"%@: %@", message.with.name, message.message] duration:1.5];
}

-(BOOL)isMessageFromCurrentConversation:(UserMessage*)message{
    return [message.with isEqual:_currentContact];
}

-(Conversation*)findConversation:(User*)with{
    for (Conversation* c in _conversations) {
        if ([c.with isEqual:with]) {
            return c;
        }
    }
    return nil;
}

-(void)updateConversation:(UserMessage*)message{
    [self updateConversation:message unreadCount:1];
}

//update conversation after retrieveing a bunch of messages and updated with last message
-(void)updateConversation:(UserMessage*)message unreadCount:(NSInteger)unreadCount{
    Conversation* conversation = [self findConversation:message.with];
    if (conversation) {
        if ([self isMessageFromCurrentConversation:message]) {
            [self markMessagesReadFrom:conversation.with];
            conversation.unread = [NSNumber numberWithInteger:0];
        } else if (message.incoming) {
            conversation.unread = [NSNumber numberWithInteger:conversation.unread.integerValue + unreadCount];
        }
    } else { //a message between i and a user i have never talked to
        conversation = [NSEntityDescription insertNewObjectForEntityForName:@"Conversation" inManagedObjectContext:_mainQueueContext];
        conversation.owner = message.owner;
        conversation.with = message.with;
        
        if (message.incoming) {
            conversation.unread = [NSNumber numberWithInteger:unreadCount];
        } else {
            conversation.unread = [NSNumber numberWithInteger:0];
        }
        [_conversations addObject:conversation];
    }
    conversation.incoming = message.incoming;
    conversation.message = message.message;
    conversation.time = message.time;
    [self updateUnreadCount];
}

-(void)updateUnreadCount{
    int totoalUnread = 0;
    for(Conversation* c in _conversations){
        NSInteger unread = [c.unread integerValue];
        totoalUnread += unread;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:EOUnreadMessageCount
                                                        object:[NSNumber numberWithInteger:totoalUnread]
                                                      userInfo:nil];
//    [UIApplication sharedApplication].applicationIconBadgeNumber = totoalUnread; TODO
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
//    NSFetchRequest *req = [[NSFetchRequest alloc] init];
//    NSManagedObjectContext* context = _messageManagedObjectContext;
//    req.entity = [NSEntityDescription entityForName:@"EOMessage" inManagedObjectContext:context];
//    req.predicate = [NSPredicate predicateWithFormat:@"receiver BEGINSWITH %@ OR sender BEGINSWITH %@", jid, jid];
//    NSError* error;
//    NSArray* objects = [context executeFetchRequest:req error:&error];
//    for (EOMessage *message in objects) {
//        [context deleteObject:message];
//    }
//    
//    req.entity = [NSEntityDescription entityForName:@"RecentContact" inManagedObjectContext:context];
//    req.predicate = [NSPredicate predicateWithFormat:@"contact BEGINSWITH %@", jid];
//    objects = [context executeFetchRequest:req error:&error];
//    for (RecentContact *contact in objects) {
//        [context deleteObject:contact];
//    }
//    
//    [_recentContactsDict removeObjectForKey:jid];
//    if(![context save:&error]){
//        DDLogError(@"failed to delete messages for %@", jid);
//    }
//    [self updateUnreadCount];
}


@end
