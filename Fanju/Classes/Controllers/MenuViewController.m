//
//  MenuViewController.m
//  EasyOrder
//
//  Created by igneus on 12/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MenuViewController.h"
#import "AppDelegate.h"
#import "MenuCoverView.h"
#import "LeftSideBarView.h"
#import "MenuUpdater.h"
#import "OrderManager.h"
#import "MenuTableView.h"
#import "OrderListView.h"
#import "DishDisplayViewController.h"
#import "Const.h"
#import "ActivationViewController.h"

@interface MenuViewController()
@property (nonatomic, strong) UIView *rightView;
@property (nonatomic, strong) NSString *restaurant;
@property (nonatomic, strong) LeftSideBarView *leftBar;
@property (nonatomic, strong) MenuCoverView *cover;
@property (nonatomic, strong) MenuTableView *menuTable;
@property (nonatomic, strong) OrderListView *orderList;
@end

@implementation MenuViewController

@synthesize menuTable = _menuTable, rightView = _rightView, restaurant = _restaurant;
@synthesize leftBar = _leftBar;
@synthesize cover = _cover;
@synthesize restaurantID = _restaurantID;
@synthesize orderList = _orderList;

- (void)loadView {
    [super loadView];
    
    [self.navigationController setNavigationBarHidden:YES];
}

- (void)showOrderList {
    if (!self.orderList) {
        self.orderList = [[OrderListView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width - 10, self.view.frame.size.height - 8)];
        [self.orderList setAlpha:0];
        [self.orderList performedDismissOrderList:^{
            [UIView animateWithDuration:0.5
                                  delay:0
                                options:UIViewAnimationOptionCurveEaseIn 
                             animations:^(){
                                 self.orderList.center = CGPointMake(self.view.frame.size.width / 2, - self.view.frame.size.height);
                                 [self.orderList setAlpha:0];
                             }
                             completion:^(BOOL finished) {
                                 [self.leftBar setUserInteractionEnabled:YES];
                                 [self.menuTable setUserInteractionEnabled:YES];
                             }];
        }];
        [self.view addSubview:self.orderList];
    }
    self.orderList.center = CGPointMake(self.view.frame.size.width / 2, - self.view.frame.size.height);
    [self.view bringSubviewToFront:self.orderList];
    
    [UIView animateWithDuration:0.5
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut 
                     animations:^(){
                         self.orderList.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2);
                         [self.orderList setAlpha:1];
                     }
                     completion:^(BOOL finished) {
                         [self.orderList showView];
                         [self.leftBar setUserInteractionEnabled:NO];
                         [self.menuTable setUserInteractionEnabled:NO];
                     }];
}

- (void)didLogin:(NSNotification*)notif {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:EODidLoginNotification
                                                  object:nil];
    
    [self showOrderList];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGRect appFrame = [UIScreen mainScreen].applicationFrame;
    [self.view setFrame:appFrame];
    
    self.leftBar = [[LeftSideBarView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    [self.leftBar setCategoryToggleAction:[^{
        [self.menuTable toggleMenuTable];
    } copy]];
    [self.leftBar setDismissedAction:[^{
        [self dismissModalViewControllerAnimated:YES];
    } copy]];
    [self.leftBar setDisplayOrderAction:[^(){
        if (![[Authentication sharedInstance] isLoggedIn]) {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(didLogin:) 
                                                         name:EODidLoginNotification
                                                       object:nil];
            
            AppDelegate *delegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
            [delegate showLogin];
        } else {
            [self showOrderList];
        }
    } copy]];
    [self.leftBar setCategorySelectAction:[^(Category *category) {
        [self.menuTable categorySelected:category];
    } copy]];
    [self.leftBar setDisplayChangeAction:[^(int mode) {
        [self.menuTable setDisplayMode:mode];
    } copy]];
    [self.view addSubview:self.leftBar];
    
    self.menuTable = [[MenuTableView alloc] initWithFrame:CGRectMake(0, 44, self.view.frame.size.width, self.view.frame.size.height - 44)];
    [self.menuTable setTablePanAction:[^(){
        [self.leftBar setToggleCategory];
    } copy]];
    [self.menuTable setDishSelectAction:[^(int index) {
        DishDisplayViewController *dishDisplay = [[DishDisplayViewController alloc] initWithDishes:self.menuTable.array
                                                                                           atIndex:index];
        dishDisplay.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        [self presentModalViewController:dishDisplay animated:YES];
    } copy]];
    [self.view addSubview:self.menuTable];
    
    self.cover = [[MenuCoverView alloc] init];
    [self.view addSubview:self.cover];
    
    MenuUpdater *updater = [[MenuUpdater alloc] init];
    [updater updateMenu:self.restaurantID];
    
    [[OrderManager sharedManager] newOrder:self.restaurantID];
}

- (id)initWithRestaurant:(NSString*)restaurant {
    if (self = [super init]) {
        self.restaurant = restaurant;
        self.restaurantID = 25;
    }
    
    return self;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
