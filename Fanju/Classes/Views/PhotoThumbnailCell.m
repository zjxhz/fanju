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

#define H_GAP 5
#define V_GAP 10
#define MAX_VISIBLE_PHOTO_COUNT 8
#define MAX_PHOTO_IN_A_ROW 4
#define SIDE_LENGTH 75
@interface PhotoThumbnailCell(){
    BOOL _editable;
    UIImageView *_addPhotoImageView;
    NSMutableArray* _imageViews;
    UITapGestureRecognizer* _photoTapGestureRecognizer;
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
    for(TTImageView *imgView in _imageViews){
        [imgView removeFromSuperview];
    }
    [_addPhotoImageView removeFromSuperview];
    [self buildUI];
}

-(void)buildUI{
    _imageViews = [NSMutableArray array];
    NSArray* urls = [_user avatarAndPhotoThumbnailFullUrls];
    for (int i = 0; i < urls.count && i < MAX_VISIBLE_PHOTO_COUNT; ++i) {
        NSString* photoURL = [urls objectAtIndex:i];
        CGRect frame = [self frameAtIndex:i];
        NINetworkImageView* imageView = [[NINetworkImageView alloc] initWithFrame:frame];
        [_imageViews addObject:imageView];
        imageView.userInteractionEnabled = YES;
        UITapGestureRecognizer* photoTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(photoTapped:)];
        [imageView addGestureRecognizer:photoTapGestureRecognizer];
        imageView.initialImage = [UIImage imageNamed:@"anno.png"];
        [imageView setPathToNetworkImage:photoURL forDisplaySize:frame.size contentMode:UIViewContentModeScaleAspectFill];
        [self.contentView addSubview:imageView];
    }

    [self createAddPhotoButtonIfNeeded];
}

-(void)createAddPhotoButtonIfNeeded{
    if (_imageViews.count < MAX_VISIBLE_PHOTO_COUNT && _editable) {
        _addPhotoImageView = [[UIImageView alloc] initWithFrame:[self frameAtIndex:_imageViews.count]];
        _addPhotoImageView.image = [UIImage imageNamed:@"add"];
        _addPhotoImageView.userInteractionEnabled = YES;
        [self.contentView addSubview:_addPhotoImageView];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(addTapped:)];
        [_addPhotoImageView addGestureRecognizer:tap];
    }
}
-(void)addUploadedPhoto:(UserPhoto*)photo withLocalImage:(UIImage*)localImage{
    NSInteger nextIndex = _imageViews.count;
    if (nextIndex >= MAX_VISIBLE_PHOTO_COUNT) {
        return;
    }
    CGRect frame = [self frameAtIndex:nextIndex];
    NINetworkImageView *uploadedImageView = [[NINetworkImageView alloc] initWithFrame:frame];
    [_imageViews addObject:uploadedImageView];
    uploadedImageView.initialImage = localImage;
    [uploadedImageView setPathToNetworkImage:[photo fullUrl] forDisplaySize:frame.size contentMode:UIViewContentModeScaleAspectFill];
    uploadedImageView.userInteractionEnabled = YES;
    UITapGestureRecognizer* photoTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(photoTapped:)];
    
    [uploadedImageView addGestureRecognizer:photoTapGestureRecognizer];
    [self.contentView addSubview:uploadedImageView];
    
    if (++nextIndex < MAX_VISIBLE_PHOTO_COUNT && _editable) {
        _addPhotoImageView.frame = [self frameAtIndex:nextIndex];
    }
    [self layoutSubviews];
}

-(void)deleteUserPhoto:(UserPhoto*)photo atIndex:(NSInteger)index{
    if (!_addPhotoImageView) {
        [self createAddPhotoButtonIfNeeded];//it might have been removed while there are full of photos
    }
    NINetworkImageView *toBeRemoved = [_imageViews objectAtIndex:index + 1]; //+1 as the first one is avatar
    [toBeRemoved removeFromSuperview];
    [_imageViews removeObject:toBeRemoved];;
    
    if (toBeRemoved) {
        [toBeRemoved removeFromSuperview];
        [_imageViews removeObject:toBeRemoved];
    }
    
    if (_imageViews.count < MAX_VISIBLE_PHOTO_COUNT && _editable) {
        _addPhotoImageView.frame = [self frameAtIndex:_imageViews.count];
    }
    

}

-(void)changeAvatar:(NSString*)avatarFullUrl withLocalImage:(UIImage *)localImage{
    NINetworkImageView* avatarImageView = [_imageViews objectAtIndex:0];
    avatarImageView.initialImage = localImage;
    [avatarImageView setPathToNetworkImage:avatarFullUrl];
}
-(CGRect)frameAtIndex:(NSInteger)index{
    int x,y;
    if (index >= MAX_PHOTO_IN_A_ROW) {
        y = V_GAP + SIDE_LENGTH + V_GAP;
        x = H_GAP + (H_GAP + SIDE_LENGTH) * (index - MAX_PHOTO_IN_A_ROW);
    } else {
        x = H_GAP + (H_GAP + SIDE_LENGTH) * index;
        y = V_GAP;
    }
    return CGRectMake(x, y, SIDE_LENGTH, SIDE_LENGTH);
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

    if (index == 0) {
        [self.delegate didSelectAvatar:[allImages objectAtIndex:0] withAllPhotos:allImages atIndex:index];
    } else {
        [self.delegate didSelectUserPhoto:[_user.photos objectAtIndex:index - 1] withAllPhotos:allImages atIndex:index];
    }
}

-(NSInteger)numberOfRows{
    int photoCount = _imageViews.count + (_editable ? 1 : 0);
    if (photoCount > 8) {
        return 2; //maximal 2 rows
    }
    if (photoCount % 4 == 0) {
        return photoCount / 4;
    } else {
        return photoCount / 4 + 1;
    }
}
@end
