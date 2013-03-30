//
//  NewSidebarViewController.h
//  EasyOrder
//
//  Created by 浣泽 徐 on 7/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MealListViewController.h"
#import "MyMealsViewController.h"
#import "UserListViewController.h"
#import "SocialNetworkViewController.h"
#import "RecentContactsViewController.h"
#import "NewUserDetailsViewController.h"
#import "NotificationViewController.h"
#import "MFSideMenu.h"

@interface NewSidebarViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate>{
    NSArray *_sections;
    NSArray *_sectionItems;
    UIView* _header1;
    UIView* _header2;
}
@property(nonatomic, strong) MFSideMenu* sideMenu;
@property(nonatomic, weak) id delegate;
@property(nonatomic, strong) MealListViewController* mealListViewController;
@property(nonatomic, readonly) MyMealsViewController* myMealsViewController;
@property(nonatomic, readonly) UserListViewController* userListViewController;
//@property(nonatomic, readonly) SocialNetworkViewController* socialViewController;
@property(nonatomic, readonly) RecentContactsViewController* recentContactsViewController;
@property(nonatomic, readonly) NewUserDetailsViewController* userDetailsViewController;
@property(nonatomic, readonly) NotificationViewController* notificationViewController;

+(NewSidebarViewController*) sideBar;
- (void)showMealList;
- (void)showRegistrationWizard;
@end

@protocol SidebarViewControllerDelegate
@optional
-(void)sidebarController:(NewSidebarViewController*)controller didSelectRow:(NSInteger)row;
@end

