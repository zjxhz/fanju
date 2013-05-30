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
#import "NotificationService.h"
#import "DateUtil.h"

NSString * const LAST_SUCCESSFUL_RETRIEVE_DATE = @"LAST_SUCCESSFUL_RETRIEVE_DATE";
#define MAX_RETRIEVE 20

@implementation ArchivedMessageService{
    NSDate* _lastSuccessfulRetrieveDate;
    NSMutableArray* _unhanldedConversations;
    NSDateFormatter* _formatter;
    XMPPStream* _xmppStream;
    NSManagedObjectContext* _mainQueueContext;
    User* _currentContact;
}
+(ArchivedMessageService*)service{
    static dispatch_once_t onceToken;
    static ArchivedMessageService* instance = nil;
    dispatch_once(&onceToken,^{
        instance = [[ArchivedMessageService alloc] init];
    });
    return instance;
}

-(id)init{
    if (self = [super init]) {
        RKManagedObjectStore* store = [RKObjectManager sharedManager].managedObjectStore;
        _mainQueueContext = store.mainQueueManagedObjectContext;
        _unhanldedConversations = [NSMutableArray array];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(currentConversationChanged:)
                                                     name:CurrentConversation
                                                   object:nil];
    }
    return self;
}

-(void)setup{
    _xmppStream = [XMPPHandler sharedInstance].xmppStream;
    [_xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
    _lastSuccessfulRetrieveDate = [self lastSuccessfulRetrieveDate];
    DDLogInfo(@"init lastSuccessfulRetrieveDate value: %@", _lastSuccessfulRetrieveDate);
}

-(void)tearDown{
    [_xmppStream removeDelegate:self];
    _unhanldedConversations = [NSMutableArray array];
    _lastSuccessfulRetrieveDate = nil;
}

-(void)retrieveConversations{
    _retrievingConversations = YES; //TODO
    [self retrieveConversationsStartFrom:_lastSuccessfulRetrieveDate after:-1];
}

-(void)retrieveConversationsStartFrom:(NSDate*)date after:(NSInteger)index{
    NSXMLElement *list = [NSXMLElement elementWithName:@"list" xmlns:@"urn:xmpp:archive"];
    if (date) {
        NSString* strDate = [self.formatter stringFromDate:date];
        [list addAttributeWithName:@"start" stringValue:strDate];
    } else { //if date is not given, retrieve unread only
        [list addAttributeWithName:@"read" stringValue:@"0"];
    }

	
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
    
    _lastSuccessfulRetrieveDate = [[NSUserDefaults standardUserDefaults] valueForKey:[self lastRetriveDateKey]];
    if(!_lastSuccessfulRetrieveDate){
        NSDate* latestMessageDate = [self latestMessageDate];
        NSDate* latestNotificationDate = [[NotificationService service] latestNotificationDate];
        
        if (!latestMessageDate) {
            _lastSuccessfulRetrieveDate = [latestNotificationDate copy];
        } else if(!latestNotificationDate){
            _lastSuccessfulRetrieveDate = [latestMessageDate copy];
        } else { //both are not nil
            if ([latestMessageDate compare:latestNotificationDate] > 0) {
                _lastSuccessfulRetrieveDate = [latestMessageDate copy];
            } else {
                _lastSuccessfulRetrieveDate = [latestNotificationDate copy];
            }
        }
    }

//    if(!_lastSuccessfulRetrieveDate){
//        _lastSuccessfulRetrieveDate = [self yesterday];
//    }

    return _lastSuccessfulRetrieveDate;
}

-(NSString*)lastRetriveDateKey{
    return [NSString stringWithFormat:@"%@_%@", [UserService service].loggedInUser, LAST_SUCCESSFUL_RETRIEVE_DATE];
}

-(void)setLastSuccessfulRetrieveDate:(NSDate*)date{
    DDLogInfo(@"Updating last successful retriving date to: %@", date);
    _lastSuccessfulRetrieveDate = [date copy];
    [[NSUserDefaults standardUserDefaults] setObject:_lastSuccessfulRetrieveDate forKey:[self lastRetriveDateKey]];
    [[NSUserDefaults standardUserDefaults] synchronize];    
}

//used when if no local conversation found, currently it's 2 weeks
-(NSDate*)maximalRetriveDate{
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
                    if ([with isEqual:XMPP_HOST]) {
                        DDLogInfo(@"ignoring the system notification from %@", with);
                        continue;
                    }
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
        NSDate* afterDate = [self latestConversationDateWith:unhandledConversation];
        
        void (^block)(void) = ^(void){
            DDLogInfo(@"retriving messages with %@ after: %@", unhandledConversation, afterDate);
            if (afterDate) {
                [self retrieveMessagesWith:unhandledConversation after:[afterDate timeIntervalSince1970]];
            } else {
                [self retrieveMessagesWith:unhandledConversation after:-1];
            }
        };
        if ([unhandledConversation isEqual:PUBSUB_SERVICE]) {
            block();
        } else {
            User* user = [[UserService service] userWithJID:unhandledConversation];
            if (!user) {
                [[UserService service] getOrFetchUserWithJID:unhandledConversation success:^(User *user) {
                    block();
                } failure:^{
                    DDLogError(@"failed to fetch user with jid: %@, some archived message may be missing", unhandledConversation);
                }];
            } else {
                block();
            }
        }
    }
}

-(NSDate*)latestConversationDateWith:(NSString*)with{
    NSDate* afterDate = nil;
    if ([with isEqual:PUBSUB_SERVICE]) {
        afterDate = [NotificationService service].latestNotificationDate;
        if (!afterDate) {
            DDLogInfo(@"no local notification found");
//            afterDate = [self maximalRetriveDate];
        }
    } else {
        Conversation* localConversation = [self localConversationWith:with];
        
        if (!localConversation) {
            DDLogInfo(@"Messages from new contact %@",
                      with);
//            afterDate = [self maximalRetriveDate];
        } else {
            afterDate = localConversation.time;
        }
    }
    return afterDate;
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
    NSXMLElement *retrieve = [NSXMLElement elementWithName:@"retrieve" xmlns:@"urn:xmpp:archive"];
	[retrieve addAttributeWithName:@"with" stringValue:with];
    NSXMLElement *set = [NSXMLElement elementWithName:@"set" xmlns:@"http://jabber.org/protocol/rsm"];
    NSXMLElement *max = [NSXMLElement elementWithName:@"max"];
    [max setStringValue:[NSString stringWithFormat:@"%d", MAX_RETRIEVE]];

    if (interval == -1) {//no local conversation or notifications found, do not use interval but "read"
        [retrieve addAttributeWithName:@"read" stringValue:@"0"];
    } else {
        NSXMLElement* afterElement = [NSXMLElement elementWithName:@"after"];
        double intervalInMilliSeconds = interval * 1000;
        [afterElement setStringValue:[NSString stringWithFormat:@"%.0f", intervalInMilliSeconds]];
        [set addChild:afterElement];
    }
    [set addChild:max];
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
    User* owner = [UserService service].loggedInUser;
    User* withUser = nil;
    Conversation* conversation = nil;
    if (![with isEqual:PUBSUB_SERVICE]) {
        withUser = [[UserService service] userWithJID:with];
        conversation = [[MessageService service] getOrCreateConversation:owner with:withUser];
        NSAssert(withUser, @"with user not found in core data, must be coding error");
    }

    NSInteger unread = 0;
    NSDate* messageDate = nil;
    NSArray* fromToElements = [self fromToElementsFrom:chatElement];
    for (int i = 0; i < fromToElements.count; ++i) {
        NSXMLElement* element = fromToElements[i];
        NSInteger seconds = [[element attributeStringValueForName:@"secs"] integerValue];
        if (i < fromToElements.count -1 ) {
            messageDate = [date dateByAddingTimeInterval:seconds];
        } else { //last message time must be accurate(in ms), others are in seconds
            messageDate = endDate;
        }
        BOOL read = [element attributeBoolValueForName:@"isRead"];
        if ([with isEqual:PUBSUB_SERVICE]){
            NSXMLElement* bodyElement = [element elementForName:@"body"] ;
            NSXMLElement *event = [[NSXMLElement alloc] initWithXMLString:[bodyElement stringValue] error:nil];
//            NSString* pubid = [element attributeStringValueForName:@""] TODO add pubid
            [[NotificationService service] handleArchivedNotificatoin:event atTime:messageDate read:read];
        } else {
            NSString* strMessage = [[element elementForName:@"body"] stringValue];
            if ([self isValidMessage:with messageDate:messageDate message:strMessage]) {
                DDLogVerbose(@"inserting message: %@ with %@ at %@", strMessage, with, messageDate);
                messageObject = [NSEntityDescription insertNewObjectForEntityForName:@"UserMessage" inManagedObjectContext:_mainQueueContext];
                if ([element.name isEqual:@"to"] ) {
                    messageObject.incoming = [NSNumber numberWithBool:NO];
                } else if([element.name isEqual:@"from"]){
                    messageObject.incoming = [NSNumber numberWithBool:YES];
                }

                messageObject.time = messageDate;
                messageObject.message = strMessage;
                messageObject.read = [NSNumber numberWithBool:read];
                messageObject.conversation = conversation;
                if (!read && ![self isMessageFromCurrentConversation:messageObject] && [messageObject.incoming boolValue]) {
                    unread++;
                }

            } 
        }
    }
    if (messageObject) {
        if (![with isEqual:PUBSUB_SERVICE])  {
            [[MessageService service] updateConversation:conversation withMessage:messageObject unreadCount:unread];
            NSError* error = nil;
            if(![_mainQueueContext saveToPersistentStore:&error]){
                DDLogError(@"failed to save retrived messages: %@", error);
            } else {
                DDLogInfo(@"saved archived messages with conversation: %@", conversation);
            }
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

-(NSArray*)fromToElementsFrom:(NSXMLElement*)chatElement{
    NSMutableArray* fromToElements = [chatElement.children mutableCopy];
    NSXMLElement* lastElement = [chatElement.children lastObject];
    if ([lastElement.name isEqual:@"set"]) {
        [fromToElements removeLastObject];
        DDLogVerbose(@"ignoring the set element in chat element as it's not used in app");
    }
    return fromToElements;
}
-(BOOL)isMessageFromCurrentConversation:(UserMessage*)message{
    return [message.conversation.with isEqual:_currentContact];
}

-(void)currentConversationChanged:(NSNotification*)notif{
    _currentContact = notif.object;
}

//valid messages should not older than the local ones, nor should them be duplicated
-(BOOL)isValidMessage:(NSString*)with messageDate:(NSDate*)messageDate message:(NSString*)strMessage{
    if ([with isEqual:PUBSUB_SERVICE]) {
        return NO;//!_latestNotificationDate || [messageDate compare:_latestNotificationDate] > 0;
    } else {
        Conversation* conversation = [self localConversationWith:with];
        if (conversation && conversation.time){
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
