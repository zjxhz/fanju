//
//  UserMessageCell.m
//  EasyOrder
//
//  Created by 徐 浣泽 on 11/6/12.
//
//

#import "UserMessageCell.h"
#import "AvatarFactory.h"
#import "UserMessageTableItem.h"
#import "Authentication.h"

#define H_GAP 5
#define V_GAP 10
#define USER_IMAGE_SIDE_LENGTH 50
#define COMMENT_WIDTH (320-USER_IMAGE_SIDE_LENGTH - H_GAP*3)
@implementation UserMessageCell

+ (CGFloat)tableView:(UITableView*)tableView rowHeightForObject:(id)item {
    SpeechBubble *message = [UserMessageCell speechBubbleFromItem:item];
    CGFloat messageHeight = message.frame.size.height + V_GAP*2;
    CGFloat avatarHeight = USER_IMAGE_SIDE_LENGTH + 2* V_GAP;
    return messageHeight > avatarHeight ? messageHeight : avatarHeight;
}

- (id)initWithStyle:(UITableViewCellStyle)style
    reuseIdentifier:(NSString*)identifier {
    
	if (self = [super initWithStyle:UITableViewCellStyleValue2
                    reuseIdentifier:identifier]) {
		_item = nil;
        _avatar = [AvatarFactory defaultAvatarWithFrame: CGRectZero];
        [self.contentView addSubview:_avatar];
	}
    
	return self;
}


#pragma mark -
#pragma mark UIView

- (void)layoutSubviews {
	[super layoutSubviews];
}


#pragma mark -
#pragma mark TTTableViewCell

- (id)object {
	return _item;
}

- (void)setObject:(id)object {
    if (_item != object) {
        [super setObject:object];
        
        UserMessageTableItem *item = object;
        UserProfile *fromUser = item.fromUser;
        CGRect otherUserFrame = CGRectMake(H_GAP, V_GAP, USER_IMAGE_SIDE_LENGTH, USER_IMAGE_SIDE_LENGTH);
        CGRect myFrame = CGRectMake(320 - H_GAP - USER_IMAGE_SIDE_LENGTH, V_GAP, USER_IMAGE_SIDE_LENGTH, USER_IMAGE_SIDE_LENGTH);
        
        if ([fromUser isEqual:[Authentication sharedInstance].currentUser]) {
            _avatar.frame = myFrame;
        } else {
            _avatar.frame = otherUserFrame;
        }
        
        [_avatar setPathToNetworkImage:[fromUser smallAvatarFullUrl]];
        if (_message) {
            [_message removeFromSuperview];
        }
        _message = [UserMessageCell speechBubbleFromItem:item];
        [self.contentView addSubview:_message];
    }
}

+ (SpeechBubble*) speechBubbleFromItem:(UserMessageTableItem*)item{
    UserProfile *fromUser = item.fromUser;
    if ([fromUser isEqual:[Authentication sharedInstance].currentUser]) {
        return [[SpeechBubble alloc] initWithText:item.message font:[UIFont systemFontOfSize:12] origin:CGPointMake(H_GAP, V_GAP)  pointLocation:224 width:COMMENT_WIDTH];
    } else {
        return [[SpeechBubble alloc] initWithText:item.message font:[UIFont systemFontOfSize:12] origin:CGPointMake(H_GAP*2 + USER_IMAGE_SIDE_LENGTH, V_GAP) pointLocation:40 width:COMMENT_WIDTH];
    }
}


@end
