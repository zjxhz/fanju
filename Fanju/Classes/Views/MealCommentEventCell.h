//
//  MealCommentEventCell.h
//  Fanju
//
//  Created by Xu Huanze on 7/31/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NINetworkImageView.h"
#import "SimpleUserEventCell.h"

@interface MealCommentEventCell : SimpleUserEventCell
@property(nonatomic, weak) IBOutlet UILabel* comment;
@property(nonatomic, weak) IBOutlet UIImageView* mealImgBg;
@property(nonatomic, weak) IBOutlet NINetworkImageView* mealImage;
@end
