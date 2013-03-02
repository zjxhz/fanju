//
//  PhotoThumbnailCell.h
//  EasyOrder
//
//  Created by 浣泽 徐 on 9/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UserImageView.h"

@protocol PhotoThumbnailCellDelegate
@optional
-(void) didSelectAddPhoto;
-(void) didSelectUserPhotos:(NSArray*)allPhotos  withIndex:(NSInteger)index;
-(void) didSelectAvatar:(UIImage*)avatarImage withAllPhotos:(NSArray*)allPhotos atIndex:(NSInteger)index;
-(void) didSelectUserPhoto:(UserPhoto*)userPhoto withAllPhotos:(NSArray*)allPhotos atIndex:(NSInteger)index;
@end

@interface PhotoThumbnailCell : UITableViewCell
@property(nonatomic, weak) id<PhotoThumbnailCellDelegate> delegate;
@property(nonatomic, weak) UserProfile* user;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier withUser:(UserProfile*)user editable:(BOOL)editable;
-(void)addUploadedPhoto:(UserPhoto*)photo withLocalImage:(UIImage*)localImage;
-(void)deleteUserPhoto:(UserPhoto*)photo atIndex:(NSInteger)index;
-(void)changeAvatar:(NSString*)avatarFullUrl withLocalImage:(UIImage*)localImage;
-(NSInteger)numberOfRows;
@end
