//
//  RecentContactTableItem.m
//  EasyOrder
//
//  Created by 徐 浣泽 on 11/4/12.
//
//

#import "UserMessageTableItem.h"
#import "DateUtil.h"
#import "Authentication.h"

@implementation UserMessageTableItem

- (id) initWithData:(NSDictionary*)data{
    if (self = [super init]) {
        self.fromUser = [UserProfile profileWithData:[data objectForKey:@"from_person"]];
        self.toUser = [UserProfile profileWithData:[data objectForKey:@"to_person"]];
        self.time = [DateUtil dateFromString:[data objectForKey:@"timestamp"]];
        self.message = [data objectForKey:@"message"];
        self.mID = [[data objectForKey:@"id"] intValue];
    }
    return self;
}

+ (id)itemFromUser:(UserProfile*)fromUser toUser:(UserProfile*)toUser withMessage:(NSString*)message at:(NSDate*)time{
    UserMessageTableItem *item = [[self alloc] init];
    item.fromUser = fromUser;
    item.toUser = toUser;
    item.message = message;
    item.time = time;
    return item;
}

-(UserProfile*)otherUser{
    return [[Authentication sharedInstance].currentUser isEqual:self.fromUser] ? self.toUser : self.fromUser;
}

@end
