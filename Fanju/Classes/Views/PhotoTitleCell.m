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
        
        _seeAllButton = [[UILabel alloc] initWithFrame:CGRectMake(246, 10, 0, 0)];
        _seeAllButton.textColor = RGBCOLOR(150, 150, 150);
        //    moreButton.backgroundColor = [UIColor clearColor];
        _seeAllButton.font = [UIFont systemFontOfSize:12];
        _seeAllButton.text = @"查看更多";
        _seeAllButton.backgroundColor = [UIColor clearColor];
        [_seeAllButton sizeToFit];
        [self.contentView addSubview:_seeAllButton];
        
        UIImage* disclosureIcon = [UIImage imageNamed:@"disclosure"];
        _disclosureView = [[UIImageView alloc] initWithFrame:CGRectMake(295, 10, disclosureIcon.size.width, disclosureIcon.size.height)];
        _disclosureView.image = disclosureIcon;
        [self.contentView addSubview:_disclosureView];
    }
    return self;
}



@end
