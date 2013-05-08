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

@interface XMPPChatViewController2  : UIViewController <UIBubbleTableViewDataSource, UITextViewDelegate, UIGestureRecognizerDelegate, UIBubbleTableViewCellAvatarDelegate	>
-(id)initWithUserChatTo:(User*)with;
@property(nonatomic, strong) UIImage* avatarSomeoneElse;
@end
