//
//  NewSidebarViewController.m
//  EasyOrder
//
//  Created by 浣泽 徐 on 7/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NewSidebarViewController.h"
#import "Three20/Three20.h"
#import "AppDelegate.h"
#import "Authentication.h"
#import "UserMessagesViewController.h"
#import "SVProgressHUD.h"
#import "NameAndGenderViewController.h"
#import "EmailViewController.h"
#import "SettingsTableViewController.h"
#import "MKNumberBadgeView.h"
#import "UIViewController+MFSideMenu.h"
#import "Const.h"
#import "TDBadgedCell.h"

#define SIDEBAR_WIDTH 270
#define SIDEBAR_HEADER_HEIGHT 30

@interface NewSidebarViewController (){
    BOOL _showLoginAfterLeftBarHides;
    NSInteger _unreadMessageCount;
    NSInteger _unreadNotificationCount;
    MKNumberBadgeView* _unreadMsgBadge;
    MKNumberBadgeView* _unreadNotifBadge;
}

@end

@implementation NewSidebarViewController
@synthesize delegate;
@synthesize mealListViewController = _mealListViewController;
@synthesize myMealsViewController = _myMealsViewController;
@synthesize userListViewController = _userListViewController;
@synthesize socialViewController = _socialViewController;
@synthesize userDetailsViewController = _userDetailsViewController;
@synthesize recentContactsViewController = _recentContactsViewController;
@synthesize notificationViewController = _notificationViewController;

+(NewSidebarViewController*) sideBar{
    static NewSidebarViewController* instance;
    if (!instance) {
        instance = [[NewSidebarViewController alloc]  initWithStyle:UITableViewStyleGrouped];
    }
    return instance;    
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        _sections = [NSMutableArray arrayWithObjects:@"饭局", @"找朋友", @"我", @"其它", @"", nil];
        NSMutableArray *sectionItems0 = [NSMutableArray arrayWithObjects:@"当前饭局", @"我的饭局", @"发起饭局", nil];
        NSMutableArray *sectionItems1 = [NSMutableArray arrayWithObjects:@"志趣相投", @"附近朋友", @"添加好友", nil];
        NSMutableArray *sectionItems2 = [NSMutableArray arrayWithObjects:@"我的关注", @"我的粉丝", @"对话", @"我的资料", @"我的账户", nil];
        NSMutableArray *sectionItems3 = [NSMutableArray arrayWithObjects:@"消息", @"设置", @"获取金币", @"饭局小贴士", nil];
        NSMutableArray *sectionItems4 = [NSMutableArray arrayWithObjects:@"登出", nil];
        _sectionItems = [NSMutableArray arrayWithObjects:sectionItems0, sectionItems1, sectionItems2, sectionItems3, sectionItems4, nil];
        self.tableView.dataSource = self;
        self.tableView.delegate = self;
        self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"sidebar_bg.png"]];
        self.tableView.separatorColor = [UIColor blackColor];
         _unreadMsgBadge = [[MKNumberBadgeView alloc] initWithFrame:CGRectMake(180, 10, 40, 25)];
        _unreadNotifBadge = [[MKNumberBadgeView alloc] initWithFrame:CGRectMake(180, 10, 40, 25)];
        _unreadMessageCount =  [[NSUserDefaults standardUserDefaults] integerForKey:UNREAD_MESSAGE_COUNT];
        _unreadNotificationCount = [[NSUserDefaults standardUserDefaults] integerForKey:UNREAD_NOTIFICATION_COUNT];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didLogout:)
                                                     name:EODidLogoutNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(unreadMsgUpdated:)
                                                     name:EOUnreadMessageCount
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(unreadNotifUpdated:)
                                                     name:EOUnreadNotificationCount object:nil];
        
    }
    return self;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


-(MyMealsViewController*) myMealsViewController{
    if (!_myMealsViewController) {
        _myMealsViewController = [[MyMealsViewController alloc] init];
    }
    return _myMealsViewController;
}

-(UserListViewController*) userListViewController{
    if (!_userListViewController) {
        _userListViewController = [[UserListViewController alloc] initWithStyle:UITableViewStylePlain];
        [_userListViewController viewDidLoad];
    }
    return _userListViewController;
}

-(SocialNetworkViewController*)socialViewController{
    if (!_socialViewController) {
        _socialViewController = [[SocialNetworkViewController alloc] init];
    }
    return _socialViewController;
}

-(RecentContactsViewController*)recentContactsViewController{
    if (!_recentContactsViewController) {
        _recentContactsViewController = [[RecentContactsViewController alloc] init];
    }
    return _recentContactsViewController;
}

-(NewUserDetailsViewController*)userDetailsViewController{
    if (!_userDetailsViewController) {
        _userDetailsViewController = [[NewUserDetailsViewController alloc] initWithStyle:UITableViewStylePlain];
    }
    return _userDetailsViewController;
}

-(NotificationViewController*)notificationViewController{
    if (!_notificationViewController) {
        _notificationViewController = [[NotificationViewController alloc] initWithStyle:UITableViewStylePlain];;
    }
    return _notificationViewController;
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    self.view.frame = CGRectMake(0, 0, 260, 460);
}

#pragma mark - Table view data source
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return SIDEBAR_HEADER_HEIGHT;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray* sec = [_sectionItems objectAtIndex:section];
    return sec.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    TDBadgedCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[TDBadgedCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    NSArray* sec = [_sectionItems objectAtIndex:indexPath.section];
    cell.textLabel.text = [sec objectAtIndex:indexPath.row];
    cell.textLabel.font = [UIFont systemFontOfSize:16];
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.selectionStyle  = UITableViewCellSelectionStyleNone;
    cell.backgroundColor = [UIColor clearColor];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.badgeString = nil;
    if (indexPath.section == 2 && indexPath.row == 2) {
        if (_unreadMessageCount > 0) {
            cell.badgeString = [NSString stringWithFormat:@"%d", _unreadMessageCount];
        }
    } else if(indexPath.section == 3 && indexPath.row == 0){
        if (_unreadNotificationCount > 0) {
            cell.badgeString = [NSString stringWithFormat:@"%d", _unreadNotificationCount];
        }
    }
    return cell;
}

#pragma mark - Table view delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return _sections.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    return [_sections objectAtIndex:section];
}

- (void)showMealList{
    [self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
}

- (void)showRegistrationWizard{
    UIViewController *vc = nil;
    UserProfile* currentUser = [Authentication sharedInstance].currentUser;
    if (currentUser.email.length > 0) {
        NameAndGenderViewController *nameAndGender = [[NameAndGenderViewController alloc] initWithStyle:UITableViewStyleGrouped];
        nameAndGender.user = [Authentication sharedInstance].currentUser;
        vc = nameAndGender;
    } else {
        vc = [[EmailViewController alloc] initWithStyle:UITableViewStyleGrouped];
    }
    vc.navigationItem.hidesBackButton = YES;// no way back
    self.sideMenu.navigationController.viewControllers = [NSArray arrayWithObjects:self.mealListViewController, vc, nil];
    [self.sideMenu setMenuState:MFSideMenuStateClosed];
    UIAlertView* a = [[UIAlertView alloc] initWithTitle:@"完善个人信息" message:@"请花1分钟时间提供所需信息以完成注册。" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
    [a show];
    return;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self requireLogin:indexPath]) {
        if (![[Authentication sharedInstance] isLoggedIn]) {
            [self.sideMenu setMenuState:MFSideMenuStateClosed];
            AppDelegate *appDelegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
            dispatch_async(dispatch_get_main_queue(), ^{
                [appDelegate showLogin];
            });
            return;
        }
//        else if(![[Authentication sharedInstance].currentUser hasCompletedRegistration]){
//            [self showRegistrationWizard];
//            return;
//        }
    }
    
    UIViewController *controller;
    switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
                case 0:
                    controller = self.mealListViewController;
                    break;
                case 1:                    
                    controller = self.myMealsViewController;
                    break;
                case 2:
                    break;
                default:
                    break;
            }
            break;
        case 1:
            controller = self.userListViewController;
            switch (indexPath.row) {
                case 0:
                    ((UserListViewController*)controller).baseURL = [NSString stringWithFormat:@"%@://%@/api/v1/user/%d/recommendations/?format=json", HTTPS, EOHOST, [Authentication sharedInstance].currentUser.uID];
                    controller.title = @"志趣相投";
                    break;
                case 1:
                    ((UserListViewController*)controller).baseURL = [NSString stringWithFormat:@"%@://%@/api/v1/user/%d/users_nearby/?format=json", HTTPS, EOHOST, [Authentication sharedInstance].currentUser.uID];
                    controller.title = @"附近朋友";
                    break;
            }
            
            break;
        case 2:
            switch (indexPath.row) {
                case 0:
                    controller = self.socialViewController;
                    controller.title = @"我的关注";
                    break;
                case 1:
                    controller = self.userListViewController;
                    ((UserListViewController*)controller).baseURL = [NSString stringWithFormat:@"%@://%@/api/v1/user/%d/followers/?format=json", HTTPS, EOHOST, [Authentication sharedInstance].currentUser.uID];
                    controller.title = @"我的粉丝";
                    break;
                case 2:                    
                    controller = self.recentContactsViewController;
                    break;
                case 3:
                    controller = self.userDetailsViewController;
                    self.userDetailsViewController.user = [Authentication sharedInstance].currentUser;
                    break;
            }
            break;
        case 3:
            switch (indexPath.row) {
                case 0:
                    controller = self.notificationViewController;
                    _unreadNotificationCount = 0;
                    [[NSNotificationCenter defaultCenter] postNotificationName:EOUnreadNotificationCount
                                                                        object:[NSNumber numberWithInteger:_unreadNotificationCount]
                                                                      userInfo:nil];
                    break;
                case 1:
                    controller = [[SettingsTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
                    break;
            }
            break;
        case 4:
            switch (indexPath.row) {
                case 0:
                    [self.sideMenu setMenuState:MFSideMenuStateClosed];
                    [[Authentication sharedInstance] logout];
                    [SVProgressHUD dismissWithSuccess:@"成功登出"];
                    controller = self.mealListViewController;
                    break;
                default:
                    break;
            }
            break; 
        default:
            [[[UIAlertView alloc] initWithTitle:@"Warning" message:@"Not implemented" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            return;
    }
    self.sideMenu.navigationController.viewControllers = [NSArray arrayWithObject:controller];
    [self.sideMenu.navigationController setToolbarHidden:YES];
    [self.sideMenu setMenuState:MFSideMenuStateClosed];
    if ([[Authentication sharedInstance] isLoggedIn]) {
        [controller setupSideMenuBarButtonItem];
    }
}

-(BOOL)requireLogin:(NSIndexPath*)indexPath{
    if (indexPath.section == 0 && indexPath.row ==0) {
        return NO;
    }
    
    if (indexPath.section == 4 ){
        return NO;
    }

    return YES;
}

-(void)presentModalViewControllerWithNavigationBar:(UIViewController*) viewController{
    UINavigationController *vc = [[UINavigationController alloc] initWithRootViewController:viewController];
    viewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonClicked:)];
    [self.navigationController presentModalViewController:vc animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 40;
}

#pragma mark NSObject
-(NSString*)description{
    return [NSString stringWithFormat:@"class: %@, %@", [self class], [super description]];
}

#pragma mark NSNotificationCenter
- (void)didLogout:(NSNotification*)notif {
    _myMealsViewController = nil;;
    _userListViewController = nil;
    _socialViewController = nil;
    _userDetailsViewController = nil;
    _recentContactsViewController = nil;
}

- (void)unreadMsgUpdated:(NSNotification*)notif {
    _unreadMessageCount = [notif.object integerValue];
    [self.tableView reloadData];
    [[NSUserDefaults standardUserDefaults] setInteger:_unreadMessageCount forKey:UNREAD_MESSAGE_COUNT];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self notifyUnreadCount];
}

- (void)unreadNotifUpdated:(NSNotification*)notif {
    _unreadNotificationCount = [notif.object integerValue];
    [self.tableView reloadData];
    [[NSUserDefaults standardUserDefaults] setInteger:_unreadNotificationCount forKey:UNREAD_NOTIFICATION_COUNT];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self notifyUnreadCount];
}

-(void)notifyUnreadCount{
    [[NSNotificationCenter defaultCenter] postNotificationName:EOUnreadCount
                                                        object:[NSNumber numberWithInteger:_unreadNotificationCount + _unreadMessageCount]
                                                      userInfo:nil];
}

@end
