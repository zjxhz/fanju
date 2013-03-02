//
//  RecentContactTableItem.h
//  EasyOrder
//
//  Created by 徐 浣泽 on 11/4/12.
//
//

#import <Three20UI/Three20UI.h>
#import "UserProfile.h"
#import "EOMessage.h"

@interface UserMessageTableItem  : TTTableImageItem
@property (nonatomic, strong) UserProfile *fromUser;
@property (nonatomic, strong) UserProfile *toUser;

//@property (nonatomic, copy) NSString* sender;
@property (nonatomic, readonly) UserProfile *otherUser; //the user is not myself
@property (nonatomic, copy) NSString* message;
@property (nonatomic, copy) NSDate* time;
@property (nonatomic) NSInteger mID;

+ (id)itemFromUser:(UserProfile*)fromUser toUser:(UserProfile*)toUser withMessage:(NSString*)message at:(NSDate*)time;
- (id) initWithData:(NSDictionary*)data;
@end
