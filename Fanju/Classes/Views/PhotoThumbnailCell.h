//
//  PhotoThumbnailCell.h
//  EasyOrder
//
//  Created by 浣泽 徐 on 9/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UserImageView.h"
#import "User.h"
#import "Photo.h"

@protocol PhotoThumbnailCellDelegate
@optional
-(void) addOrRequestPhoto;
-(void) didSelectUserPhoto:(Photo*)userPhoto atIndex:(NSInteger)index;
@end

@interface PhotoThumbnailCell : UITableViewCell
@property(nonatomic, weak) id<PhotoThumbnailCellDelegate> delegate;
@property(nonatomic, weak) User* user;
@property(nonatomic, readonly) UIButton *addOrRequestPhotoButton;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier withUser:(User*)user editable:(BOOL)editable;
-(void)addUploadedPhoto:(Photo*)photo withLocalImage:(UIImage*)localImage;
-(void)deleteUserPhoto:(Photo*)photo atIndex:(NSInteger)index;
-(void)scrollToRight;
@end
