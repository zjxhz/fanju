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
    UIButton *_sharedInterestsButton;
    UILabel *_distance;
    UILabel *_motto;
    UIImage *_maleImg;
    UIImage *_femaleImg;
    UserProfile* _currentUser;
    
}
@end

@implementation UserTableItemCell

- (id)initWithStyle:(UITableViewCellStyle)style
    reuseIdentifier:(NSString*)identifier {
    
	if (self = [super initWithStyle:UITableViewCellStyleValue2
                    reuseIdentifier:identifier]) {
		_item = nil;
        _currentUser = [Authentication sharedInstance].currentUser;
        
        UIView *infoView = [[UIView alloc] initWithFrame:CGRectMake(INFO_FRAME_X, 0, 320 - INFO_FRAME_X, CELL_HEIGHT)];
        [self.contentView addSubview:infoView];
        
        _username = [[UILabel alloc] initWithFrame:CGRectMake(0, 11, 100, 20)];
        [_username setBackgroundColor:[UIColor clearColor]];
        _username.font = [UIFont boldSystemFontOfSize:16];
        [infoView addSubview:_username];
        
        UIImage* sharedInterestsBg = [UIImage imageNamed:@"shared_interests_bg"];
        _sharedInterestsButton = [[UIButton alloc] initWithFrame:CGRectMake(SHARED_INTERESTS_X, 12, sharedInterestsBg.size.width, sharedInterestsBg.size.height)];
        _sharedInterestsButton.userInteractionEnabled = NO;
        [_sharedInterestsButton setBackgroundImage:sharedInterestsBg forState:UIControlStateNormal];
        _sharedInterestsButton.titleLabel.font = [UIFont systemFontOfSize:10];
        _sharedInterestsButton.titleLabel.textColor = [UIColor whiteColor];
        [infoView addSubview:_sharedInterestsButton];
        
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

- (void)addFollowing {
    [SVProgressHUD setStatus:@"请稍候…"];
    int uid = ((UserTableItem *)_item).profile.uID;
    int myID = [Authentication sharedInstance].currentUser.uID;
    NSArray *params = [NSArray arrayWithObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%d", uid], @"value", @"user_id", @"key", nil]];
    http_method_t method = POST;
    NSString* url = [NSString stringWithFormat:@"%@://%@/api/v1/user/%d/following/", HTTPS, EOHOST, myID];

    [[NetworkHandler getHandler] requestFromURL:url
                                         method:method
                                     parameters:params
                                    cachePolicy:TTURLRequestCachePolicyNone
                                        success:^(id obj) {
                                            if ([[obj objectForKey:@"status"] isEqualToString:@"OK"]) {
                                                [SVProgressHUD dismissWithSuccess:[obj objectForKey:@"info"]];
                                                NSString* followingUserID = [NSString stringWithFormat:@"%d",uid];
                                                [[Authentication sharedInstance].currentUser.followings addObject:followingUserID];
                                                [[Authentication sharedInstance] synchronize];
                                                
                                            } else {
                                                [SVProgressHUD dismissWithError:[obj objectForKey:@"info"]];
                                            }
                                        } failure:^{
                                            [SVProgressHUD dismissWithError:BLAME_NETWORK_ERROR_MESSAGE];
                                        }];
}


#pragma mark -
#pragma mark UIView

- (void)layoutSubviews {
	[super layoutSubviews];
	// Set the size, font, foreground color, background color, ...
    self.backgroundColor = [UIColor clearColor];
}


#pragma mark -
#pragma mark TTTableViewCell

- (id)object {
	return _item;  
}

- (void)setObject:(id)object {
	if (_item != object) {
		[super setObject:object];
        UserTableItem *item = object;
        
		// Set the data in various UI elements
		[_username setText:item.profile.name];
        [_avatar setPathToNetworkImage:[item.profile smallAvatarFullUrl] forDisplaySize:CGSizeMake(AVATAR_SIDE_LENGTH, AVATAR_SIDE_LENGTH)];
        _avatar.userInteractionEnabled = NO;
        
        NSMutableSet *myTagSet = [NSMutableSet setWithArray:_currentUser.tags];
        NSMutableSet *otherTagSet = [NSMutableSet setWithArray:item.profile.tags];
        [myTagSet intersectSet:otherTagSet];
        
        [_sharedInterestsButton setTitle:[NSString stringWithFormat:@"%d个共同爱好", myTagSet.count] forState:UIControlStateNormal];
        [_gender setTitle:[NSString stringWithFormat:@"%d",[item.profile age]] forState:UIControlStateNormal];
        NSInteger offset = [item.profile age] > 9 ? 9 : 7;
        _gender.contentEdgeInsets = UIEdgeInsetsMake(0, offset, 0, 0);
        if (item.profile.gender == 0) {
            [_gender setBackgroundImage:_maleImg forState:UIControlStateNormal];
        } else {
            [_gender setBackgroundImage:_femaleImg forState:UIControlStateNormal];
        } //TODO user with no age and no gender set
        
        NSString* updated = @"未知时间";
        if (item.profile.locationUpdatedTime) {
            NSTimeInterval interval = [item.profile.locationUpdatedTime timeIntervalSinceNow] > 0 ? 0 : -[item.profile.locationUpdatedTime timeIntervalSinceNow];
            updated = [DateUtil humanReadableIntervals: interval];
        }
        _distance.text = [NSString stringWithFormat:@"%@ | %@", [DistanceUtil distanceToMe:item.profile], updated];
        [_distance sizeToFit];
        _motto.text = item.profile.motto;
	}
}
@end