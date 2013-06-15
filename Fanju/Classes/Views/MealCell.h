//
//  MealCell.h
//  Fanju
//
//  Created by Xu Huanze on 4/10/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import "Three20/Three20.h"
#import "NINetworkImageView.h"

@interface MealCell : TTTableViewCell<NINetworkImageViewDelegate>
@property(nonatomic, weak) IBOutlet UIImageView* priceBgView;
@property(nonatomic, weak) IBOutlet UILabel* costLabel;
@property(nonatomic, weak) IBOutlet UILabel* addressLabel;
@property(nonatomic, weak) IBOutlet UILabel* topicLabel;
@property(nonatomic, weak) IBOutlet UILabel* timeLabel;
@property(nonatomic, weak) IBOutlet NINetworkImageView* mealView;
@property(nonatomic, strong) UIActivityIndicatorView *activityIndicator;


@end
