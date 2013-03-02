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

#define LABEL_HEIGHT 18
#define SMALL_FONT_SIZE 12

@interface UserTableItemCell () {
	UILabel *_username;
    UIButton *_gender;
    UILabel *_distance;
    UILabel *_motto;
    
}
@end

@implementation UserTableItemCell

+ (CGFloat)tableView:(UITableView*)tableView rowHeightForObject:(id)item {  
	// Set the height for the particular cell
	return 60.0;
}

- (id)initWithStyle:(UITableViewCellStyle)style
    reuseIdentifier:(NSString*)identifier {
    
	if (self = [super initWithStyle:UITableViewCellStyleValue2
                    reuseIdentifier:identifier]) {
		_item = nil;
        
        UIView *infoView = [[UIView alloc] initWithFrame:CGRectMake(55, 0, 250, 60)];
        [self.contentView addSubview:infoView];
        
        _username = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 20)];
        [_username setBackgroundColor:[UIColor clearColor]];
        _username.font = [UIFont boldSystemFontOfSize:16];
        [infoView addSubview:_username];
              
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
        
        
        _motto = [[UILabel alloc] initWithFrame:CGRectMake(0, 40, 200, LABEL_HEIGHT)];
        _motto.backgroundColor = [UIColor clearColor];
        _motto.font = [UIFont systemFontOfSize:SMALL_FONT_SIZE];
        [infoView addSubview:_motto];
        
        _avatar = [AvatarFactory defaultAvatarWithFrame:CGRectMake(8, 8, 41, 41)];
        [self.contentView addSubview:_avatar];
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
        [_avatar setPathToNetworkImage:[item.profile smallAvatarFullUrl] forDisplaySize:CGSizeMake(50, 50)];
        _avatar.userInteractionEnabled = NO;
        
        [_gender setTitle:[NSString stringWithFormat:@"%d",[item.profile age]] forState:UIControlStateNormal];
        if (item.profile.gender == 0) {
            _gender.backgroundColor = RGBCOLOR(0x60, 0xC0, 0xF0) ;
            [_gender setImage:[UIImage imageNamed:@"male.png"] forState:UIControlStateNormal];
        } else {
            _gender.backgroundColor = RGBCOLOR(0xEE, 0x66, 0xEE);
            [_gender setImage:[UIImage imageNamed:@"female.png"] forState:UIControlStateNormal];
            
        } //TODO user with no age and no gender set
        
        NSString* updated = @"未知时间";
        if (item.profile.locationUpdatedTime) {
            NSTimeInterval interval = [item.profile.locationUpdatedTime timeIntervalSinceNow] > 0 ? 0 : -[item.profile.locationUpdatedTime timeIntervalSinceNow];
            updated = [DateUtil humanReadableIntervals: interval];
        }
        _distance.text = [NSString stringWithFormat:@"%@ | %@", [DistanceUtil distanceToMe:item.profile], updated];
        _motto.text = item.profile.motto;
	}
}
@end