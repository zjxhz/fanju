//
//  UserMessageCell.h
//  EasyOrder
//
//  Created by 徐 浣泽 on 11/6/12.
//
//

#import "Three20/Three20.h"
#import "SpeechBubble.h"
#import "UserImageView.h"

@interface UserMessageCell : TTTableLinkedItemCell{
    UserImageView *_avatar;
	SpeechBubble *_message;
}

@end
