//
//  TagSelectionCell.m
//  Fanju
//
//  Created by Xu Huanze on 5/23/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import "TagSelectionCell.h"
#import "Tag.h"
#import "TagSelectionItem.h"

@implementation TagSelectionCell{
    TagSelectionItem* _item;
    UIImageView* _imageView;
    UIImage* _selectedImg;
    UIImage* _unselectedImg;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _selectedImg = [UIImage imageNamed:@"tag_selected"];
        _unselectedImg = [UIImage imageNamed:@"tag_unselected"];
        _imageView = [[UIImageView alloc] initWithFrame:CGRectMake(285, 9, _selectedImg.size.width, _selectedImg.size.height)];
//        [self.contentView addSubview:_imageView];
        self.textLabel.font = [UIFont systemFontOfSize:15];
        self.textLabel.textColor = RGBCOLOR(0x2B, 0x2B, 0x2B);
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

-(id)object{
    return _item;
}

-(void)setObject:(id)object{
    [super setObject:object];
    _item = object;
    if (!object) {
        self.textLabel.text = nil;
        _imageView.image = nil;
        return;
    }

    Tag* tag = _item.tag;
    if (_item.selected) {
        _imageView.image = _selectedImg;
    } else {
        _imageView.image = _unselectedImg;
    }
    [self.contentView addSubview:_imageView];
    self.textLabel.text = tag.name;
}

@end
