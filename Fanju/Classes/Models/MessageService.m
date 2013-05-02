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
@implementation MessageService{
    XMPPStream* _xmppStream;
    dispatch_queue_t _background_queue;
}


-(void)setup{
    if (!_xmppStream) {
        NSLog(@"ERROR: stream not initialized");
        return;
    }
    _background_queue = dispatch_queue_create("MessageRetrievingQueue", DISPATCH_QUEUE_SERIAL);
    [_xmppStream addDelegate:self delegateQueue:_background_queue];

    
//    _messageCoreDataStorage = [[ChatHistoryCoreDataStorage alloc] initWithDatabaseFilename:[NSString stringWithFormat:@"ChatHistory_%d.sqlite", _currentUser.uID]];
//    _messageManagedObjectContext = [_messageCoreDataStorage mainThreadManagedObjectContext];
//    _background_queue = dispatch_queue_create("MessageRetrievingQueue", DISPATCH_QUEUE_SERIAL);
//    _xmppRosterStorage = [[XMPPRosterCoreDataStorage alloc] initWithDatabaseFilename:[NSString stringWithFormat:@"XMPPRoster_%d.sqlite", _currentUser.uID]];
//    _rosterManagedObjectContext = [_xmppRosterStorage mainThreadManagedObjectContext];
//    
//    _xmppRoster = [[XMPPRoster alloc] initWithRosterStorage:_xmppRosterStorage];
//    
//    _xmppRoster.autoFetchRoster = YES;
//    _xmppRoster.autoAcceptKnownPresenceSubscriptionRequests = YES;
//    [_xmppRoster activate:_xmppStream];
//    [_xmppRoster addDelegate:self delegateQueue:dispatch_get_main_queue()];
//    
//    // Setup vCard support
//    //
//    // The vCard Avatar module works in conjuction with the standard vCard Temp module to download user avatars.
//    // The XMPPRoster will automatically integrate with XMPPvCardAvatarModule to cache roster photos in the roster.
//    
//    _xmppvCardStorage = [XMPPvCardCoreDataStorage sharedInstance];
//    _xmppvCardTempModule = [[XMPPvCardTempModule alloc] initWithvCardStorage:_xmppvCardStorage];
//    _xmppvCardAvatarModule = [[XMPPvCardAvatarModule alloc] initWithvCardTempModule:_xmppvCardTempModule];
//    [_xmppvCardTempModule   activate:_xmppStream];
//    [_xmppvCardTempModule addDelegate:self delegateQueue:dispatch_get_main_queue()];
//    [_xmppvCardAvatarModule activate:_xmppStream];
//    _cachedMessages = [NSMutableArray array];
//    _unreadNotifCount = [[NSUserDefaults standardUserDefaults] integerForKey:UNREAD_MESSAGE_COUNT];
//    _lastRetrievedTimes = [NSMutableDictionary dictionary];
//
//    _xmppStream.myJID = [XMPPJID jidWithString:_currentUser.jabberID];
//    _xmppStream.hostName = EOHOST;
//    NSError* error = nil;
//    if (![_xmppStream connect:&error]) {
//        NSLog(@"Opps, I probably forgot something: %@", error);
//    } else {
//        NSLog(@"Probably connected?");
//    }
//    [self loadRecentContacts];
//    [self loadLatestNotificationDate];
}

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message{
    if ([message wasDelayed]) {
        // NSLog(@"ignoring offline messages as we are handling archived messages only");
        return;
    }
    if ([message isChatMessageWithBody]){
        NSLog(@"Received a chat message from %@", sender);
//        if (![self addSenderIfNeeded:message]) { // no need to add the user, already in roster
//            [self handleReceivedMessage:message];
//        };
    }
}

@end
