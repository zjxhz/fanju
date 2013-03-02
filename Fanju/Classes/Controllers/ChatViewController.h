//
//  ChatViewController.h
//  EasyOrder
//
//  Created by 徐 浣泽 on 11/6/12.
//
//

#import <Three20UI/Three20UI.h>
#import "UserProfile.h"
#import "UserMessageTableItem.h"

@protocol ChatViewControllerDelegate<NSObject>
@optional
-(void)newMessageAppear:(UserMessageTableItem*)message;
@end


@interface ChatViewController : TTTableViewController<UITableViewDelegate, UITextViewDelegate>
@property(nonatomic, weak) UserProfile* chatWithUser;
@property(nonatomic, weak) id<ChatViewControllerDelegate> delegate;
-(id)initWithStyle:(UITableViewStyle)style userChatTo:(UserProfile*)userChatTo;
@end
