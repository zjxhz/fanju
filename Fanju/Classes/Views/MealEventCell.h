//
//  MealEventCell.h
//  Fanju
//
//  Created by Xu Huanze on 3/29/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NINetworkImageview.h"
#import "SimpleUserEventCell.h"

@interface MealEventCell : SimpleUserEventCell
@property(nonatomic, weak) IBOutlet UILabel* topic;
@property(nonatomic, weak) IBOutlet UIImageView* mealImgBg;
@property(nonatomic, weak) IBOutlet NINetworkImageView* mealImage;
@end
