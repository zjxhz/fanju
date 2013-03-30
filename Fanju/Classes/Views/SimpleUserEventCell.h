//
//  SimpleUserEventCell.h
//  Fanju
//
//  Created by Xu Huanze on 3/30/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NINetworkImageView.h"

@interface SimpleUserEventCell : UITableViewCell
@property(nonatomic, weak) IBOutlet NINetworkImageView* avatar;
@property(nonatomic, weak) IBOutlet UILabel* name;
@property(nonatomic, weak) IBOutlet UILabel* event;
@property(nonatomic, weak) IBOutlet UILabel* topic;
@property(nonatomic, weak) IBOutlet UILabel* time;
@end
