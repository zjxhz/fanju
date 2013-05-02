//
//  FeedTableItemCell.m
//  EasyOrder
//
//  Created by 浣泽 徐 on 7/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FeedTableItemCell.h"
#import "AvatarFactory.h"
#import "OrderTableItem.h"
#import "DateUtil.h"

@interface FeedTableItemCell(){
    UserImageView *_avatar;
    TTStyledTextLabel *_event;
    UILabel *_time;
}
@end
@implementation FeedTableItemCell


+ (CGFloat)tableView:(UITableView*)tableView rowHeightForObject:(id)item {  
	return 80;
}



- (id)initWithStyle:(UITableViewCellStyle)style
    reuseIdentifier:(NSString*)identifier {
	if (self = [super initWithStyle:UITableViewCellStyleValue2
                    reuseIdentifier:identifier]) {
		_item = nil;
        
        _avatar = [AvatarFactory defaultAvatarWithFrame:CGRectMake(8, 8, 41, 41)];
        [self.contentView addSubview:_avatar];
        
        _event = [[TTStyledTextLabel alloc] initWithFrame:CGRectMake(55, 8, 250, 40)];
        [self.contentView addSubview:_event];
        
        _time = [[UILabel alloc] initWithFrame:CGRectMake(55, 40, 250, 20)];
        [self.contentView addSubview:_time];
	}
    
	return self;
}



- (id)object {
	return _item;  
}

- (void)setObject:(id)object {
	if (_item != object) {
		[super setObject:object];
        OrderTableItem *item = object;

        [_avatar setPathToNetworkImage:[item.orderInfo.customer avatarFullUrl]];
        NSString* text = [NSString stringWithFormat: @"<b>%@</b>参加了%@", item.orderInfo.customer.name, item.orderInfo.meal.topic];
        _event.text =  [TTStyledText textFromXHTML:text lineBreaks:YES URLs:YES];
        _event.font = [UIFont systemFontOfSize:12];
        
        _time.font = [UIFont systemFontOfSize:10];
        _time.textColor = [UIColor grayColor];
        _time.text = [DateUtil humanReadableIntervals:-[item.orderInfo.createdTime timeIntervalSinceNow]];
	}
}

- (void)layoutSubviews {
	[super layoutSubviews];
    // Set the size, font, foreground color, background color, ...
    
}

@end
