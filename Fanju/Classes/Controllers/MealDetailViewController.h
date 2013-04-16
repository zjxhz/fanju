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

#define MAP_HEIGHT 175
#define TAB_BAR_HEIGHT 49
#define HOST_VIEW_HEIGHT 58
#define DISH_VIEW_HEIGHT 140
#define DISH_VIEW_WIDTH 320
#define H_GAP 7
#define V_GAP 13
#define DETAILS_CONTENT_VIEW_WIDTH (320 - H_GAP*2)
#define DETAILS_VIEW_HEIGHT 250
#define INTRO_WIDTH 250
#define INTRO_HEIGHT 48
#define ADDRESS_WIDTH 210
#define ADDRESS_HEIGHT 24
#define NUM_OF_PERSONS_WIDTH INTRO_WIDTH
#define NUM_OF_PERSONS_HEIGHT 12
#define MENU_BUTTON_X 255
#define MENU_BUTTON_WIDTH 55
#define MENU_BUTTON_HEIGH 22
#define MAP_BUTTON_X MENU_BUTTON_X
#define SECOND_COLUMN_X 35
#define NUMBER_OF_CHARS_IN_ONE_LINE 20
#define MAP_WIDTH 290
#define PARTICIPANTS_WIDTH 53
#define PARTICIPANTS_HEIGHT PARTICIPANTS_WIDTH
#define PARTICIPANTS_GAP 2
#define JOIN_BUTTON_X 36.5
@interface MealDetailViewController : TTTableViewController <MKMapViewDelegate, ShareToDelegate, SinaWeiboDelegate, WBSendViewDelegate, CreateOrderDelegate, UserImageViewDelegate>{
    UIView *_detailsView;
    UIButton* _mapButton;
    UILabel *_introduction;
    UILabel *_numberOfPersons;
    UIScrollView *_participants;
    Location *_location;
    UILabel* _loadingOrNoCommentsLabel;
    UIView* _normalTabBar;
    MealMenu* _mealMenu;
    UIButton *_joinButton;
    BOOL _initiallyLiked;
    BOOL _like;
    ShareTableViewController *_shareContentViewController;
    MenuTableViewController *_menuContentViewController;
    WEPopoverController *_sharePopOver;
    WEPopoverController *_menuPopover;
    SinaWeibo *_wb;
    ClosablePopoverViewController *_cpc;
}
@property(nonatomic, strong) NSString* mealID;
@property (nonatomic, strong) MealInfo *mealInfo;
@property (nonatomic, readonly)  UIView* tabBar;

@end
