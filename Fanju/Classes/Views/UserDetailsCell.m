//
//  UserDetailsCell.m
//  Fanju
//
//  Created by Xu Huanze on 3/19/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import "UserDetailsCell.h"
#import "NINetworkImageView.h"
#import "AvatarFactory.h"
#import "NetworkHandler.h"
#import "NSDictionary+ParseHelper.h"
#import "OrderInfo.h"
#import "Authentication.h"
#import "DateUtil.h"
#import "DistanceUtil.h"
#import "URLService.h"

@interface UserDetailsCell(){
    User* _user;
    UIImageView* _nextMealView;
    UILabel* _nextMealLabel;
    UITextField* _nextMealText;
}
@end
@implementation UserDetailsCell

- (id)initWithUser:(User*)user{
    self = [super init];
    if (self) {
        _user = user;
        UIImage* bg = [UIImage imageNamed:@"restaurant_sample.jpg"];
        UIImageView* bgImgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 149)];
        bgImgView.clipsToBounds = YES;
        bgImgView.contentMode = UIViewContentModeScaleAspectFill;
        bgImgView.image = bg;
        [self.contentView addSubview:bgImgView];
        
        UIImage* maskBg = [UIImage imageNamed:@"u_detail_mask"];
        _nextMealView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 109, maskBg.size.width, maskBg.size.height)];
        _nextMealView.image = maskBg;
        _nextMealView.alpha = 0;
        [self.contentView addSubview:_nextMealView];
        
        _nextMealLabel = [[UILabel alloc] initWithFrame:CGRectMake(74, 2, 0, 0)];
        _nextMealLabel.font = [UIFont systemFontOfSize:12];
        _nextMealLabel.textColor = RGBCOLOR(220, 220, 220);
        _nextMealLabel.backgroundColor = [UIColor clearColor];
        _nextMealLabel.layer.shadowColor = RGBACOLOR(0, 0, 0, 0.2).CGColor;
        _nextMealLabel.layer.shadowOffset = CGSizeMake(0, 2);
        _nextMealLabel.text = @"下一个饭局：";
        [_nextMealLabel sizeToFit];
        
        _nextMealText = [[UITextField alloc] initWithFrame:CGRectMake(88, 18, 200, 18)];
        _nextMealText.userInteractionEnabled = NO;
        _nextMealText.font = [UIFont systemFontOfSize:15];
        _nextMealText.adjustsFontSizeToFitWidth = YES;
        _nextMealText.minimumFontSize = 12;
        _nextMealText.textColor = RGBCOLOR(220, 220, 220);
        _nextMealText.backgroundColor = [UIColor clearColor];
        _nextMealText.layer.shadowColor = RGBACOLOR(0, 0, 0, 0.4).CGColor;
        _nextMealText.layer.shadowOffset = CGSizeMake(0, 2);
        _nextMealText.contentVerticalAlignment = UIControlContentVerticalAlignmentBottom;
        
        UIImage* nextMealArrowImg = [UIImage imageNamed:@"next_meal_arrow"];
        UIImageView* arrowView = [[UIImageView alloc] initWithFrame:CGRectMake(320 - nextMealArrowImg.size.width - 10, (_nextMealView.frame.size.height - nextMealArrowImg.size.height) /2 , nextMealArrowImg.size.width, nextMealArrowImg.size.height)];
        arrowView.image = nextMealArrowImg;
        
        
        [_nextMealView addSubview:_nextMealLabel];
        [_nextMealView addSubview:_nextMealText];
        [_nextMealView addSubview:arrowView];
        
        UIImage* avatarBgImg = [UIImage imageNamed:@"avatar_bg_big"];
        UIImageView* avatarView = [[UIImageView alloc] initWithFrame:CGRectMake(3, 106, avatarBgImg.size.width, avatarBgImg.size.height)];
        avatarView.contentMode = UIViewContentModeScaleAspectFill;
        avatarView.image = avatarBgImg;
        
        _avatar = [[NINetworkImageView alloc] initWithFrame:CGRectMake(4, 4, 62, 62)];
        [_avatar setPathToNetworkImage:[URLService absoluteURL:_user.avatar] forDisplaySize:CGSizeMake(62, 62)];
        [avatarView addSubview:_avatar];
        [self.contentView addSubview:avatarView];
        
        UIImage* male = [UIImage imageNamed:@"male_details"];
        UIImage* female = [UIImage imageNamed:@"female_details"];
        UIImageView* gender = [[UIImageView alloc] initWithFrame:CGRectMake(81, 156, male.size.width, male.size.height)];
        if ([_user.gender integerValue] == 0) {
            gender.image = male;
        } else {
            gender.image = female;
        }
        
        UILabel* age = [[UILabel alloc] initWithFrame:CGRectMake(22, 2, 30, 30)];
        age.backgroundColor = [UIColor clearColor];
        age.font = [UIFont systemFontOfSize:12];
        age.textColor = [UIColor whiteColor];
        age.layer.shadowColor = RGBACOLOR(0, 0, 0, 0.2).CGColor;
        age.layer.shadowOffset = CGSizeMake(0, -1);
        age.text = [NSString stringWithFormat:@"%d", [DateUtil ageFromBirthday:_user.birthday]];
        [age sizeToFit];
        [gender addSubview:age];
        [self.contentView addSubview:gender];
        
        UserProfile* me = [Authentication sharedInstance].currentUser;
        if (![me isEqual:_user]) {
            UIImage* locIcon = [UIImage imageNamed:@"order_address"];
            UIImageView* iconView = [[UIImageView alloc] initWithFrame:CGRectMake(200, 157, locIcon.size.width, locIcon.size.height)];
            iconView.image = locIcon;
            [self.contentView addSubview:iconView];
            
            NSString* updated  = nil;
            if (_user.locationUpdatedAt) {
                NSTimeInterval interval = [_user.locationUpdatedAt timeIntervalSinceNow] > 0 ? 0 : -[_user.locationUpdatedAt timeIntervalSinceNow];
                updated = [DateUtil humanReadableIntervals: interval];
            }
            
            UILabel* distanceLabel = [[UILabel alloc] initWithFrame:CGRectMake(213, 159, 60, 12)];
            distanceLabel.font = [UIFont systemFontOfSize:12];
            distanceLabel.textColor = RGBCOLOR(150, 150, 150);
            distanceLabel.backgroundColor = [UIColor clearColor];
            distanceLabel.text =  [DistanceUtil distanceFrom:_user];
            [self.contentView addSubview:distanceLabel];

            UILabel* updatedLabel = [[UILabel alloc] initWithFrame:CGRectMake(267, 159, 60, 12)];
            updatedLabel.font = [UIFont systemFontOfSize:12];
            updatedLabel.textColor = RGBCOLOR(150, 150, 150);
            updatedLabel.backgroundColor = [UIColor clearColor];
            updatedLabel.text =  updated;
            [self.contentView addSubview:updatedLabel];
        }
        
        UILabel* motto = [[UILabel alloc] initWithFrame:CGRectMake(15, 193, 295, 0)];
        motto.font = [UIFont systemFontOfSize:12];
        motto.textColor = RGBCOLOR(80, 80, 80);
        motto.text = _user.motto;
        motto.backgroundColor = [UIColor clearColor];
        motto.numberOfLines = 0;
        [motto sizeToFit];
        [self.contentView addSubview:motto];
        
        CGFloat y = motto.frame.origin.y + motto.frame.size.height + 10;
        UIImage* separatorImg = [UIImage imageNamed:@"sep_details"];
        UIImageView* separatorView = [[UIImageView alloc] initWithFrame:CGRectMake(0, y, separatorImg.size.width, separatorImg.size.height)];
        separatorView.image = separatorImg;
        [self.contentView addSubview:separatorView];
        
        _cellHeight = separatorView.frame.origin.y + separatorView.frame.size.height;
        [self requestNextMeal];
    }
    return self;
}


-(void) requestNextMeal{
    NSString* url = [NSString stringWithFormat:@"http://%@/api/v1/user/%@/meal/", EOHOST, _user.uID];
    //use a new instance of network handler as there might be simultaneous reqeusts on the user details view 
    [[NetworkHandler getHandler] requestFromURL:url method:GET cachePolicy:TTURLRequestCachePolicyDefault
                                        success:^(id obj) {
                                            NSArray *meals = [obj objectForKeyInObjects];
                                            if (meals && [meals count] > 0) {
                                                MealInfo *meal = [MealInfo mealInfoWithData:[meals objectAtIndex:0]];
                                                [UIView animateWithDuration:0.9 animations:^{
                                                    _nextMealText.text = meal.topic;
                                                    _nextMealView.alpha = 1;
                                                }];
                                                
                                                
//                                                [_nextMealText sizeToFit];
                                            } else {
                                                _nextMealView.alpha = 1;
                                                _nextMealText.text = @"最近没有饭局";
//                                                _nextMealTimeLabel.text = @"";
                                            }
                                        } failure:^{
                                            DDLogError(@"failed to fetch order for %@", _user);
                                            _nextMealText.text = @"获取饭局失败";
                                            _nextMealView.alpha = 1;
//                                            _nextMealTimeLabel.text = @"";
                                        }];
}

@end
