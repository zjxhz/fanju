//
//  UserHeaderCell.h
//  Fanju
//
//  Created by Xu Huanze on 3/24/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UserHeaderCell : UITableViewCell
@property(nonatomic, weak) IBOutlet UILabel* nameLabel;
@property(nonatomic, weak) IBOutlet UIImageView* messageImageView;
@property(nonatomic, weak) IBOutlet UIImageView* notificationImageView;
@property(nonatomic, weak) IBOutlet UILabel* messageLabel;
@property(nonatomic, weak) IBOutlet UILabel* unreadMessageCountLabel;
@property(nonatomic, weak) IBOutlet UILabel* notificationLabel;
@property(nonatomic, weak) IBOutlet UILabel* unreadNotificationLabel;
@property(nonatomic, weak) IBOutlet UIImageView* avatarMaskView;
@property(nonatomic, weak) IBOutlet UIView* avatarContainerView;
@end
