//
//  NumberOfParticipantsCell.m
//  Fanju
//
//  Created by Xu Huanze on 4/13/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import "NumberOfParticipantsCell.h"

@implementation NumberOfParticipantsCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        UIImage* minus = [UIImage imageNamed:@"minus"];
        UIImage* add = [UIImage imageNamed:@"add"];
        
        CGFloat segWidth = minus.size.width + add.size.width;
        CGFloat segX = self.contentView.frame.size.width - segWidth - 15;
        
        _segControll = [[AKSegmentedControl alloc] initWithFrame:CGRectMake(segX, 8, segWidth, minus.size.height)];
        _segControll.segmentedControlMode = AKSegmentedControlModeButton;
        UIButton* minusButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, minus.size.width, minus.size.height)];
        [minusButton setBackgroundImage:minus forState:UIControlStateNormal];
//        [minusButton addTarget:self action:@selector(minus:) forControlEvents:UIControlEventTouchUpInside];
        UIButton* addButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, minus.size.width, minus.size.height)];
        [addButton setBackgroundImage:add forState:UIControlStateNormal];
//        [addButton addTarget:self action:@selector(add:) forControlEvents:UIControlEventTouchUpInside];
        [_segControll setButtonsArray:@[minusButton, addButton]];
        
        [self.contentView addSubview:_segControll];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
