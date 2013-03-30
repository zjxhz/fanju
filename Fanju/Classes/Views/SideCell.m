//
//  SideCell.m
//  Fanju
//
//  Created by Xu Huanze on 3/25/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import "SideCell.h"

@implementation SideCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)layoutSubviews{
    [super layoutSubviews];
    self.textLabel.frame = CGRectMake(18, 0, 100, 44);
}
@end
