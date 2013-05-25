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
#import "Authentication.h"
#import "URLService.h"

#define PHOTO_BG_WIDTH 70
#define PHOTO_BG_HEIGHT PHOTO_BG_WIDTH
#define PHOTO_WIDTH 62
#define PHOTO_HEIGHT PHOTO_WIDTH
#define PHOTO_BG_GAP 2
@interface PhotoThumbnailCell(){
    BOOL _editable;
    NSMutableArray* _imageViews;
    NSMutableArray* _contentViews;
    UIScrollView* _scrollView;
    NSArray* _photos;
}
@end

@implementation PhotoThumbnailCell
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier withUser:(User*)user editable:(BOOL)editable
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _user = user;
        _editable = editable;
        [self buildUI];
    }
    return self;
}

-(void)setUser:(User *)user{
    if (user == _user) {
        return;
    }
    _user = user;
    for(UIView *view in _contentViews){
        [view removeFromSuperview];
    }
    [_addOrRequestPhotoButton removeFromSuperview];
    [self buildUI];
}

-(void)buildUI{   
    _imageViews = [NSMutableArray array];
    _contentViews = [NSMutableArray array];
    _photos = [UserService sortedPhotosForUser:_user];
    _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(3, 0, 320 - 3, 70)];
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.backgroundColor = [UIColor clearColor];
    [self resetContentSize:_photos.count];
    if (_photos.count == 0) {
        [self addAddOrRequestPhotoButton];
    } else if([_user isEqual:[UserService service].loggedInUser] && _photos.count < 15){
        [self addAddOrRequestPhotoButton];
    }
    for (int i = 0; i < _photos.count; ++i) {
        [self addPhoto:[_photos objectAtIndex:i] atIndex:i];
    }
    [self.contentView addSubview:_scrollView];
}

-(void)addAddOrRequestPhotoButton{
    _addOrRequestPhotoButton = [[UIButton alloc] initWithFrame:[self frameAtIndex:_photos.count]];
    UIImage* bgImg = nil;
    if ([_user isEqual:[UserService service].loggedInUser]) {
        bgImg = [UIImage imageNamed:@"photo_add"];
    } else {
        bgImg = [UIImage imageNamed:@"photo_request"];
    }
    _addOrRequestPhotoButton.userInteractionEnabled = YES;
    [_addOrRequestPhotoButton setBackgroundImage:bgImg forState:UIControlStateNormal];
    [_addOrRequestPhotoButton addTarget:self action:@selector(addOrRequestTapped:) forControlEvents:UIControlEventTouchUpInside];
    [_scrollView addSubview:_addOrRequestPhotoButton];
    [self resetContentSize:_photos.count];
}

-(void)resetContentSize:(NSInteger)photoCount{
    int count = photoCount;
    if (_addOrRequestPhotoButton) {
        count++;
    }
    _scrollView.contentSize = CGSizeMake( (PHOTO_BG_WIDTH + PHOTO_BG_GAP) * count, 70);
}

-(void)addPhoto:(Photo*)photo atIndex:(NSInteger)index{
    UIImage* photoBG = [UIImage imageNamed:@"avatar_bg_big"];
    UIView* contentView = [[UIView alloc] initWithFrame:[self frameAtIndex:index]];
    UIImageView *bgView = [[UIImageView alloc] initWithImage:photoBG];
    [contentView addSubview:bgView];
    NINetworkImageView* photoView = [[NINetworkImageView alloc] initWithFrame:CGRectMake(4, 4, PHOTO_WIDTH, PHOTO_HEIGHT)];
    photoView.contentMode = UIViewContentModeScaleAspectFill;
    [photoView setPathToNetworkImage:[URLService  absoluteURL:photo.thumbnailURL] forDisplaySize:CGSizeMake(PHOTO_WIDTH, PHOTO_HEIGHT)];
    [contentView addSubview:photoView];
    [_scrollView addSubview:contentView];
    photoView.userInteractionEnabled = YES;
    UITapGestureRecognizer* photoTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(photoTapped:)];
    [photoView addGestureRecognizer:photoTapGestureRecognizer];
    [_imageViews addObject:photoView];
    [_contentViews addObject:contentView];
}

-(void)addUploadedPhoto:(Photo*)photo withLocalImage:(UIImage*)localImage{
    [self addPhoto:photo atIndex:_contentViews.count];
    [self resetContentSize:_imageViews.count];
    [self layoutSubviews];
}

-(void)deleteUserPhoto:(Photo*)photo atIndex:(NSInteger)index{
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

-(void)addOrRequestTapped:(id)sender{
    [self.delegate addOrRequestPhoto];
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

    [self.delegate didSelectUserPhoto:[_photos objectAtIndex:index] withAllPhotos:allImages atIndex:index];
}

-(void)scrollToRight{
    [_scrollView scrollRectToVisible:[self frameAtIndex:_photos.count] animated:YES];
}
@end
