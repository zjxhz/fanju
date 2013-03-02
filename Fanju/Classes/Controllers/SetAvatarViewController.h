//
//  SetAvatarViewController.h
//  EasyOrder
//
//  Created by 浣泽 徐 on 8/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UserProfile.h"
#import "UserImageView.h"
#import "Authentication.h"
@protocol SetAvatarViewControllerDelegate <NSObject>
@optional
-(void)avatarUpdatedForUser:(UserProfile*)user withImage:(UIImage*)image;
@end


@interface SetAvatarViewController : UIViewController<UIImagePickerControllerDelegate, UINavigationControllerDelegate, UserImageViewDelegate, AuthenticationDelegate>
@property id<SetAvatarViewControllerDelegate> delegate;
@property(nonatomic, strong) UserProfile* user;
@property(nonatomic) BOOL isModal;

-(id)initWithUser:(UserProfile*)user;
@end
