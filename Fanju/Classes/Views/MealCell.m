//
//  MealCell.m
//  Fanju
//
//  Created by Xu Huanze on 4/10/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import "MealCell.h"
#import "MealInfo.h"
#import "MealTableItem.h"
#import "AvatarFactory.h"

@implementation MealCell{
    MealInfo* _mealInfo;
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
    [_participants makeObjectsPerformSelector:@selector(removeFromSuperview)];
}

- (void)setObject:(id)object {
    [super setObject:object];
    MealTableItem* item = object;
    _mealInfo = item.mealInfo;
    _costLabel.text = [NSString stringWithFormat:NSLocalizedString(@"AverageCost", nil),
                       _mealInfo.price, (_mealInfo.maxPersons - _mealInfo.actualPersons)];
    _addressLabel.text = _mealInfo.restaurant.name;
    _topicLabel.text = _mealInfo.topic;
    _timeLabel.text = _mealInfo.timeText;
    NSInteger i = 0;
    [_mealView setPathToNetworkImage:_mealInfo.photoFullUrl];
    for (UserProfile* participant in _mealInfo.participants) {
        if (i >= 5) {
            break;
        }
        UIImageView* avatar = [AvatarFactory avatarWithBg:participant];
        avatar.frame = CGRectMake(24 + 55*i, 227, 53, 53);
        [self.contentView addSubview:avatar];
        [_participants addObject:avatar];
        i++;
    }
}
@end
