//
//  UserImageView.h
//  EasyOrder
//
//  Created by 浣泽 徐 on 7/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Three20/Three20.h"
#import "UserProfile.h"
#import "NINetworkImageView.h"

@protocol UserImageViewDelegate <NSObject>

@optional
-(void)userImageTapped:(UserProfile*)user;

@end

@interface UserImageView : NINetworkImageView
@property (nonatomic, strong) UserProfile* user;
@property (nonatomic, weak) id<UserImageViewDelegate> tapDelegate;


@end
