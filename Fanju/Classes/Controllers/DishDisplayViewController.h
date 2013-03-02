//
//  DishDisplayViewController.h
//  EasyOrder
//
//  Created by igneus on 1/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Three20/Three20.h>

@interface DishDisplayViewController : TTViewController <TTScrollViewDataSource, TTScrollViewDelegate> 
- (id)initWithDishes:(NSArray*)dishes atIndex:(int)index;
@end
