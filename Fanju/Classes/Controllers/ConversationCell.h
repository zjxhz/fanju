//
//  ConversationCell.h
//  Fanju
//
//  Created by Xu Huanze on 5/31/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NINetworkImageView.h"

@interface ConversationCell : UITableViewCell
@property(nonatomic, weak) IBOutlet UILabel* nameLabel;
@property(nonatomic, weak) IBOutlet UILabel* messageLabel;
@property(nonatomic, weak) IBOutlet UILabel* timeLabel;
@property(nonatomic, weak) IBOutlet UILabel* unreadLabel;
@property(nonatomic, weak) IBOutlet NINetworkImageView* avatarView;
@end
