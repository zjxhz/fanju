//
//  ArchivedMessageService.m
//  Fanju
//
//  Created by Xu Huanze on 5/7/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import "ArchivedMessageService.h"
#import "XMPPFramework.h"
#import "User.h"
#import "XMPPHandler.h"
#import "MessageService.h"
#import "Conversation.h"
#import "User.h"
#import "Const.h"
#import "UserMessage.h"
#import "RestKit.h"
#import "UserService.h"

NSString * const LAST_SUCCESSFUL_RETRIEVE_DATE = @"LAST_SUCCESSFUL_RETRIEVE_DATE";
#define MAX_RETRIEVE 20

@implementation ArchivedMessageService{
    NSDate* _lastSuccessfulRetrieveDate;
    NSMutableArray* _unhanldedConversations;
    NSDateFormatter* _formatter;
    XMPPStream* _xmppStream;
    BOOL _retrievingConversations;
    NSManagedObjectContext* _mainQueueContext;
}
+(ArchivedMessageService*)shared{
    static dispatch_once_t onceToken;
    static ArchivedMessageService* instance = nil;
    dispatch_once(&onceToken,^{
        instance = [[ArchivedMessageService alloc] init];
    });
    return instance;
}

-(id)init{
    if (self = [super init]) {
        _xmppStream = [XMPPHandler sharedInstance].xmppStream;
        [_xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
        RKManagedObjectStore* store = [RKObjectManager sharedManager].managedObjectStore;
        _mainQueueContext = store.mainQueueManagedObjectContext;
        _unhanldedConversations = [NSMutableArray array];
        _lastSuccessfulRetrieveDate = [self lastSuccessfulRetrieveDate];
        DDLogInfo(@"init lastSuccessfulRetrieveDate value: %@", _lastSuccessfulRetrieveDate);
    }
    return self;
}


-(void)retrieveConversations{
    _retrievingConversations = YES;
    [self retrieveConversationsStartFrom:_lastSuccessfulRetrieveDate after:-1];
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

-(NSDateFormatter*)formatter{
    if (!_formatter) {
        _formatter = [[NSDateFormatter alloc] init];
        [_formatter setDateFormat: @"yyyy-MM-dd'T'HH:mm:ss.SSS'+08:00'"];
    }
    return _formatter;
}

-(NSDate*)latestMessageDate{
    NSDate* latest = nil;
    for (Conversation *conversation in [MessageService service].conversations) {
        if (!latest || [conversation.time compare:latest] == NSOrderedDescending ) {
            latest = [conversation.time copy];
        }
    }
    return latest;
}

-(NSDate*)lastSuccessfulRetrieveDate{
    if (_lastSuccessfulRetrieveDate) {
        return _lastSuccessfulRetrieveDate;
    }
//    _lastSuccessfulRetrieveDate = [[NSUserDefaults standardUserDefaults] valueForKey:LAST_SUCCESSFUL_RETRIEVE_DATE];
//    if(!_lastSuccessfulRetrieveDate){
//        _lastSuccessfulRetrieveDate = [self latestMessageDate];
//    }
//
    if(!_lastSuccessfulRetrieveDate){
        _lastSuccessfulRetrieveDate = [self twoWeeksAgo];
    }

    return _lastSuccessfulRetrieveDate;
}

-(void)setLastSuccessfulRetrieveDate:(NSDate*)date{
    DDLogInfo(@"Updating last successful retriving date to: %@", date);
    _lastSuccessfulRetrieveDate = [date copy];
//    NSData* data = [NSKeyedArchiver archivedDataWithRootObject:_lastSuccessfulRetrieveDate];
    [[NSUserDefaults standardUserDefaults] setObject:_lastSuccessfulRetrieveDate forKey:LAST_SUCCESSFUL_RETRIEVE_DATE];
    [[NSUserDefaults standardUserDefaults] synchronize];    
}

-(NSDate*)twoWeeksAgo{
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *components = [cal components:( NSEraCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:[[NSDate alloc] init]];
    [components setDay:([components day] - 14)];
    return [cal dateFromComponents:components];
}

#pragma mark XMPP Delegate
- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq{
    if ([iq.type isEqualToString:@"result"] ){
        NSXMLElement *child = [iq childElement];
        if([child.name isEqual:@"list" ] && [child.xmlns isEqual:@"urn:xmpp:archive"] ){
            for (NSXMLElement* element in child.children)  {
                if ([element.name isEqual:@"chat"]) {
                    NSString* with = [element attributeStringValueForName:@"with"];
                    DDLogInfo(@"retrived conversation with: %@", with);
                    if (![_unhanldedConversations containsObject:with]) {
                        [_unhanldedConversations addObject:with];
                    } else {
                        DDLogWarn(@"unhandled conversation found, ignore this one");
                        continue;
                    }
                }
                else if([element.name isEqual:@"set"] && [element.xmlns isEqual:@"http://jabber.org/protocol/rsm"]){
                    DDLogVerbose(@"retrieved conversation set: %@ ", element);
                    NSInteger firstIndex = [[[element elementForName:@"first"] attributeStringValueForName:@"index"] integerValue];
                    NSInteger last = [[element elementForName:@"last"] stringValueAsInt];
                    NSInteger count = [[element elementForName:@"count"] stringValueAsInt];
                    if (firstIndex + MAX_RETRIEVE < count) {
//                        DDLogWarn(@"sleeping 5 seconds for testing retriving more, put the app to background now!");
//                        sleep(5);
                        DDLogInfo(@"retriving more conversations...");
                        [self retrieveConversationsStartFrom:[self lastSuccessfulRetrieveDate] after:last];
                    } else {
                        DDLogVerbose(@"no more to come, done with conversations");
                        _retrievingConversations = NO;
                        [self retrieveMessages];
                        [self setLastSuccessfulRetrieveDate:[NSDate date]];
                        
                    }
                }
            }
        } else if([child.name isEqual:@"chat"] && [child.xmlns isEqual:@"urn:xmpp:archive"]){
            [self handleRetrievedMessages:child after:[child attributeStringValueForName:@"start"]];
        }
    }
    
    return NO;
}

-(void)retrieveMessages{
    for (NSString* unhandledConversation in _unhanldedConversations) {
        Conversation* localConversation = [self localConversationWith:unhandledConversation];
        NSDate* afterDate = nil;
        if (!localConversation) {
            DDLogWarn(@"Messages from new contact %@, retriving messages only 2 weeks ago, maybe we can let user to decide if he wants retrive more",
                      unhandledConversation);
            afterDate = [self twoWeeksAgo];
        } else {
            afterDate = localConversation.time;
        }
        void (^block)(void) = ^(void){
            DDLogInfo(@"retriving messages with %@ after: %@", unhandledConversation, afterDate);
            [self retrieveMessagesWith:unhandledConversation after:[afterDate timeIntervalSince1970]];
        };
        User* user = [[UserService shared] userWithJID:unhandledConversation];
        if (!user) {
            [[UserService shared] getOrFetchUserWithJID:unhandledConversation success:^(User *user) {
                block();
            } failure:^{
                DDLogError(@"failed to fetch user with jid: %@, some archived message may be missing", unhandledConversation);
            }];
        } else {
            block();
        }
        
    }
}

-(Conversation*)localConversationWith:(NSString*)with{
    for (Conversation *conversation in [MessageService service].conversations) {
        NSString* withJID = [NSString stringWithFormat:@"%@@%@", conversation.with.username, XMPP_HOST];
        if ([withJID isEqual:with]) {
            return conversation;
        }
    }
    return nil;
}

-(void)retrieveMessagesWith:(NSString*)with after:(NSTimeInterval)interval{

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
}

-(void)handleRetrievedMessages:(NSXMLElement*)chatElement after:(NSString*)after{
//    dispatch_async(_background_queue, ^(void){
    UserMessage* messageObject = nil;
    NSDate* date = [self.formatter dateFromString:after];
    NSDate* endDate = [self.formatter dateFromString:[chatElement attributeStringValueForName:@"end"]];
    NSString* with = [XMPPJID jidWithString:[chatElement attributeStringValueForName:@"with"]].bare;
    NSInteger unread = 0;
    for (int i = 0; i < chatElement.children.count; ++i) {
        NSXMLElement* element = chatElement.children[i];
        if ([with isEqual:PUBSUB_SERVICE]){
//            NSXMLElement* bodyElement = [element elementForName:@"body"] ;
//            NSXMLElement *event = [[NSXMLElement alloc] initWithXMLString:[bodyElement stringValue] error:nil];
//            messageMO = [NSEntityDescription insertNewObjectForEntityForName:@"EOMessage" inManagedObjectContext:[self backgroundMessageManagedObjectContext]];
//            messageMO.time = messageDate;
//            messageMO.node = [self nodeNameFrom:event];
//            messageMO.payload = [self payloadFrom:event];
//            _unreadNotifCount++;
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [[NSNotificationCenter defaultCenter] postNotificationName:EONotificationDidSaveNotification
//                                                                    object:messageMO
//                                                                  userInfo:nil];
//            });
        } else {
            NSString* strMessage = [[element elementForName:@"body"] stringValue];
            NSDate* messageDate = nil;
            NSInteger seconds = [[element attributeStringValueForName:@"secs"] integerValue];
            if (i < chatElement.children.count -1 ) {
                messageDate = [date dateByAddingTimeInterval:seconds];
            } else { //last message time must be accurate(in ms), others are in seconds
                messageDate = endDate;
            }
            
            if ([self isValidMessage:with messageDate:messageDate message:strMessage]) {
                messageObject = [NSEntityDescription insertNewObjectForEntityForName:@"UserMessage" inManagedObjectContext:_mainQueueContext];
                if ([element.name isEqual:@"to"] ) {
                    messageObject.incoming = [NSNumber numberWithBool:NO];
                } else if([element.name isEqual:@"from"]){
                    messageObject.incoming = [NSNumber numberWithBool:YES];
                }
                BOOL read = [element attributeBoolValueForName:@"isRead"];
                messageObject.time = messageDate;
                messageObject.message = strMessage;
                messageObject.read = [NSNumber numberWithBool:read];
                User* withUser = [[UserService shared] userWithJID:with];
                messageObject.owner = [UserService shared].loggedInUser;
                NSAssert(withUser, @"with user not found in core data, must be coding error");
                messageObject.with = withUser;
                if (!read && ![self isMessageFromCurrentConversation:messageObject]) {
                    unread++;
                }

            } 
        }
    }
    if (messageObject) {
        NSError* error = nil;
        if(![_mainQueueContext saveToPersistentStore:&error]){
            DDLogError(@"failed to save a retrived message: %@", error);
        }
        if ([with isEqual:PUBSUB_SERVICE]) {
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [[NSNotificationCenter defaultCenter] postNotificationName:EOUnreadNotificationCount
//                                                                    object:[NSNumber numberWithInteger:_unreadNotifCount]
//                                                                  userInfo:nil];
//            });
        } else {
            [[MessageService service] updateConversation:messageObject unreadCount:unread];
//            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:MessageDidSaveNotification
                                                                    object:messageObject
                                                                  userInfo:nil];
//            });
        }
        
    }
    NSInteger more = [[chatElement attributeStringValueForName:@"more"] integerValue];
    if (more > 0) {
        DDLogInfo(@"retrieving more messages after %@", endDate);
        [self retrieveMessagesWith:with after:[endDate timeIntervalSince1970]];
    }
//    [NSThread sleepForTimeInterval:0.1];//slow down the background saving as it might block GUIs
    
//    });
}

-(BOOL)isMessageFromCurrentConversation:(UserMessage*)message{
    return NO; //TODO
}
//valid messages should not older than the local ones, nor should them be duplicated
-(BOOL)isValidMessage:(NSString*)with messageDate:(NSDate*)messageDate message:(NSString*)strMessage{
    if ([with isEqual:PUBSUB_SERVICE]) {
        return NO;//!_latestNotificationDate || [messageDate compare:_latestNotificationDate] > 0;
    } else {
        Conversation* conversation = [self localConversationWith:with];
        if (conversation){
            NSDate* localConversationTime = conversation.time;
            NSTimeInterval delta = [messageDate timeIntervalSinceDate:localConversationTime];
            if ( delta < 0 || [strMessage isEqual:conversation.message]) {
                DDLogWarn(@"ignoring message(%@ - at:%@) that is either too old or has same time(%@) and same content with the latest one", strMessage, messageDate, conversation.time);
                return NO;
            }
        }
    }
    return YES;
}
@end
