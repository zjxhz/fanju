//
//  UserTagsCell.m
//  EasyOrder
//
//  Created by 浣泽 徐 on 9/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UserTagsCell.h"
#import "Authentication.h"
#import "UserProfile.h"
#import "Three20/Three20.h"
#import "QuartzCore/QuartzCore.h"

//#define MAX_VISIBLE_TAGS 5
#define TAG_GAP 10
#define FONT_SIZE 14	
#define LABEL_INSET_H 15
#define LABEL_INSET_V 5
#define TAG_GAP 10
@implementation UserTagsCell
@synthesize tags = _tags;


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        
    }
    return self;
}

-(void)setTags:(NSArray *)tags{
    UIFont* font = [UIFont systemFontOfSize:12];
    UIImage* tag_bg0 = [UIImage imageNamed:@"tag_bg0"];
    UIImage* tag_bg = [UIImage imageNamed:@"tag_bg"];
    CGFloat x = TAG_GAP;
    CGFloat y = 8;
    for(int i = 0; i < tags.count; ++i){
        UIImage* bg = i == 0 ? tag_bg0 : tag_bg;
        UserTag* tag = tags[i];
        CGFloat tagWidth = bg.size.width;
        if (tag.name.length > 3) {
            CGFloat width = [tag.name sizeWithFont:font].width; //tag0.name
            bg = [bg resizableImageWithCapInsets:UIEdgeInsetsMake(9, 25, 10, 25)];
            tagWidth = width + 25;
        }
        CGFloat right = x + tagWidth;
        if (right > 320 ) {
            x = TAG_GAP;
            y += bg.size.height + 5;
            bg = tag_bg0;
        }
        UIImageView* tagView = [[UIImageView alloc] initWithFrame:CGRectMake(x, y, tagWidth, bg.size.height)];
        tagView.clipsToBounds = YES;
        tagView.image = bg;
        
        UILabel* tagl = [[UILabel alloc] initWithFrame:tagView.frame];
        tagl.text = tag.name;
        tagl.textColor = [UIColor whiteColor];
        tagl.font = font;
        tagl.backgroundColor = [UIColor clearColor];
        tagl.textAlignment = UITextAlignmentCenter;
        [self.contentView addSubview:tagView];
        [self.contentView addSubview:tagl];
        
        x += tagWidth - 4; // -4 as there is overlapping
    }

    _cellHeight = y + tag_bg.size.height + 8;
       
        

    
//    
//    self.detailTextLabel.text = [NSString stringWithFormat:@"%d", tags.count];
//    if (_tagLabels) {
//        for(UILabel* label in _tagLabels){
//            [label removeFromSuperview];
//        }
//    }
//    _tagLabels = [NSMutableArray array];
//    _tags = tags;
//    int x = 10;
//    UserProfile *me = [[Authentication sharedInstance] currentUser];
//    _tags = [_tags sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
//        if ([me.tags containsObject: obj1]) {
//            return -1;
//        } else if ([me.tags containsObject:obj2]){
//            return 1;
//        }
//        return 0;
//    } ];
//    
//    for (int i = 0; i < _tags.count; ++i) { //show maxmial 5 tags
//        UserTag* tag = [_tags objectAtIndex:i];
//        UILabel* tagLabel = [[UILabel alloc] init];
//        [_tagLabels addObject:tagLabel];
//        tagLabel.textColor = [UIColor whiteColor];
//        tagLabel.layer.cornerRadius = 5;
//        tagLabel.textAlignment = UITextAlignmentCenter;
//        if ([me.tags containsObject:tag]) {
//            tagLabel.font = [UIFont boldSystemFontOfSize:FONT_SIZE];
//            tagLabel.backgroundColor = RGBCOLOR(0x3C, 0xA2, 0xE2);
//        } else {
//            tagLabel.font = [UIFont systemFontOfSize:FONT_SIZE];
//            tagLabel.backgroundColor = RGBACOLOR(0, 0, 0, 0.5);
//        }
//        tagLabel.text = tag.name;
//        CGSize size = [tag.name sizeWithFont:tagLabel.font];
//        tagLabel.frame = CGRectMake(x, LABEL_INSET_V, size.width + LABEL_INSET_H, size.height + LABEL_INSET_V);
//        x += TAG_GAP + tagLabel.frame.size.width;
//        if (x > 280) {
//            break;
//        } else {
//            [self.contentView addSubview:tagLabel];
//        }
//    }
}
@end
