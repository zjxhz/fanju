//
//  CommentTableItemCell.m
//  EasyOrder
//
//  Created by 浣泽 徐 on 7/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CommentTableItemCell.h"
#import "SpeechBubble.h"
#import "AvatarFactory.h"
#import "CommentTableItem.h"
#import "UserProfile.h"

#define H_GAP 5
#define V_GAP 10
#define USER_IMAGE_SIDE_LENGTH 50
#define COMMENT_WIDTH (320-USER_IMAGE_SIDE_LENGTH - H_GAP*3)

@interface CommentTableItemCell () {
    UserImageView *_user;
	SpeechBubble *_comment;
}
@end

@implementation CommentTableItemCell
+ (CGFloat)tableView:(UITableView*)tableView rowHeightForObject:(id)item {  
    SpeechBubble *comment = [CommentTableItemCell speechBubbleFromItem:item];
    CGFloat commentHeight = comment.frame.size.height + V_GAP*2;
    CGFloat avatarHeight = USER_IMAGE_SIDE_LENGTH + 2* V_GAP;
    return commentHeight > avatarHeight ? commentHeight : avatarHeight;
}

- (id)initWithStyle:(UITableViewCellStyle)style
    reuseIdentifier:(NSString*)identifier {
    
	if (self = [super initWithStyle:UITableViewCellStyleValue2
                    reuseIdentifier:identifier]) {
		_item = nil;
        _user = [AvatarFactory defaultAvatarWithFrame: CGRectMake(H_GAP, V_GAP, USER_IMAGE_SIDE_LENGTH, USER_IMAGE_SIDE_LENGTH)];
//        _comment = [[SpeechBubble alloc] init];
        [self.contentView addSubview:_user];
//        [self.contentView addSubview:_comment];
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

        CommentTableItem *item = object;
        UserProfile *fromUser = item.user;
        [_user setPathToNetworkImage:[fromUser smallAvatarFullUrl] forDisplaySize:CGSizeMake(50, 50)];
        if (_comment) {
            [_comment removeFromSuperview];
        }
        _comment = [CommentTableItemCell speechBubbleFromItem:item];
        [self.contentView addSubview:_comment];
    }
}

+ (SpeechBubble*) speechBubbleFromItem:(CommentTableItem*)item{
    return [[SpeechBubble alloc] initWithText:item.comment font:[UIFont systemFontOfSize:12] origin:CGPointMake(H_GAP*2 + USER_IMAGE_SIDE_LENGTH, V_GAP) pointLocation:40 width:COMMENT_WIDTH];
}

@end
