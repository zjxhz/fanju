//
//  MealThumbnailTableItemCell.m
//  EasyOrder
//
//  Created by 浣泽 徐 on 4/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MealThumbnailTableItemCell.h"
#import "MealTableItem.h"
#import "MealInvitationTableItem.h"
#import "DateUtil.h"
#import "AvatarFactory.h"
#import "NINetworkImageView.h"
#import "Restaurant.h"

#define CELL_HEIGHT 125
#define THUMBNAIL_LENGTH 107
#define RIGHT_FRAME_X 123
@interface MealThumbnailTableItemCell(){
    UILabel *_topicLabel;
    UILabel *_codeTextLabel;
    NINetworkImageView *_imgView;
    UIView *_frame;
    UILabel *_restaurant;
    UIView *_peopleFrame;
    UIButton *accetButton;
    UIButton *rejectButton;
    UILabel* _timeLabel;
    UILabel* _addressLabel;
    UILabel* _numberOfPersonLabel;
}
@end

@implementation MealThumbnailTableItemCell

+ (CGFloat)tableView:(UITableView*)tableView rowHeightForObject:(id)item {  
	return 123.0;
}

- (void)buildUI
{
    UIImage* bg = [UIImage imageNamed:@"meal_thumbnail_bg"];
    UIImageView* bgView = [[UIImageView alloc] initWithFrame:CGRectMake(4, 4, bg.size.width, bg.size.height)];
    bgView.image = bg;
    
    _imgView = [[NINetworkImageView alloc] initWithFrame:CGRectMake(4, 4, THUMBNAIL_LENGTH, THUMBNAIL_LENGTH)];
    [_imgView setContentMode:UIViewContentModeScaleAspectFill];
    _imgView.clipsToBounds = YES;
    [bgView addSubview:_imgView];
    [self.contentView addSubview:bgView];
    
    
    _frame = [[UIView alloc] initWithFrame:CGRectMake(RIGHT_FRAME_X, 0, 320 - RIGHT_FRAME_X, CELL_HEIGHT)];
    
    _topicLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 300 - RIGHT_FRAME_X, 18)];
    [_topicLabel setBackgroundColor:[UIColor clearColor]];
    [_topicLabel setFont:[UIFont boldSystemFontOfSize:18]];
    _topicLabel.minimumFontSize = 12;
    _topicLabel.adjustsFontSizeToFitWidth =YES;
    _topicLabel.textColor = RGBCOLOR(50, 50, 50);
    [_topicLabel setTextAlignment:UITextAlignmentCenter];
    [_frame addSubview:_topicLabel];
    
    UIImage* clockIcon = [UIImage imageNamed:@"order_time"];
    UIImageView* clockView = [[UIImageView alloc] initWithImage:clockIcon];
    clockView.frame = CGRectMake(0, 36, clockIcon.size.width, clockIcon.size.height);
    CGFloat textX = 19;
    _timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(textX, 37, 0, 0)];
    _timeLabel.font = [UIFont systemFontOfSize:10];
    _timeLabel.textColor = RGBCOLOR(150, 150, 150);
    _timeLabel.backgroundColor = [UIColor clearColor];
    [_frame addSubview:clockView];
    [_frame addSubview:_timeLabel];
    
    UIImage* addIcon = [UIImage imageNamed:@"order_address"];
    UIImageView* addView = [[UIImageView alloc] initWithImage:addIcon];
    addView.frame = CGRectMake(0, 56, addIcon.size.width, addIcon.size.height);
    _addressLabel = [[UILabel alloc] initWithFrame:CGRectMake(textX, 55, 170, 30)];
    _addressLabel.font = [UIFont systemFontOfSize:10];
    _addressLabel.textColor = RGBCOLOR(150, 150, 150);
    _addressLabel.numberOfLines = 2;
    _addressLabel.backgroundColor = [UIColor clearColor];
    [_frame addSubview:addView];
    [_frame addSubview:_addressLabel];
    
    UIImage* codeIcon = [UIImage imageNamed:@"meal_code"];
    UIImageView* codeView = [[UIImageView alloc] initWithImage:codeIcon];
    codeView.frame = CGRectMake(0, 100, codeIcon.size.width, codeIcon.size.height);
    UILabel* codeLabel = [[UILabel alloc] initWithFrame:CGRectMake(textX, 102, 0, 0)];
    codeLabel.font = [UIFont systemFontOfSize:10];
    codeLabel.backgroundColor = [UIColor clearColor];
    codeLabel.textColor = RGBCOLOR(150, 150, 150);
    codeLabel.text = @"验证码：";
    [codeLabel sizeToFit];
    
    _codeTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(57, 98, 100, 18)];
    _codeTextLabel.font = [UIFont boldSystemFontOfSize:17];
    _codeTextLabel.textColor = RGBCOLOR(50, 140, 50);
    _codeTextLabel.backgroundColor = [UIColor clearColor];
    [_frame addSubview:codeView];
    [_frame addSubview:codeLabel];
    [_frame addSubview:_codeTextLabel];
  
    _numberOfPersonLabel = [[UILabel alloc] initWithFrame:CGRectMake(156, 102, 0, 0)];
    _numberOfPersonLabel.backgroundColor = [UIColor clearColor];
    _numberOfPersonLabel.font = [UIFont systemFontOfSize:10];
    _numberOfPersonLabel.textColor = RGBCOLOR(150, 150, 150);
    [_frame addSubview:_numberOfPersonLabel];
    
    
    [self.contentView addSubview:_frame];
    
    UIImage* separatorImg = [UIImage imageNamed:@"separator"];
    UIImageView* separatorView = [[UIImageView alloc] initWithFrame:CGRectMake(0, CELL_HEIGHT - separatorImg.size.height, separatorImg.size.width, separatorImg.size.height)];
    separatorView.image = separatorImg;
    [self.contentView addSubview:separatorView];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (id)initWithStyle:(UITableViewCellStyle)style
    reuseIdentifier:(NSString*)identifier {
	if (self = [super initWithStyle:UITableViewCellStyleValue2
                    reuseIdentifier:identifier]) {
        [self buildUI];
	}
    
	return self;
}

-(id)object{
    return _orderInfo;
}

-(void)prepareForReuse{
    _imgView.image = nil;
    _topicLabel.text = nil;
    _timeLabel.text = nil;
    _addressLabel.text = nil;
    _codeTextLabel.text = nil;
    _numberOfPersonLabel.text = nil;
}

- (void)setObject:(id)object {
    [super setObject:object];
    if (object == nil) {
        return;
    }
    Meal *mealInfo = nil;
    MealInvitation *mealInvitation = nil;
    if ([object isKindOfClass:[Order class]]) {
        _orderInfo = object;
        mealInfo = _orderInfo.meal;
    } else if([object isKindOfClass:[MealInvitationTableItem class]]) {
        MealInvitationTableItem *mealInvitationTableItem = object;
        mealInvitation = mealInvitationTableItem.mealInvitation;        
        mealInfo = mealInvitation.meal;
    } 
    
    // Set the data in various UI elements
    [_imgView setPathToNetworkImage:[URLService  absoluteURL:mealInfo.photoURL] forDisplaySize:CGSizeMake(THUMBNAIL_LENGTH, THUMBNAIL_LENGTH) contentMode:UIViewContentModeScaleAspectFill];
    [_topicLabel setText:mealInfo.topic];
    [_timeLabel setText:[MealService dateTextOfMeal:mealInfo]];
    [_timeLabel sizeToFit];
    _addressLabel.text = [NSString stringWithFormat:@"%@ %@", mealInfo.restaurant.name, mealInfo.restaurant.address];
//        [_addressLabel sizeToFit];
    if (_orderInfo.code) {
        _codeTextLabel.text = _orderInfo.code;
    } else {
        _codeTextLabel.text = @"未支付";
    }
    
//        [_codeTextLabel sizeToFit];
    _numberOfPersonLabel.text = [NSString stringWithFormat:@"限%@人", _orderInfo.numberOfPersons];
    [_numberOfPersonLabel sizeToFit];
}

@end
