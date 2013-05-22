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

@implementation MealCell{
    Meal* _mealInfo;
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
	}
    
	return self;
}

- (id)object {
    return _mealInfo;
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
    _mealInfo = object;
    if (!_mealInfo) {
        return;
    }
    _costLabel.text = [NSString stringWithFormat:NSLocalizedString(@"AverageCost", nil),
                       [_mealInfo.price floatValue], ([_mealInfo.maxPersons integerValue] - [_mealInfo.actualPersons integerValue])];
    _addressLabel.text = _mealInfo.restaurant.name;
    _topicLabel.text = _mealInfo.topic;
    _timeLabel.text = [MealService dateTextOfMeal:_mealInfo];
    NSInteger i = 0;
    [_mealView setPathToNetworkImage:[URLService  absoluteURL:_mealInfo.photoURL] ];
    for (User* participant in _mealInfo.participants) {
        if (i >= 5) {
            break;
        }
        UIImageView* avatar = [AvatarFactory avatarWithBg:participant];
        avatar.frame = CGRectMake(23 + 55*i, 227, 53, 53);
        [self.contentView addSubview:avatar];
        [_participants addObject:avatar];
        i++;
    }
}
@end
