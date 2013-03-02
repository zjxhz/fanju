//
//  UserDetailViewController.h
//  EasyOrder
//
//  Created by igneus on 3/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UserProfile.h"
#import <Three20/Three20.h>

@protocol UserDetailViewControllerDelegate <NSObject>

@optional
-(void)userFollowed:(UserProfile*)user;
-(void)userUnfollowed:(UserProfile*)user;

@end


@interface UserDetailViewController : TTTableViewController 

@property (nonatomic, weak) UserProfile *profile;
@property (nonatomic, weak) id<UserDetailViewControllerDelegate> delegate;

@end
