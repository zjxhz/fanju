//
//  UserTagCell.m
//  EasyOrder
//
//  Created by 徐 浣泽 on 2/1/13.
//
//

#import "UserTagCell.h"

@implementation UserTagCell


#pragma mark -
#pragma mark TTTableViewCell
//-(void)layoutSubviews{
//    [super layoutSubviews];
//    CGRect rect =  self.textLabel.frame;
//    rect.origin.x = 17;
//    self.textLabel.frame = rect;
//}
- (void)setObject:(id)object {
    [super setObject:object];
    if ([object isKindOfClass:[NSString class]]) {
        NSString* text = object;
        self.imageView.image = [UIImage imageNamed:@"tag_add"];
        self.textLabel.font = [UIFont systemFontOfSize:16];
        self.textLabel.text = text;
        self.textLabel.textColor = RGBCOLOR(0x2B, 0x2B, 0x2B);
        return;
    } else {
        self.imageView.image = nil;
    }
    _userTag = object;
    self.textLabel.font = [UIFont systemFontOfSize:17];
    self.textLabel.textColor = RGBCOLOR(0x2B, 0x2B, 0x2B);
    self.textLabel.text = _userTag.name;

}

@end
