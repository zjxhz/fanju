//
//  RecentContactCell.m
//  EasyOrder
//
//  Created by 徐 浣泽 on 11/4/12.
//
//

#import "RecentContactCell.h"
#import "SpeechBubble.h"
#import "UserImageView.h"
#import "AvatarFactory.h"
#import "UserMessageTableItem.h"
#import "Authentication.h"
#import "DateUtil.h"
#import "DistanceUtil.h"

#define H_GAP 3
#define V_GAP 3
#define USER_IMAGE_SIDE_LENGTH 75
#define COMMENT_WIDTH (320-USER_IMAGE_SIDE_LENGTH - H_GAP*4)
#define LABEL_HEIGHT 18
#define SMALL_FONT_SIZE 12

@interface RecentContactCell () {
    UserImageView *_avatar;
	SpeechBubble *_message;
    UILabel *_name;
    UIButton *_gender;
    UILabel *_distance;
}
@end

@implementation RecentContactCell
+ (CGFloat)tableView:(UITableView*)tableView rowHeightForObject:(id)item {
    return 81;
}

- (id)initWithStyle:(UITableViewCellStyle)style
    reuseIdentifier:(NSString*)identifier {
    
	if (self = [super initWithStyle:UITableViewCellStyleValue2
                    reuseIdentifier:identifier]) {
		_item = nil;
        _avatar = [AvatarFactory defaultAvatarWithFrame: CGRectMake(H_GAP, V_GAP, USER_IMAGE_SIDE_LENGTH, USER_IMAGE_SIDE_LENGTH)];
        [self.contentView addSubview:_avatar];
        UIView *infoView = [[UIView alloc] initWithFrame:CGRectMake(USER_IMAGE_SIDE_LENGTH + 2*H_GAP, V_GAP, 320 - (USER_IMAGE_SIDE_LENGTH + 3*H_GAP), USER_IMAGE_SIDE_LENGTH)];
        [self.contentView addSubview:infoView];
        
        _name = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 20)];
        [_name setBackgroundColor:[UIColor clearColor]];
        _name.font = [UIFont boldSystemFontOfSize:16];
        [infoView addSubview:_name];
        
        _gender = [[UIButton alloc] initWithFrame:CGRectMake(0, 25, 30, 15)];
        [_gender setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _gender.titleLabel.font = [UIFont systemFontOfSize:SMALL_FONT_SIZE];
        _gender.layer.cornerRadius = 5;
        _gender.clipsToBounds = YES;
        [_gender setImageEdgeInsets:UIEdgeInsetsMake(0, -5, 0, 0)]; // place the image to the right
        [infoView addSubview:_gender];
        
        _distance = [[UILabel alloc] initWithFrame:CGRectMake(50, 20, 150, LABEL_HEIGHT)];
        _distance.textAlignment = UITextAlignmentRight;
        _distance.backgroundColor = [UIColor clearColor];
        _distance.font = [UIFont systemFontOfSize:SMALL_FONT_SIZE];
        [infoView addSubview:_distance];
        
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
        UserProfile *toUser = item.toUser;
        
        UserProfile* otherUser = [[Authentication sharedInstance].currentUser isEqual:fromUser] ? toUser : fromUser;
        // Set the data in various UI elements
		[_name setText:otherUser.name];
        [_avatar setPathToNetworkImage:[otherUser smallAvatarFullUrl]];
        
        [_gender setTitle:[NSString stringWithFormat:@"%d",[otherUser age]] forState:UIControlStateNormal];
        if (otherUser.gender == 0) {
            _gender.backgroundColor = RGBCOLOR(0x60, 0xC0, 0xF0) ;
            [_gender setImage:[UIImage imageNamed:@"male.png"] forState:UIControlStateNormal];
        } else {
            _gender.backgroundColor = RGBCOLOR(0xEE, 0x66, 0xEE);
            [_gender setImage:[UIImage imageNamed:@"female.png"] forState:UIControlStateNormal];
            
        } //TODO user with no age and no gender set
        
        NSString* updated = @"未知时间";
        if (otherUser.locationUpdatedTime) {
            NSTimeInterval interval = [otherUser.locationUpdatedTime timeIntervalSinceNow] > 0 ? 0 : -[otherUser.locationUpdatedTime timeIntervalSinceNow];
            updated = [DateUtil humanReadableIntervals: interval];
        }
        _distance.text = [NSString stringWithFormat:@"%@ | %@", [DistanceUtil distanceToMe:otherUser], updated];
        
        if (_message) {
            [_message removeFromSuperview];
        }
        _message = [RecentContactCell speechBubbleFromItem:item];
        [self.contentView addSubview:_message];
    }
}

+ (SpeechBubble*) speechBubbleFromItem:(UserMessageTableItem*)item{
    CGFloat pointLocation = [[Authentication sharedInstance].currentUser isEqual:item.fromUser] ? 224 : 40;
    return [[SpeechBubble alloc] initWithText:item.message font:[UIFont systemFontOfSize:12] origin:CGPointMake(H_GAP*2 + USER_IMAGE_SIDE_LENGTH, 45) pointLocation:pointLocation width:COMMENT_WIDTH height:25];
}

@end
