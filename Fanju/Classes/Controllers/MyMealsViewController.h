//
//  MyMealsViewController.h
//  EasyOrder
//
//  Created by 浣泽 徐 on 4/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Three20/Three20.h>
#import "LoadMoreTableItem.h"

//#define COLOR_BUTTON_DOWN RGBCOLOR(0x95, 0xBC, 0xF2)
//#define COLOR_BUTTON_UP  [UIColor whiteColor]

@interface MyMealsViewController : TTTableViewController <UITableViewDelegate>{
    LoadMoreTableItem *_loadMore;
}

@end
