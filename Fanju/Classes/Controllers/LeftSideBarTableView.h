//
//  LeftSideBarTableView.h
//  EasyOrder
//
//  Created by igneus on 12/15/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Category+Query.h"
#import "ShadowedTableView.h"

typedef void (^CategorySelected)(Category*);

@interface LeftSideBarTableView : ShadowedTableView 

@property (nonatomic, strong) CategorySelected categorySelectAction;


- (id)initWithFrame:(CGRect)frame;
- (void)clearTableSelection;
@end
