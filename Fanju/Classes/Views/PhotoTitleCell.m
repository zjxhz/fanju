//
//  PhotoTitleCell.m
//  Fanju
//
//  Created by Xu Huanze on 3/20/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import "PhotoTitleCell.h"

@implementation PhotoTitleCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        UIImage* photoIcon = [UIImage imageNamed:@"photo_icon"];
        UIImageView* iconView = [[UIImageView alloc] initWithFrame:CGRectMake(15, 10, photoIcon.size.width, photoIcon.size.height)];
        iconView.image = photoIcon;
        [self.contentView addSubview:iconView];
        
        UILabel* photoLabel = [[UILabel alloc] initWithFrame:CGRectMake(36, 10, 0, 0)];
        photoLabel.textColor = RGBCOLOR(150, 150, 150);
        photoLabel.backgroundColor = [UIColor clearColor];
        photoLabel.font = [UIFont systemFontOfSize:12];
        photoLabel.text = @"相册：";
        [photoLabel sizeToFit];
        [self.contentView addSubview:photoLabel];
        
        UILabel* moreLabel = [[UILabel alloc] initWithFrame:CGRectMake(246, 10, 0, 0)];
        moreLabel.textColor = RGBCOLOR(150, 150, 150);
        //    moreButton.backgroundColor = [UIColor clearColor];
        moreLabel.font = [UIFont systemFontOfSize:12];
        moreLabel.text = @"查看更多";
        moreLabel.backgroundColor = [UIColor clearColor];
        [moreLabel sizeToFit];
        [self.contentView addSubview:moreLabel];
        
        UIImage* disclosureIcon = [UIImage imageNamed:@"disclosure"];
        UIImageView* disclosureView = [[UIImageView alloc] initWithFrame:CGRectMake(295, 10, disclosureIcon.size.width, disclosureIcon.size.height)];
        disclosureView.image = disclosureIcon;
        [self.contentView addSubview:disclosureView];
    }
    return self;
}



@end
