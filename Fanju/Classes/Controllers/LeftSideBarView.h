//
//  LeftSideBarView.h
//  EasyOrder
//
//  Created by igneus on 12/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Three20/Three20.h>

@class Category;

typedef void (^DismissActionBlock)(void);
typedef void (^CategoryToggleActionBlock)(void);
typedef void (^DisplayOrderListBlock)(void);
typedef void (^CategorySelectedBlock)(Category*);
typedef void (^DisplayModeChangedBlock)(int);

@interface LeftSideBarView : UIView <TTTabDelegate> 
@property (nonatomic, strong) DismissActionBlock dismissedAction;
@property (nonatomic, strong) CategoryToggleActionBlock categoryToggleAction;
@property (nonatomic, strong) DisplayOrderListBlock displayOrderAction;
@property (nonatomic, strong) CategorySelectedBlock categorySelectAction;
@property (nonatomic, strong) DisplayModeChangedBlock displayChangeAction;

- (void)setToggleCategory;

@end
