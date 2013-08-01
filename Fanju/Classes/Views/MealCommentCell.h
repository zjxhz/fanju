//
//  MealCommentCell.h
//  Fanju
//
//  Created by Xu Huanze on 7/23/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import "TTTableViewCell.h"
#import "NINetworkImageView.h"
#import "MealCommentTableItem.h"
#import "MealDetailViewController.h"

@interface MealCommentCell : TTTableViewCell
//@property(nonatomic, strong) MealCommentTableItem* commentItem;
@property(nonatomic, strong) MealComment* mealComment;
@property(nonatomic, weak) IBOutlet NINetworkImageView* avatar;
@property(nonatomic, weak) IBOutlet UILabel* nameLabel;
@property(nonatomic, weak) IBOutlet UILabel* commentLabel;
@property(nonatomic, weak) IBOutlet UILabel* timeLabel;
@property(nonatomic, weak) IBOutlet UIImageView* replyImageView;
@property(nonatomic, strong) MealDetailViewController* parentController;
@end
