//
//  SendCommentViewController.h
//  Fanju
//
//  Created by Xu Huanze on 7/26/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MealComment.h"
#import "Meal.h"

@protocol SendCommentDelegate
-(void)didSendComment:(MealComment*)comment;
-(void)didFailSendComment;
@end

@interface SendCommentViewController : UIViewController
@property(nonatomic, strong) MealComment* parentComment;
@property(nonatomic, strong) Meal* meal;
@property(nonatomic, weak) id<SendCommentDelegate> sendCommentDelegate;
@end
