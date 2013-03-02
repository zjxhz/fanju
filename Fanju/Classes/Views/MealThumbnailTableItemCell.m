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
#import "OrderTableItem.h"
#import "AvatarFactory.h"

@interface MealThumbnailTableItemCell(){
    UILabel *_fromLabel;
    UILabel *_topicLabel;
    UILabel *_numAndCodeLabel;
	UILabel *_subtitleLabel;
    TTImageView *_imgView;
    UIView *_frame;
    UILabel *_restaurant;
    UIView *_peopleFrame;
    UIButton *accetButton;
    UIButton *rejectButton;
}
@end

@implementation MealThumbnailTableItemCell

+ (CGFloat)tableView:(UITableView*)tableView rowHeightForObject:(id)item {  
	return 125.0;
}

- (void)buildUI
{
    //_frame = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"big_frame.png"]];
    _frame = [[UIView alloc] initWithFrame:CGRectMake(0, 0,320,120)];
    [self.contentView addSubview:_frame];
    
    int y = 2;
    if ([_item isKindOfClass:[MealInvitationTableItem class]]){
        _fromLabel = [[UILabel alloc] initWithFrame:CGRectMake(2, y, 200, 20)];
        y += 20;
        [_frame addSubview:_fromLabel];
    }
    
    _imgView = [[TTImageView alloc] initWithFrame:CGRectMake(2, y, 120, 111)];
    [_imgView setContentMode:UIViewContentModeScaleAspectFill];
    _imgView.clipsToBounds = YES; 
    [_frame addSubview:_imgView];
    
    _topicLabel = [[UILabel alloc] initWithFrame:CGRectMake((_frame.frame.size.width - 100) / 2, y+45, 200, y+50)];
    [_topicLabel setBackgroundColor:[UIColor clearColor]];
    [_topicLabel setFont:[UIFont boldSystemFontOfSize:14]];
    [_topicLabel setTextAlignment:UITextAlignmentCenter];
    [_frame addSubview:_topicLabel];
    
    _subtitleLabel = [[UILabel alloc] initWithFrame:CGRectMake((_frame.frame.size.width - 100) / 2, y+75, 200, 20)];
    [_subtitleLabel setBackgroundColor:[UIColor clearColor]];
    [_subtitleLabel setFont:[UIFont italicSystemFontOfSize:12]];
    [_subtitleLabel setTextAlignment:UITextAlignmentCenter];
    [_frame addSubview:_subtitleLabel];
    
    _numAndCodeLabel = [[UILabel alloc] initWithFrame:CGRectMake((_frame.frame.size.width - 100) / 2, y+95, 200, 20)];
    [_numAndCodeLabel setBackgroundColor:[UIColor clearColor]];
    [_numAndCodeLabel setFont:[UIFont boldSystemFontOfSize:12]];
    [_numAndCodeLabel setTextAlignment:UITextAlignmentCenter];
    [_frame addSubview:_numAndCodeLabel];
    
    
    if ([_item isKindOfClass:[MealInvitationTableItem class]]){
        _fromLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 20)];
        y += 20;
    }
    
    _peopleFrame = [[UIView alloc] initWithFrame:CGRectMake(124, y, 240, 57)];
    [_peopleFrame setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.5]];
    [_frame addSubview:_peopleFrame];
    _item = nil;
}

- (id)initWithStyle:(UITableViewCellStyle)style
    reuseIdentifier:(NSString*)identifier {
	if (self = [super initWithStyle:UITableViewCellStyleValue2
                    reuseIdentifier:identifier]) {
        [self buildUI];
        viewInitialzed = YES;
	}
    
	return self;
}


- (id)object {
	return _item;  
}

- (void)setObject:(id)object {
	if (_item != object) {
		[super setObject:object];
//        if(viewInitialzed){
//            [_frame removeFromSuperview];
//        }
        MealInfo *mealInfo = nil;
        MealInvitation *mealInvitation = nil;
        OrderInfo *order = nil;
        if ([object isKindOfClass:[OrderTableItem class]]) {
            OrderTableItem *orderTableItem =  object;
            order = orderTableItem.orderInfo;
            mealInfo = order.meal;
        } else if([object isKindOfClass:[MealInvitationTableItem class]]) {
            MealInvitationTableItem *mealInvitationTableItem = object;
            mealInvitation = mealInvitationTableItem.mealInvitation;        
            mealInfo = mealInvitation.meal;
        } 
        
        if (mealInvitation) {
            NSString *invitationString = mealInfo.type == THEMES ? NSLocalizedString(@"GatheringInvitation", nil) : NSLocalizedString(@"DatingInvitation", nil);
            
            NSString* timePast = [DateUtil humanReadableIntervals:[mealInvitation.timestamp timeIntervalSinceNow]];
            [_fromLabel setText:[NSString stringWithFormat:invitationString, mealInvitation.from.username, timePast]];
            _imgView.frame = CGRectMake(2, 22, 120, 111);
            
        } else {
            _fromLabel = nil;
            _imgView.frame = CGRectMake(2, 2, 120, 111);
        }
		// Set the data in various UI elements
		[_topicLabel setText:mealInfo.topic];
        
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df setDateStyle:NSDateFormatterFullStyle];
        [df setLocale:[NSLocale currentLocale]];
		[_subtitleLabel setText:[df stringFromDate:mealInfo.time]];
        
        [_numAndCodeLabel setText:[NSString stringWithFormat:@"验证码：%@  人数：%d", order.code, order.numerOfPersons]];
        [_imgView setUrlPath:[NSString stringWithFormat:@"http://%@%@", EOHOST, mealInfo.photoURL]];
        [_restaurant setText:mealInfo.restaurant.name];
        
        for (UIView *view in [_peopleFrame subviews]) {
            if ([view isKindOfClass:[TTImageView class]]) {
                [view removeFromSuperview];
            }
        }
        
        int num = [mealInfo.participants count];
        for (int i = 0; i < num; i++) {
            [_peopleFrame addSubview:[AvatarFactory avatarForUser:[mealInfo.participants objectAtIndex:i] frame:CGRectMake(8 + 50 * i, 8, 41, 41) ]];
        }
	}
}

- (void)layoutSubviews {
	[super layoutSubviews];
    // Set the size, font, foreground color, background color, ...
    _frame.center = self.contentView.center;
    
}

@end
