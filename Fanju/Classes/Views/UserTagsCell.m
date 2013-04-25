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
#import "UserListViewController.h"
#import "NetworkHandler.h"
#import "WidgetFactory.h"

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
        _frameTagDic = [NSMutableDictionary dictionary];
        self.contentView.userInteractionEnabled = YES;
        UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped:)];
        [self.contentView addGestureRecognizer:tap];
    }
    return self;
}

-(UIImage*)bgImageForTag:(UserTag*)tag atFirst:(BOOL)first{
    UserProfile* me = [Authentication sharedInstance].currentUser;
    BOOL common = [me.tags containsObject:tag];
    UIImage* tag_bg0 = [UIImage imageNamed:@"tag_bg0"];
    UIImage* tag_bg = [UIImage imageNamed:@"tag_bg"];
    UIImage* tag_bg0_normal = [UIImage imageNamed:@"tag_bg0_normal"];
    UIImage* tag_bg_normal = [UIImage imageNamed:@"tag_bg_normal"];
    if (first && common) {
        return tag_bg0;
    } else if(first && !common){
        return tag_bg0_normal;
    } else if(!first && common){
        return tag_bg;
    } else {
        return tag_bg_normal;
    }
}

-(void)setTags:(NSArray *)tags{
    _tags = tags;
    [_frameTagDic removeAllObjects];
    [self removeTagsFromView];
    UserProfile* me = [Authentication sharedInstance].currentUser;
    _tags = [_tags sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        if ([me.tags containsObject: obj1]) {
            return -1;
        } else if ([me.tags containsObject:obj2]){
            return 1;
        }
        return 0;
    } ];
    UIFont* font = [UIFont systemFontOfSize:12];
    CGFloat x = TAG_GAP;
    CGFloat y = 8;
    for(int i = 0; i < _tags.count; ++i){
        UserTag* tag = _tags[i];
        UIImage* bg = [self bgImageForTag:tag atFirst:i == 0];
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
            bg = [self bgImageForTag:tag atFirst:YES];
        }
        CGRect frame = CGRectMake(x, y, tagWidth, bg.size.height);
        UIImageView* tagView = [[UIImageView alloc] initWithFrame:frame];
        _frameTagDic[[NSValue valueWithCGRect:frame]] = tag;
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

    _cellHeight = y + 20 + 8;
}

-(void)removeTagsFromView{
    [[self.contentView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
}

-(void)viewTapped:(UITapGestureRecognizer*)recognizer{
    CGPoint point = [recognizer locationInView:self.contentView];
    for (NSValue* value in [_frameTagDic allKeys]) {
        CGRect frame = [value CGRectValue];
        if (CGRectContainsPoint(frame, point)) {
            UserTag* tag =  _frameTagDic[value];
            [self showUsersWithTag:tag];
            break;
        }
    }
}

-(void)showUsersWithTag:(UserTag*)tag{
    UserListViewController* ul = [[UserListViewController alloc] initWithStyle:UITableViewStylePlain];
    ul.baseURL = [NSString stringWithFormat:@"http://%@/api/v1/usertag/%d/users/?format=json", EOHOST, tag.uID];
    ul.title = tag.name;
    ul.tag = tag;
    ul.showAddTagButton = YES;
    ul.hideNumberOfSameTags = YES;
    ul.hideFilterButton = YES;
    [_rootController.navigationController pushViewController:ul animated:YES];
    
}
@end
