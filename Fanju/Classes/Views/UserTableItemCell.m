//
//  UserTableItemCell.m
//  EasyOrder
//
//  Created by igneus on 3/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UserTableItemCell.h"
#import "UserTableItem.h"
#import "UserProfile.h"
#import "NetworkHandler.h"
#import "Const.h"
#import "SVProgressHUD.h"
#import "AvatarFactory.h"
#import "DistanceUtil.h"
#import "DateUtil.h"
#import "Authentication.h"
#import "NewUserDetailsViewController.h"


#define INFO_FRAME_X 92
#define CELL_HEIGHT 88
#define GENDER_Y 36
#define MOTTO_Y 61
#define AVATAR_SIDE_LENGTH 75
#define SHARED_INTERESTS_X 157

@interface UserTableItemCell () {
	UILabel *_username;
    UIButton *_gender;
    UILabel *_distance;
    UILabel *_motto;
    UIImage *_maleImg;
    UIImage *_femaleImg;
    User* _currentUser;
    User* _user;
    
}
@end

@implementation UserTableItemCell

- (id)initWithStyle:(UITableViewCellStyle)style
    reuseIdentifier:(NSString*)identifier {
    
	if (self = [super initWithStyle:UITableViewCellStyleValue2
                    reuseIdentifier:identifier]) {
        _currentUser = [UserService service].loggedInUser;
        
        UIView *infoView = [[UIView alloc] initWithFrame:CGRectMake(INFO_FRAME_X, 0, 320 - INFO_FRAME_X, CELL_HEIGHT)];
        [self.contentView addSubview:infoView];
        
        _username = [[UILabel alloc] initWithFrame:CGRectMake(0, 11, 200, 20)];
        [_username setBackgroundColor:[UIColor clearColor]];
        _username.font = [UIFont boldSystemFontOfSize:16];
        [infoView addSubview:_username];
        
        UIImage* sharedInterestsBg = [UIImage imageNamed:@"shared_interests_bg"];
        _numberOfSameTagsButton = [[UIButton alloc] initWithFrame:CGRectMake(SHARED_INTERESTS_X, 12, sharedInterestsBg.size.width, sharedInterestsBg.size.height)];
        _numberOfSameTagsButton.userInteractionEnabled = NO;
        [_numberOfSameTagsButton setBackgroundImage:sharedInterestsBg forState:UIControlStateNormal];
        _numberOfSameTagsButton.titleLabel.font = [UIFont systemFontOfSize:10];
        _numberOfSameTagsButton.titleLabel.textColor = [UIColor whiteColor];
        [infoView addSubview:_numberOfSameTagsButton];
        
        _maleImg = [UIImage imageNamed:@"male"];
        _femaleImg = [UIImage imageNamed:@"female"];
        _gender = [[UIButton alloc] initWithFrame:CGRectMake(0, GENDER_Y, _maleImg.size.width, _maleImg.size.height)];
        _gender.userInteractionEnabled = NO;
        [_gender setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _gender.titleLabel.font = [UIFont systemFontOfSize:8];
        [infoView addSubview:_gender];
        
        CGFloat x = _maleImg.size.width + 5;
        _distance = [[UILabel alloc] initWithFrame:CGRectMake(x, GENDER_Y - 2, 150, 12)]; //2 pixes up to align top with gender icon
        _distance.textAlignment = UITextAlignmentRight;
        _distance.textColor = RGBCOLOR(130, 130, 130);
        _distance.backgroundColor = [UIColor clearColor];
        _distance.font = [UIFont systemFontOfSize:12];
        [infoView addSubview:_distance];
        
        
        _motto = [[UILabel alloc] initWithFrame:CGRectMake(0, MOTTO_Y, 320 - INFO_FRAME_X - 5, 20)];
        _motto.backgroundColor = [UIColor clearColor];
        _motto.font = [UIFont systemFontOfSize:14];
        _motto.textColor = RGBCOLOR(130, 130, 130);
        [infoView addSubview:_motto];
        
        _avatar = [AvatarFactory defaultAvatarWithFrame:CGRectMake(6, 6, AVATAR_SIDE_LENGTH, AVATAR_SIDE_LENGTH)];
        [self.contentView addSubview:_avatar];
        
        UIImage* separatorImg = [UIImage imageNamed:@"separator"];
        UIImageView* separatorView = [[UIImageView alloc] initWithFrame:CGRectMake(0, CELL_HEIGHT - separatorImg.size.height, separatorImg.size.width, separatorImg.size.height)];
        separatorView.image = separatorImg;
        [self.contentView addSubview:separatorView];
	}
    
	return self;
}

#pragma mark -
#pragma mark UIView

- (void)layoutSubviews {
	[super layoutSubviews];
	// Set the size, font, foreground color, background color, ...
    self.backgroundColor = [UIColor clearColor];
}

-(void)prepareForReuse{
    [super prepareForReuse];
    _avatar.image = nil;
}

#pragma mark -
#pragma mark TTTableViewCell
- (void)setObject:(id)object {
	if (_user != object) {
		[super setObject:object];
        _user = object;
		// Set the data in various UI elements
		[_username setText:_user.name];
        
        [_avatar setPathToNetworkImage:[URLService absoluteURL:_user.avatar] forDisplaySize:CGSizeMake(AVATAR_SIDE_LENGTH, AVATAR_SIDE_LENGTH)];
        _avatar.userInteractionEnabled = NO;
        
        NSMutableSet *myTagSet = [_currentUser.tags mutableCopy];;
        NSMutableSet *otherTagSet = [_user.tags mutableCopy];
        [myTagSet intersectSet:otherTagSet];
        
        [_numberOfSameTagsButton setTitle:[NSString stringWithFormat:@"%d个共同爱好", myTagSet.count] forState:UIControlStateNormal];
        NSInteger age = [DateUtil ageFromBirthday:_user.birthday];
        [_gender setTitle:[NSString stringWithFormat:@"%d", age] forState:UIControlStateNormal];
        NSInteger offset = age > 9 ? 9 : 7;
        _gender.contentEdgeInsets = UIEdgeInsetsMake(0, offset, 0, 0);
        if ([_user.gender integerValue] == 0) {
            [_gender setBackgroundImage:_maleImg forState:UIControlStateNormal];
        } else {
            [_gender setBackgroundImage:_femaleImg forState:UIControlStateNormal];
        } 
        
        NSString* updated = @"很久以前";
        if (_user.locationUpdatedAt) {
            NSTimeInterval interval = [_user.locationUpdatedAt timeIntervalSinceNow] > 0 ? 0 : -[_user.locationUpdatedAt timeIntervalSinceNow];
            updated = [DateUtil humanReadableIntervals: interval];
        }
        _distance.text = [NSString stringWithFormat:@"%@ | %@", [DistanceUtil distanceFrom:_user], updated];
        [_distance sizeToFit];
        _motto.text = _user.motto;
	}
}
@end