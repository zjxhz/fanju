//
//  MealCell.m
//  Fanju
//
//  Created by Xu Huanze on 4/10/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import "MealCell.h"
#import "Meal.h"
#import "MealTableItem.h"
#import "AvatarFactory.h"
#import "Restaurant.h"
#import "MealService.h"
#import "URLService.h"
#import "Order.h"
#import "GuestUser.h"
@implementation MealCell{
    Meal* _meal;
    NSMutableArray* _participants;
}

+ (CGFloat)tableView:(UITableView*)tableView rowHeightForObject:(id)item {
	return 329;
}

- (id)initWithStyle:(UITableViewCellStyle)style
    reuseIdentifier:(NSString*)identifier {
	if (self = [super initWithStyle:style
                    reuseIdentifier:identifier]) {
        UIViewController* temp = [[UIViewController alloc] initWithNibName:@"MealCell" bundle:nil];
         self = (MealCell*)temp.view;
        _participants = [NSMutableArray array];
        _mealView.delegate = self;
        _activityIndicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        _activityIndicator.center = _mealView.center;
        [_activityIndicator hidesWhenStopped];
        [_mealView addSubview: _activityIndicator];
	}
    
	return self;
}

- (id)object {
    return _meal;
}

-(void)prepareForReuse{
    [super prepareForReuse];
    _costLabel.text = nil;
    _addressLabel.text = nil;
    _mealView.image = nil;
    _topicLabel.text = nil;
    _timeLabel.text = nil;
    [_participants makeObjectsPerformSelector:@selector(removeFromSuperview)];
}

- (void)setObject:(id)object {
    [super setObject:object];
    _meal = object;
    if (!_meal) {
        return;
    }
    _costLabel.text = [NSString stringWithFormat:NSLocalizedString(@"AverageCost", nil),
                       [_meal.price floatValue], ([_meal.maxPersons integerValue] - [_meal.actualPersons integerValue])];
    _addressLabel.text = _meal.restaurant.name;
    _topicLabel.text = _meal.topic;
    _timeLabel.text = [MealService dateTextOfMeal:_meal];
    NSInteger i = 0;
    [_mealView setPathToNetworkImage:[URLService  absoluteURL:_meal.photoURL] ];
    for (id obj in [MealService participantsOfMeal:_meal]) {
        if (i >= 5) {
            break;
        }
        UIImageView* avatar = nil;
        if ([obj isKindOfClass:[GuestUser class]]) {
            avatar = [AvatarFactory guestAvatarWithBg:NO];
        } else {
            User* user = obj;
            avatar = [AvatarFactory avatarWithBg:user];
        }
         
        avatar.frame = CGRectMake(23 + 55*i, 227, 53, 53);
        [self.contentView addSubview:avatar];
        [_participants addObject:avatar];
        i++;
    }
}

#pragma mark NINetworkImageViewDelegate
- (void)networkImageView:(NINetworkImageView *)imageView didLoadImage:(UIImage *)image{
    [_activityIndicator stopAnimating];
}

- (void)networkImageViewDidStartLoad:(NINetworkImageView *)imageView{
    [_activityIndicator startAnimating];
}
@end
