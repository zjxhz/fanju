//
//  AvatarFactory.m
//  EasyOrder
//
//  Created by 浣泽 徐 on 6/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AvatarFactory.h"
#import "UserImageView.h"

@implementation AvatarFactory
+(UserImageView*) avatarForUser:(UserProfile*)user frame:(CGRect)frame delegate:(id<UserImageViewDelegate>)delegate{
    UserImageView *userImgView = [[UserImageView alloc] initWithFrame:frame];
    userImgView.contentMode = UIViewContentModeScaleAspectFill;
    userImgView.clipsToBounds = YES;
    [userImgView setBackgroundColor:[UIColor clearColor]];
    userImgView.image = [UIImage imageNamed:@"anno.png"];
    [userImgView setContentMode:UIViewContentModeScaleAspectFill];
    userImgView.layer.cornerRadius = 9;
    userImgView.layer.masksToBounds = YES;

    if (user){
        [userImgView setPathToNetworkImage:[AvatarFactory bestAvatarUrlForUser:user withFrame:frame] forDisplaySize:frame.size];
        userImgView.user = user;
    }
    
    if(delegate){
        userImgView.tapDelegate = delegate;
    }
    
    return userImgView;
}

+(UserImageView*) avatarForUser:(UserProfile*)user frame:(CGRect)frame{
    return [AvatarFactory avatarForUser:user frame:frame delegate:nil];
}


+(UserImageView*) defaultAvatarWithFrame:(CGRect)frame{
    return [AvatarFactory avatarForUser:nil frame:frame];
}

+(NSString*)bestAvatarUrlForUser:(UserProfile*)user withFrame:(CGRect)frame{
    if (frame.size.width < 100) {
        return [user smallAvatarFullUrl];
    } else {
        return [user avatarFullUrl];
    }
}

@end
