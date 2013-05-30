//
//  EditUserDetailsHeaderView.h
//  Fanju
//
//  Created by Xu Huanze on 5/22/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NINetworkImageView.h"

@interface EditUserDetailsHeaderView : UIView
@property(nonatomic, weak) IBOutlet UIButton* editPersonalBgButton;
@property(nonatomic, weak) IBOutlet NINetworkImageView* avatarView;
@property(nonatomic, weak) IBOutlet NINetworkImageView* personalBgView;
@end
