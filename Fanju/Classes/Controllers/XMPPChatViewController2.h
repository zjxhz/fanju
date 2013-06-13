//
//  XMPPChatViewController2.h
//  EasyOrder
//
//  Created by 徐 浣泽 on 12/14/12.
//
//

#import <UIKit/UIKit.h>
#import "UIBubbleTableViewDataSource.h"
#import "UIBubbleTableViewCell.h"
#import "User.h"
#import "Conversation.h"

@interface XMPPChatViewController2  : UIViewController <UIBubbleTableViewDataSource, UITextViewDelegate, UIGestureRecognizerDelegate	>
-(id)initWithConversation:(Conversation*)conversation;
@property(nonatomic, strong) UIImage* avatarSomeoneElse;
@end
