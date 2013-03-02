//
//  MenuViewController.h
//  EasyOrder
//
//  Created by igneus on 12/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Three20/Three20.h>

#define LEFT_SIDEBAR_WIDTH 254.5
#define BOUNCE_LEFT_X LEFT_SIDEBAR_WIDTH / 2

@interface MenuViewController : TTViewController

@property (nonatomic) int restaurantID;

- (id)initWithRestaurant:(NSString*)restaurant;

@end
