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
@implementation UserTagsCell
@synthesize tags = _tags;


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    return self;
}

-(void)setTags:(NSArray *)tags{
    self.detailTextLabel.text = [NSString stringWithFormat:@"%d", tags.count];
    if (_tagLabels) {
        for(UILabel* label in _tagLabels){
            [label removeFromSuperview];
        }
    }
    _tagLabels = [NSMutableArray array];
    _tags = tags;
    int x = 10;
    UserProfile *me = [[Authentication sharedInstance] currentUser];
    _tags = [_tags sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        if ([me.tags containsObject: obj1]) {
            return -1;
        } else if ([me.tags containsObject:obj2]){
            return 1;
        }
        return 0;
    } ];
    
    for (int i = 0; i < _tags.count; ++i) { //show maxmial 5 tags
        UserTag* tag = [_tags objectAtIndex:i];
        UILabel* tagLabel = [[UILabel alloc] init];
        [_tagLabels addObject:tagLabel];
        tagLabel.textColor = [UIColor whiteColor];
        tagLabel.layer.cornerRadius = 5;
        tagLabel.textAlignment = UITextAlignmentCenter;
        if ([me.tags containsObject:tag]) {
            tagLabel.font = [UIFont boldSystemFontOfSize:FONT_SIZE];
            tagLabel.backgroundColor = RGBCOLOR(0x3C, 0xA2, 0xE2);
        } else {
            tagLabel.font = [UIFont systemFontOfSize:FONT_SIZE];
            tagLabel.backgroundColor = RGBACOLOR(0, 0, 0, 0.5);
        }
        tagLabel.text = tag.name;
        CGSize size = [tag.name sizeWithFont:tagLabel.font];
        tagLabel.frame = CGRectMake(x, LABEL_INSET_V, size.width + LABEL_INSET_H, size.height + LABEL_INSET_V);
        x += TAG_GAP + tagLabel.frame.size.width;
        if (x > 280) {
            break;
        } else {
            [self.contentView addSubview:tagLabel];
        }
    }
}
@end
