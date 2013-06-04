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
    UILabel* _nextMealLabel;
    UITextField* _nextMealText;
    UIImageView* _gender;
    UILabel* _ageLabel;
    UILabel* _distanceLabel;
    UILabel* _updatedLabel;
    UILabel* _mottoLabel;
    UIImageView* _locationIconView ;
    UIImageView* _separatorView;
}
@end
@implementation UserDetailsCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        UIImage* bg = [UIImage imageNamed:@"restaurant_sample.jpg"];
        _backgroundImageView = [[NINetworkImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 149)];
        _backgroundImageView.clipsToBounds = YES;
        _backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
        _backgroundImageView.image = bg;


        [self.contentView addSubview:_backgroundImageView];
        
        UIImage* maskBg = [UIImage imageNamed:@"u_detail_mask"];
        _nextMealView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 109, maskBg.size.width, maskBg.size.height)];
        _nextMealView.userInteractionEnabled = YES;
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
        
        UIImage* nextMealArrowImg = [UIImage imageNamed:@"next_meal_arrow"];;
        _nextMealButton = [[UIButton alloc] initWithFrame: CGRectMake(320 - nextMealArrowImg.size.width - 10, (_nextMealView.frame.size.height - nextMealArrowImg.size.height) /2 , nextMealArrowImg.size.width, nextMealArrowImg.size.height)];
        [_nextMealButton setBackgroundImage:nextMealArrowImg forState:UIControlStateNormal];
        
        
        [_nextMealView addSubview:_nextMealLabel];
        [_nextMealView addSubview:_nextMealText];
        [_nextMealView addSubview:_nextMealButton];
        
        UIImage* avatarBgImg = [UIImage imageNamed:@"avatar_bg_big"];
        UIImageView* avatarView = [[UIImageView alloc] initWithFrame:CGRectMake(3, 106, avatarBgImg.size.width, avatarBgImg.size.height)];
        avatarView.contentMode = UIViewContentModeScaleAspectFill;
        avatarView.image = avatarBgImg;
        
        _avatar = [[NINetworkImageView alloc] initWithFrame:CGRectMake(4, 4, 62, 62)];

        [avatarView addSubview:_avatar];
        [self.contentView addSubview:avatarView];
        
        _gender = [[UIImageView alloc] initWithFrame:CGRectMake(81, 156, 45, 17)];        
        _ageLabel = [[UILabel alloc] initWithFrame:CGRectMake(22, 2, 30, 30)];
        _ageLabel.backgroundColor = [UIColor clearColor];
        _ageLabel.font = [UIFont systemFontOfSize:12];
        _ageLabel.textColor = [UIColor whiteColor];
        _ageLabel.layer.shadowColor = RGBACOLOR(0, 0, 0, 0.2).CGColor;
        _ageLabel.layer.shadowOffset = CGSizeMake(0, -1);
        [_gender addSubview:_ageLabel];
        [self.contentView addSubview:_gender];
        
        UIImage* locIcon = [UIImage imageNamed:@"order_address"];
        _locationIconView = [[UIImageView alloc] initWithFrame:CGRectMake(200, 157, locIcon.size.width, locIcon.size.height)];
        _locationIconView.image = locIcon;
        [self.contentView addSubview:_locationIconView];

        _distanceLabel = [[UILabel alloc] initWithFrame:CGRectMake(213, 159, 60, 12)];
        _distanceLabel.font = [UIFont systemFontOfSize:12];
        _distanceLabel.textColor = RGBCOLOR(150, 150, 150);
        _distanceLabel.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:_distanceLabel];

        _updatedLabel = [[UILabel alloc] initWithFrame:CGRectMake(267, 159, 60, 12)];
        _updatedLabel.font = [UIFont systemFontOfSize:12];
        _updatedLabel.textColor = RGBCOLOR(150, 150, 150);
        _updatedLabel.backgroundColor = [UIColor clearColor];

        [self.contentView addSubview:_updatedLabel];
        
        _mottoLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 193, 295, 0)];
        _mottoLabel.lineBreakMode = UILineBreakModeWordWrap;
        _mottoLabel.font = [UIFont systemFontOfSize:12];
        _mottoLabel.textColor = RGBCOLOR(80, 80, 80);
        _mottoLabel.backgroundColor = [UIColor clearColor];
        _mottoLabel.numberOfLines = 0;
        [self.contentView addSubview:_mottoLabel];
        
        CGFloat y = _mottoLabel.frame.origin.y + _mottoLabel.frame.size.height + 30;
        UIImage* separatorImg = [UIImage imageNamed:@"sep_details"];
        _separatorView = [[UIImageView alloc] initWithFrame:CGRectMake(0, y, separatorImg.size.width, separatorImg.size.height)];
        _separatorView.image = separatorImg;
        [self.contentView addSubview:_separatorView];
        
        _cellHeight = _separatorView.frame.origin.y + _separatorView.frame.size.height;
    }
    return self;
}

-(void)setUser:(User *)user{
    _user = user;
    if (_user.backgroundImage) {
        [_backgroundImageView setPathToNetworkImage:[URLService absoluteURL:_user.backgroundImage] forDisplaySize:CGSizeMake(320, 320) contentMode:UIViewContentModeScaleAspectFill];
    }
    [_avatar setPathToNetworkImage:[URLService absoluteURL:_user.avatar] forDisplaySize:CGSizeMake(62, 62)];
    UIImage* male = [UIImage imageNamed:@"male_details"];
    UIImage* female = [UIImage imageNamed:@"female_details"];
    if ([_user.gender integerValue] == 0) {
        _gender.image = male;
    } else {
        _gender.image = female;
    }
    _ageLabel.text = [NSString stringWithFormat:@"%d", [DateUtil ageFromBirthday:_user.birthday]];
    [_ageLabel sizeToFit];
    NSString* updated  = nil;
    if (_user.locationUpdatedAt) {
        NSTimeInterval interval = [_user.locationUpdatedAt timeIntervalSinceNow] > 0 ? 0 : -[_user.locationUpdatedAt timeIntervalSinceNow];
        updated = [DateUtil humanReadableIntervals: interval];
    }
    if ([[UserService service].loggedInUser isEqual:_user]) {
        _updatedLabel.hidden = YES;
        _distanceLabel.hidden = YES;
        _locationIconView.hidden = YES;
    } else {
        _updatedLabel.text =  updated;
        _distanceLabel.text =  [DistanceUtil distanceFrom:_user];
    }
    _mottoLabel.text = _user.motto;
    _mottoLabel.frame = CGRectMake(15, 193, 295, 0);
    [_mottoLabel sizeToFit];
    CGFloat y = _mottoLabel.frame.origin.y + _mottoLabel.frame.size.height + 10;
    _separatorView.frame = CGRectMake(0, y, _separatorView.frame.size.width, _separatorView.frame.size.height);
    _cellHeight = _separatorView.frame.origin.y + _separatorView.frame.size.height;
    [self requestNextMeal];
}

-(void) requestNextMeal{
    RKObjectManager* manager = [RKObjectManager sharedManager];
    NSString* path = [NSString stringWithFormat:@"user/%@/meal/", _user.uID];
    [manager getObjectsAtPath:path parameters:nil success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        NSArray* meals = mappingResult.array;
        if (meals.count > 0) {
            Meal* meal = meals[0];
            if (![meal.mID isEqual:_meal.mID]) {
                [UIView animateWithDuration:0.9 animations:^{
                    _nextMealText.text = meal.topic;
                    _nextMealView.alpha = 1;
                }];
            }
            _meal = meal;
        } else {
            _nextMealView.alpha = 0;
            _nextMealText.text = @"最近没有饭局";
        }
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        DDLogError(@"failed to fetch meals for user %@", _user.uID);
    }];
}

-(void)temp:(id)sender{
    DDLogInfo(@"next meal clicked: %@", _meal);
}

@end
