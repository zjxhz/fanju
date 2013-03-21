//
//  PhotoThumbnailCell.m
//  EasyOrder
//
//  Created by 浣泽 徐 on 9/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PhotoThumbnailCell.h"
#import "NINetworkImageView.h"
#import "AvatarFactory.h"
#import "PhotoViewController.h"

#define PHOTO_BG_WIDTH 70
#define PHOTO_BG_HEIGHT PHOTO_BG_WIDTH
#define PHOTO_WIDTH 62
#define PHOTO_HEIGHT PHOTO_WIDTH
#define PHOTO_BG_GAP 2
@interface PhotoThumbnailCell(){
    BOOL _editable;
    UIImageView *_addPhotoImageView;
    NSMutableArray* _imageViews;
    NSMutableArray* _contentViews;
    UIScrollView* _scrollView;
}
@end

@implementation PhotoThumbnailCell
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier withUser:(UserProfile*)user editable:(BOOL)editable
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _user = user;
        _editable = editable;
        [self buildUI];
    }
    return self;
}

-(void)setUser:(UserProfile *)user{
    if (user == _user) {
        return;
    }
    _user = user;
    for(UIView *view in _contentViews){
        [view removeFromSuperview];
    }
//    [_addPhotoImageView removeFromSuperview];
    [self buildUI];
}

-(void)buildUI{   
    _imageViews = [NSMutableArray array];
    _contentViews = [NSMutableArray array];
    NSArray* photos = [_user photos];
    _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(3, 0, 320 - 3, 70)];
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.backgroundColor = [UIColor clearColor];
    [self resetContentSize:photos.count];
    for (int i = 0; i < photos.count; ++i) {
        [self addPhoto:[_user.photos objectAtIndex:i] atIndex:i];
    }
    [self.contentView addSubview:_scrollView];

//    [self createAddPhotoButtonIfNeeded];
}

-(void)resetContentSize:(NSInteger)photoCount{
    _scrollView.contentSize = CGSizeMake( (PHOTO_BG_WIDTH + PHOTO_BG_GAP) * photoCount, 70);
}

-(void)addPhoto:(UserPhoto*)photo atIndex:(NSInteger)index{
    UIImage* photoBG = [UIImage imageNamed:@"avatar_bg_big"];
    UIView* contentView = [[UIView alloc] initWithFrame:[self frameAtIndex:index]];
    UIImageView *bgView = [[UIImageView alloc] initWithImage:photoBG];
    [contentView addSubview:bgView];
    NINetworkImageView* photoView = [[NINetworkImageView alloc] initWithFrame:CGRectMake(4, 4, PHOTO_WIDTH, PHOTO_HEIGHT)];
    photoView.contentMode = UIViewContentModeScaleAspectFill;
    [photoView setPathToNetworkImage:photo.thumbnailFullUrl forDisplaySize:CGSizeMake(PHOTO_WIDTH, PHOTO_HEIGHT)];
    [contentView addSubview:photoView];
    [_scrollView addSubview:contentView];
    photoView.userInteractionEnabled = YES;
    UITapGestureRecognizer* photoTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(photoTapped:)];
    [photoView addGestureRecognizer:photoTapGestureRecognizer];
    [_imageViews addObject:photoView];
    [_contentViews addObject:contentView];
}

-(void)addUploadedPhoto:(UserPhoto*)photo withLocalImage:(UIImage*)localImage{
    [self addPhoto:photo atIndex:_contentViews.count];
    [self resetContentSize:_imageViews.count];
    [self layoutSubviews];
}

-(void)deleteUserPhoto:(UserPhoto*)photo atIndex:(NSInteger)index{
    UIView *contentView = [_contentViews objectAtIndex:index]; 
    UIView *imgView = [_imageViews objectAtIndex:index];
    [contentView removeFromSuperview];
    [_imageViews removeObject:imgView];
    [_contentViews removeObject:contentView];
    NSInteger i = 0;
    for (UIView* contentView in _contentViews) {
        contentView.frame = [self frameAtIndex:i++];
    }
    
    [self resetContentSize:_imageViews.count];
    [self layoutSubviews];
}


-(CGRect)frameAtIndex:(NSInteger)index{
    return CGRectMake((PHOTO_BG_WIDTH + PHOTO_BG_GAP) * index, 0, PHOTO_BG_WIDTH, PHOTO_BG_HEIGHT);
}

-(void)addTapped:(id)sender{
    [self.delegate didSelectAddPhoto];
}

-(void)photoTapped:(id)sender{
    NSMutableArray* allImages = [NSMutableArray array];
    int index = 0;
    BOOL indexFound = NO;
    UITapGestureRecognizer* reg = (UITapGestureRecognizer*)sender;
    for(NINetworkImageView* iv in _imageViews){
        if (!indexFound) {
            if (reg.view != iv) {
                index++;
            } else {
                indexFound = YES;
            }           
        }
        [allImages addObject:iv.image];
    }

    [self.delegate didSelectUserPhoto:[_user.photos objectAtIndex:index] withAllPhotos:allImages atIndex:index];
}
@end
