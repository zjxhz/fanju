//
//  UserDetailsCell.h
//  Fanju
//
//  Created by Xu Huanze on 3/19/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UserProfile.h"
#import "NINetworkImageView.h"

@interface UserDetailsCell : UITableViewCell
- (id)initWithUser:(UserProfile*)user;
@property(nonatomic,readonly) CGFloat cellHeight;
-(void) requestNextMeal;
@property(nonatomic, readonly) NINetworkImageView* avatar;
@end
