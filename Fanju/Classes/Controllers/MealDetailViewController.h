//
//  MealDetailViewController.h
//  EasyOrder
//
//  Created by igneus on 3/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MealInfo.h"
#import <Three20/Three20.h>
#import <MapKit/MapKit.h>
#import "Location.h"
#import "ShareTableViewController.h"
#import "WEPopoverController.h"
#import "AvatarFactory.h"
#import "MealMenu.h"
#import "MenuTableViewController.h"
#import "ClosablePopoverViewController.h"
#import "SinaWeibo.h"
#import "WBSendView.h"
#import "MealDetailsViewDelegate.h"
#import "OrderInfo.h"
#import "MenuViewController.h"
#import "Meal.h"

#define MAP_HEIGHT 175
#define TAB_BAR_HEIGHT 49


#define DETAILS_CONTENT_VIEW_WIDTH (320 - H_GAP*2)



#define MENU_BUTTON_X 255
#define MENU_BUTTON_WIDTH 55
#define MENU_BUTTON_HEIGH 22
#define MAP_BUTTON_X MENU_BUTTON_X
#define SECOND_COLUMN_X 35
#define NUMBER_OF_CHARS_IN_ONE_LINE 20
#define MAP_WIDTH 290
#define DETAILS_VIEW_HEIGHT 250

@interface MealDetailViewController : TTTableViewController <MKMapViewDelegate, ShareToDelegate, SinaWeiboDelegate, WBSendViewDelegate, UserImageViewDelegate>{
    UIView *_detailsView;
    UIButton* _mapButton;
    UILabel *_introduction;
    Location *_location;
    UILabel* _loadingOrNoCommentsLabel;
    UIView* _normalTabBar;
    UIButton *_joinButton;
    BOOL _initiallyLiked;
    BOOL _like;
    ShareTableViewController *_shareContentViewController;
    WEPopoverController *_sharePopOver;
    WEPopoverController *_menuPopover;
    SinaWeibo *_wb;
    ClosablePopoverViewController *_cpc;
}
@property(nonatomic, strong) NSString* mealID;
@property (nonatomic, strong) Meal *meal;
@property (nonatomic, readonly)  UIView* tabBar;
@property (nonatomic, strong) Order* unfinishedOrder;

@end
