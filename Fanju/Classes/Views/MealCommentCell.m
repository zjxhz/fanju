//
//  MealCommentCell.m
//  Fanju
//
//  Created by Xu Huanze on 7/23/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import "MealCommentCell.h"
#import "User.h"
#import "AvatarFactory.h"
#import "DateUtil.h"
#import "QuartzCore/QuartzCore.h"
#import "UserDetailsViewController.h"
#import "SendCommentViewController.h"

@implementation MealCommentCell{
    UIImage* _sepImg;
    UIImageView* _separator;
    UIImageView* _repliesBgView;
}

+ (CGFloat)tableView:(UITableView*)tableView rowHeightForObject:(id)item {
    if (!item) {
        return 65;
    }
    MealComment* comment = item;
    CGFloat height = [MealCommentCell heightForMasterComment:comment];
    
    if (comment.replies.count > 0) {
        height += [MealCommentCell heightForReplies:comment.replies];
        height += 3;
    }
    return height;
}

+(CGFloat)heightForMasterComment:(MealComment*)comment{
    CGFloat height = 0;
    NSString *text = comment.comment;
    CGSize size = [text sizeWithFont:[UIFont systemFontOfSize:13] constrainedToSize:CGSizeMake(225, 1000) lineBreakMode:NSLineBreakByWordWrapping];
	height += 50 + size.height;
    return height;
}

+(CGFloat)heightForReplies:(NSSet*)replies{
    return 0;
//    CGFloat height = 0;
//    if (replies.count > 0) {
//        for (MealComment* reply in replies) {
//            height += [reply.comment sizeWithFont:[UIFont systemFontOfSize:12] constrainedToSize:CGSizeMake(180, 400)].height;
//            height += 35; //other parts than the comment
//        }
//    }
//    height += 7;
//    return height;
}

- (id)initWithStyle:(UITableViewCellStyle)style
    reuseIdentifier:(NSString*)identifier {
	if (self = [super initWithStyle:style
                    reuseIdentifier:identifier]) {
        UIViewController* temp = [[UIViewController alloc] initWithNibName:@"MealCommentCell" bundle:nil];
        self = (MealCommentCell*)temp.view;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        _sepImg = [UIImage imageNamed:@"meal_comment_sep"];
        _separator = [[UIImageView alloc] initWithImage:_sepImg];
        [self.contentView addSubview:_separator];
        _replyImageView.userInteractionEnabled = YES;
        UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(replyTapped:)];
        [_replyImageView addGestureRecognizer:tap];
        
        _avatar.userInteractionEnabled = YES;
        _avatar.layer.cornerRadius = 5;
        _avatar.layer.masksToBounds = YES;
        UITapGestureRecognizer* avatarTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(avatarTapped:)];
        [_avatar addGestureRecognizer:avatarTap];
	}
    
	return self;
}

-(void)avatarTapped:(UITapGestureRecognizer*)ges{
    UserDetailsViewController* vc = [[UserDetailsViewController alloc] init];
    vc.user = _mealComment.user;
    [_parentController.navigationController pushViewController:vc animated:YES];
}


-(void)replyTapped:(UITapGestureRecognizer*)ges{
    SendCommentViewController* vc = [[SendCommentViewController alloc] init];
    vc.parentComment = _mealComment;
    vc.meal = _mealComment.meal;
    vc.sendCommentDelegate = _parentController;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [_parentController presentModalViewController:nav animated:YES];
}

- (id)object {
    return _mealComment;
}

-(void)layoutSubviews{
    [super layoutSubviews];
    CGFloat cellHeight = [MealCommentCell tableView:nil rowHeightForObject:_mealComment];
    _separator.frame = CGRectMake(20, cellHeight - _sepImg.size.height, _sepImg.size.width, _sepImg.size.height);
    if (_mealComment.replies.count > 0) {
        CGFloat replyY = [MealCommentCell heightForMasterComment:_mealComment] - 8;
        CGFloat replyHeight = [MealCommentCell heightForReplies:_mealComment.replies];
        _repliesBgView.frame = CGRectMake(61, replyY, 247, replyHeight);
    }
    CGFloat replyIconY = [MealCommentCell heightForMasterComment:_mealComment] - 30;
    _replyImageView.frame = CGRectMake(_replyImageView.frame.origin.x, replyIconY, _replyImageView.frame.size.width, _replyImageView.frame.size.height);
}

-(void)prepareForReuse{
    [super prepareForReuse];
    [_avatar removeFromSuperview];
    _avatar = nil;
    _avatar.image = nil;
    _nameLabel.text = nil;
    _commentLabel.text = nil;
    _timeLabel.text = nil;    
    [_repliesBgView removeFromSuperview];
    _repliesBgView = nil;
    
}

- (void)setObject:(id)object {
    [super setObject:object];
    _mealComment = object;
    if (!_mealComment) {
        return;
    }
    
    User* user = _mealComment.user;
    [_avatar setPathToNetworkImage:[URLService absoluteURL:_mealComment.user.avatar]];
//    [_avatar removeFromSuperview];
//    _avatar = [AvatarFactory avatarForUser:user withFrame:_avatar.frame];
//    [self.contentView addSubview:_avatar];
//    _avatar.userInteractionEnabled = YES;
//    UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(avatarTapped:)];
//    [_avatar addGestureRecognizer:tap];
    _nameLabel.text = user.name;
    if (_mealComment.parent) {
        _commentLabel.text = [NSString stringWithFormat:@"回复 %@: %@", _mealComment.parent.user.name, _mealComment.comment];
    } else {
        _commentLabel.text = _mealComment.comment;        
    }

    [_commentLabel sizeToFit];
    _timeLabel.text = [DateUtil userFriendlyStringFromDate:_mealComment.timestamp];
    
//    if (_mealComment.replies.count > 0) {
//        UIImage* replyBg = [UIImage imageNamed:@"reply_bg"];
//        replyBg = [replyBg resizableImageWithCapInsets:UIEdgeInsetsMake(20, 123, 10, 123)];
//        _repliesBgView = [[UIImageView alloc] initWithImage:replyBg];
//        [self.contentView addSubview:_repliesBgView];
//        int i = 0;
//        CGFloat y = 15;
//        for (MealComment* reply in _mealComment.replies) {
//            UIImageView* avatar = [AvatarFactory avatarForUser:reply.user withFrame:CGRectMake(6, y, 35, 35)];
//            [_repliesBgView addSubview:avatar];
//            UILabel* nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(48, y, 100, 15)];
//            nameLabel.backgroundColor = [UIColor clearColor];
//            nameLabel.textColor = RGBCOLOR(0x12, 0x10, 0x10);
//            nameLabel.font = [UIFont boldSystemFontOfSize:12];
//            nameLabel.text = reply.user.name;
//            [_repliesBgView addSubview:nameLabel];
//        
//            UILabel* timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(200, y, 40, 15)];
//            timeLabel.textAlignment = UITextAlignmentRight;
//            timeLabel.backgroundColor = [UIColor clearColor];
//            timeLabel.textColor = RGBCOLOR(0xA1, 0xA1, 0xA1);
//            timeLabel.font = [UIFont boldSystemFontOfSize:12];
//            timeLabel.text = [DateUtil userFriendlyStringFromDate:reply.timestamp];
//            [_repliesBgView addSubview:timeLabel];
//            
//            y += 20;
//            UILabel* commentLabel = [[UILabel alloc] initWithFrame:CGRectMake(48, y, 180, 0)];
//            commentLabel.backgroundColor = [UIColor clearColor];
//            commentLabel.textColor = RGBCOLOR(0x66, 0x66, 0x66);
//            commentLabel.font = [UIFont systemFontOfSize:12];
//            commentLabel.text = reply.comment;
//            commentLabel.numberOfLines = 0;
//            commentLabel.lineBreakMode = NSLineBreakByWordWrapping;
//            [commentLabel sizeToFit];
//            [_repliesBgView addSubview:commentLabel];
//            
//            if (i < _mealComment.replies.count - 1) {
//                y = commentLabel.frame.origin.y + commentLabel.frame.size.height + 7;
//                UIImage* sep = [UIImage imageNamed:@"reply_sep"];
//                UIImageView* sepView = [[UIImageView alloc] initWithFrame:CGRectMake(0, y, sep.size.width, sep.size.height)];
//                sepView.image = sep;
//                [_repliesBgView addSubview:sepView];
//            }
//            y += 6;
//            i++;
//        }
//    }
}

@end
