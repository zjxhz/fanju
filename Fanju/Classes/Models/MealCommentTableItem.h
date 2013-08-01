//
//  MealCommentTableItem.h
//  Fanju
//
//  Created by Xu Huanze on 7/23/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import "TTTableViewItem.h"
#import "MealComment.h"

@interface MealCommentTableItem : TTTableViewItem
@property(nonatomic, strong) MealComment* mealComment;
@property(nonatomic, strong) MealComment* replies;
@end
