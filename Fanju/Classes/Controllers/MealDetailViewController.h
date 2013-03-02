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
#import "CreateOrderViewController.h"
#import "AvatarFactory.h"
#import "MealMenu.h"
#import "MenuTableViewController.h"
#import "ClosablePopoverViewController.h"
#import "SinaWeibo.h"
#import "WBSendView.h"
#import "MealDetailsViewDelegate.h"

#define MAP_HEIGHT 175
#define TAB_BAR_HEIGHT 44
#define HOST_VIEW_HEIGHT 58
#define DISH_VIEW_HEIGHT 320
#define DISH_VIEW_WIDTH 320
#define H_GAP 8
#define V_GAP 8
#define SMALL_LABEL_HEIGHT 18
#define DETAILS_CONTENT_VIEW_WIDTH (320 - H_GAP*2)
#define DETAILS_VIEW_HEIGHT 250
#define TOPIC_WIDTH 250
#define TOPIC_HEIGHT 25
#define MENU_BUTTON_X 255
#define MENU_BUTTON_WIDTH 55
#define MENU_BUTTON_HEIGH 22
#define MAP_BUTTON_X MENU_BUTTON_X
#define SECOND_COLUMN_X 35
#define NUMBER_OF_CHARS_IN_ONE_LINE 20
#define MAP_WIDTH 290
#define PARTICIPANTS_HEIGHT 30

@interface MealDetailViewController : TTTableViewController <MKMapViewDelegate, ShareToDelegate, SinaWeiboDelegate, WBSendViewDelegate, CreateOrderDelegate, UserImageViewDelegate>{
    UIView *_detailsView;
    UIView *_detailsContentView;
    UIButton *_mapButton;
    MKMapView *_map;
    UILabel *_introduction;
    UILabel *_numberOfPersons;
    UIView *_participants;
    Location *_location;
    UILabel* _loadingOrNoCommentsLabel;
    UIView* _normalTabBar;
//    UIView* _tabView;
//    UIButton *_shareButton;
    MealMenu* _mealMenu;
    UIButton *_joinButton;
    UIButton *_likeButton;
    NSInteger _numberOfLikedPerson;
    BOOL _initiallyLiked;
    BOOL _like;
    ShareTableViewController *_shareContentViewController;
    MenuTableViewController *_menuContentViewController;
    WEPopoverController *_sharePopOver;
    WEPopoverController *_menuPopover;
    SinaWeibo *_wb;
    ClosablePopoverViewController *_cpc;
}

@property (nonatomic, strong) MealInfo *mealInfo;
@property (nonatomic, readonly)  UIView* tabBar;

@end
