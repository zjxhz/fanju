//
//  AvatarFactory.m
//  EasyOrder
//
//  Created by 浣泽 徐 on 6/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AvatarFactory.h"
#import "UserImageView.h"
#import "URLService.h"

@implementation AvatarFactory
+(UserImageView*) avatarForUser:(UserProfile*)user frame:(CGRect)frame delegate:(id<UserImageViewDelegate>)delegate{
    return [self avatarForUser:user frame:frame delegate:delegate withCornerRadius:YES];
}

+(UserImageView*) avatarForUser:(UserProfile*)user frame:(CGRect)frame delegate:(id<UserImageViewDelegate>)delegate withCornerRadius:(BOOL)cornderRadius{
    UserImageView *userImgView = [[UserImageView alloc] initWithFrame:frame];
    userImgView.contentMode = UIViewContentModeScaleAspectFill;
    userImgView.clipsToBounds = YES;
    [userImgView setBackgroundColor:[UIColor clearColor]];
    userImgView.image = [UIImage imageNamed:@"anno.png"];
    [userImgView setContentMode:UIViewContentModeScaleAspectFill];
    if (cornderRadius) {
        userImgView.layer.cornerRadius = 5;
        userImgView.layer.masksToBounds = YES;
    }
    
    if (user){
        [userImgView setPathToNetworkImage:[AvatarFactory bestAvatarUrlForUser:user withFrame:frame] forDisplaySize:frame.size];
        userImgView.user = user;
    }
    
    if(delegate){
        userImgView.tapDelegate = delegate;
    }
    
    return userImgView;
}

+(UserImageView*)avatarWithBg:(User*)user{
    return [AvatarFactory avatarWithBg:user big:NO];
}


+(UserImageView*)avatarWithBg:(User*)user big:(BOOL)big{
    UIImage* bg = nil;
    if (big) {
        bg = [UIImage imageNamed:@"avatar_bg_big"];
    } else {
        bg = [UIImage imageNamed:@"p_photo_bg"];
    }
    UserImageView* view = [[UserImageView alloc] initWithImage:bg];
    CGFloat inset = big ? 5 : 3;
    CGRect avatarFrame = CGRectMake(inset, inset, bg.size.width - inset * 2, bg.size.height - inset * 2);
    NINetworkImageView* avatar = [[NINetworkImageView alloc] initWithFrame:avatarFrame];
    avatar.contentMode = UIViewContentModeScaleAspectFill;
    [avatar setPathToNetworkImage:[URLService absoluteURL:user.avatar]];
    [view addSubview:avatar];
    return  view;
}

+(UserImageView*)guestAvatarWithBg:(BOOL)big{
    UIImage* bg = nil;
    if (big) {
        bg = [UIImage imageNamed:@"avatar_bg_big"];
    } else {
        bg = [UIImage imageNamed:@"p_photo_bg"];
    }
    UserImageView* view = [[UserImageView alloc] initWithImage:bg];
    CGFloat inset = big ? 5 : 3;
    CGRect avatarFrame = CGRectMake(inset, inset, bg.size.width - inset * 2, bg.size.height - inset * 2);
    NINetworkImageView* avatar = [[NINetworkImageView alloc] initWithFrame:avatarFrame];
    avatar.contentMode = UIViewContentModeScaleAspectFill;
//    [avatar setPathToNetworkImage:[URLService absoluteURL:user.avatar]];
    avatar.image = [UIImage imageNamed:@"guest"];
    [view addSubview:avatar];
    return  view;
}


+(UserImageView*) avatarForUser:(UserProfile*)user frame:(CGRect)frame{
    return [AvatarFactory avatarForUser:user frame:frame delegate:nil];
}


+(UserImageView*) defaultAvatarWithFrame:(CGRect)frame{
    return [AvatarFactory avatarForUser:nil frame:frame];
}

+(UserImageView*)avatarForUser:(User*)user withFrame:(CGRect)frame{
    UserImageView *userImgView = [[UserImageView alloc] initWithFrame:frame];
    userImgView.contentMode = UIViewContentModeScaleAspectFill;
    userImgView.clipsToBounds = YES;
    [userImgView setBackgroundColor:[UIColor clearColor]];
    [userImgView setContentMode:UIViewContentModeScaleAspectFill];
    userImgView.layer.cornerRadius = frame.size.width / 12;
    userImgView.layer.masksToBounds = YES;
    
    [userImgView setPathToNetworkImage:[URLService absoluteURL:user.avatar] forDisplaySize:frame.size];
    return userImgView;
}

+(NSString*)bestAvatarUrlForUser:(UserProfile*)user withFrame:(CGRect)frame{
    return [user avatarFullUrl];
}

@end
