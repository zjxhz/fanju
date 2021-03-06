//
//  UserDetailsCell.h
//  Fanju
//
//  Created by Xu Huanze on 3/19/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User.h"
#import "NINetworkImageView.h"

@interface UserDetailsCell : UITableViewCell
@property(nonatomic,readonly) CGFloat cellHeight;
-(void) requestNextMeal;
@property(nonatomic, readonly) NINetworkImageView* avatar;
@property(nonatomic, readonly) NINetworkImageView* backgroundImageView;
@property(nonatomic, strong) User* user;
@property(nonatomic, strong) UIImageView* nextMealView;
@property(nonatomic, strong) UIButton* nextMealButton;
@property(nonatomic, strong) Meal* meal;
@end
