//
//  AvatarFactory.h
//  EasyOrder
//
//  Created by 浣泽 徐 on 6/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Three20/Three20.h>
#import "UserProfile.h"
#import "User.h"
#import "Const.h"
#import "UserImageView.h"
typedef enum {
    DEFAULT, SMALL, MEDIUM, LARGE
}
AvatarSize;

@interface AvatarFactory : NSObject

+(UserImageView*) avatarForUser:(UserProfile*)user frame:(CGRect)frame delegate:(id<UserImageViewDelegate>)delegate withCornerRadius:(BOOL)cornderRadius;
+(UserImageView*) avatarForUser:(UserProfile*)user frame:(CGRect)frame delegate:(id<UserImageViewDelegate>)delegate;
+(UserImageView*) avatarForUser:(UserProfile*)user frame:(CGRect)frame;
+(UserImageView*) defaultAvatarWithFrame:(CGRect)frame;
+(UserImageView*)avatarWithBg:(User*)user;
+(UserImageView*)avatarWithBg:(User*)user big:(BOOL)big;
+(UserImageView*)avatarForUser:(User*)user withFrame:(CGRect)frame;
+(UserImageView*)guestAvatarWithBg:(BOOL)big;
@end
