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
#import "UserHeaderCell.h"
#import "SideMealCell.h"
#import "SideCell.h"

#define SIDEBAR_HEADER_HEIGHT 22
#define CELL_HEIGHT 44
@interface NewSidebarViewController (){
    BOOL _showLoginAfterLeftBarHides;
    NSInteger _unreadMessageCount;
    MKNumberBadgeView* _unreadMsgBadge;
    MKNumberBadgeView* _unreadNotifBadge;
    UIViewController* _lastViewController;
}

@end

@implementation NewSidebarViewController
@synthesize delegate;
@synthesize mealListViewController = _mealListViewController;
@synthesize myMealsViewController = _myMealsViewController;
@synthesize userListViewController = _userListViewController;
//@synthesize socialViewController = _socialViewController;
@synthesize userDetailsViewController = _userDetailsViewController;
@synthesize notificationViewController = _notificationViewController;
@synthesize conversationViewController = _conversationViewController;

+(NewSidebarViewController*) sideBar{
    static NewSidebarViewController* instance;
    if (!instance) {
        instance = [[NewSidebarViewController alloc]  initWithStyle:UITableViewStylePlain];
    }
    return instance;    
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        _sections = @[@"", @"找朋友", @"其它"];
        NSArray *sectionItems0 = @[@"", @"", @"分享", @"关注"];
        NSArray *sectionItems1 = @[@"志趣相投", @"附近朋友", @"添加好友"];
        NSArray *sectionItems2 = @[ @"设置", @"饭局小贴士", @"登出"];
        _sectionItems = @[sectionItems0, sectionItems1, sectionItems2];
        self.tableView.dataSource = self;
        self.tableView.delegate = self;
        self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"sidebar_bg.png"]];
        self.tableView.separatorColor = [UIColor blackColor];
         _unreadMsgBadge = [[MKNumberBadgeView alloc] initWithFrame:CGRectMake(180, 10, 40, 25)];
        _unreadNotifBadge = [[MKNumberBadgeView alloc] initWithFrame:CGRectMake(180, 10, 40, 25)];
        _unreadMessageCount =  [[NSUserDefaults standardUserDefaults] integerForKey:UNREAD_MESSAGE_COUNT];
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
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(avatarUpdated:) name:AVATAR_UPDATED_NOTIFICATION object:nil];
        self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"side_bg"]];
        
        _header1 = [self createHeaderWithTitle:@"找朋友" image:[UIImage imageNamed:@"side_social"]];
        _header2 = [self createHeaderWithTitle:@"其他" image:[UIImage imageNamed:@"side_other"]];
        
    }
    return self;
}

-(UIView*)createHeaderWithTitle:(NSString*)title image:(UIImage*)image{
    UIImage* headerBg = [UIImage imageNamed:@"side_header_bg"];
    UIImageView* view = [[UIImageView alloc] initWithImage:headerBg];
    UIImageView* iconView = [[UIImageView alloc] initWithFrame:CGRectMake(8, (headerBg.size.height - image.size.height) / 2, image.size.width, image.size.height)];
    iconView.image = image;
    [view addSubview:iconView];
    
    UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(28, 0, 200, headerBg.size.height)];
    label.text = title;
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont systemFontOfSize:12];
    label.layer.shadowColor = RGBACOLOR(0, 0, 0, 0.2).CGColor;
    label.layer.shadowOffset = CGSizeMake(0, -2);
    label.textColor = RGBCOLOR(80, 80, 80);
    [view addSubview:label];
    return view;
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

//-(SocialNetworkViewController*)socialViewController{
//    if (!_socialViewController) {
//        _socialViewController = [[SocialNetworkViewController alloc] init];
//    }
//    return _socialViewController;
//}

-(ConversationViewController*)conversationViewController{
    if (!_conversationViewController) {
        _conversationViewController = [[ConversationViewController alloc] init];
    }
    return _conversationViewController;
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
    self.view.frame = CGRectMake(0, 0, 270, 460);
}

#pragma mark - Table view data source
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if (section == 0) {
        return 0;
    }
    return SIDEBAR_HEADER_HEIGHT;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray* sec = [_sectionItems objectAtIndex:section];
    return sec.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cell;
    UIViewController* temp;
    NSString* CellIdentifier;
    UserProfile* me = [Authentication sharedInstance].currentUser;
    switch (indexPath.section) {
        case 0:
            if(indexPath.row == 0) {
                CellIdentifier = @"UserHeaderCell";
                NINetworkImageView* avatarView = nil;
                if (cell == nil) {
                    temp = [[UIViewController alloc] initWithNibName:CellIdentifier bundle:nil];
                    cell = (UserHeaderCell*)temp.view;
                    UserHeaderCell* headerCell = (UserHeaderCell*)cell;
                    avatarView = [[NINetworkImageView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
                    [headerCell.avatarContainerView insertSubview:avatarView belowSubview:headerCell.avatarMaskView];
                    UIGestureRecognizer *messageTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showMessages)];
                    messageTap.delegate  = self;
                    headerCell.messageImageView.userInteractionEnabled = YES;
                    [headerCell.messageImageView addGestureRecognizer:messageTap];

                    UIGestureRecognizer *notificationTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showNotifications)];
                    notificationTap.delegate  = self;
                    headerCell.notificationImageView.userInteractionEnabled = YES;
                    [headerCell.notificationImageView addGestureRecognizer:notificationTap];
                }
                UserHeaderCell* headerCell = (UserHeaderCell*)cell;
                headerCell.nameLabel.text = me.name;
                UIImage* noNewMessageImageBg = [UIImage imageNamed:@"side_button"];
                UIImage* newMessageAvailableBg = [UIImage imageNamed:@"side_button_new"];
                UIColor* noNewMessageColor = RGBCOLOR(150, 150, 150);
                UIColor* newMessageAvailableColor = [UIColor whiteColor];
                
                if (_unreadMessageCount == 0) {
                    headerCell.messageImageView.image = noNewMessageImageBg;
                    headerCell.messageLabel.textColor = noNewMessageColor;
                    headerCell.unreadMessageCountLabel.textColor = noNewMessageColor;
                } else {
                    headerCell.messageImageView.image = newMessageAvailableBg;
                    headerCell.messageLabel.textColor = newMessageAvailableColor;
                    headerCell.unreadMessageCountLabel.textColor = newMessageAvailableColor;
                }
                NSInteger unreadNotifCount = [XMPPHandler sharedInstance].unreadNotifCount;
                if (unreadNotifCount == 0) {
                    headerCell.notificationImageView.image = noNewMessageImageBg;
                    headerCell.notificationLabel.textColor = noNewMessageColor;
                    headerCell.unreadNotificationLabel.textColor = noNewMessageColor;
                } else {
                    headerCell.notificationImageView.image = newMessageAvailableBg;
                    headerCell.notificationLabel.textColor = newMessageAvailableColor;
                    headerCell.unreadNotificationLabel.textColor = newMessageAvailableColor;
                }
                headerCell.unreadMessageCountLabel.text = [NSString stringWithFormat:@"%d", _unreadMessageCount];
                headerCell.unreadNotificationLabel.text = [NSString stringWithFormat:@"%d", unreadNotifCount];
                [avatarView setPathToNetworkImage:[me avatarFullUrl] forDisplaySize:CGSizeMake(40, 40) contentMode:UIViewContentModeScaleAspectFill];
                return cell;
            } else  if(indexPath.row == 1){
                CellIdentifier = @"SideMealCell";
                SideMealCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
                if (cell == nil) {
                    cell = [[SideMealCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
                    [cell.currentMealsButton addTarget:self action:@selector(showMealList) forControlEvents:UIControlEventTouchUpInside];
                    [cell.myMealsButton addTarget:self action:@selector(showMyMeals) forControlEvents:UIControlEventTouchUpInside];
                }
                return cell;
            }
        default:
            break;
    }
    CellIdentifier = @"SideCell";
    if (cell == nil) {
        cell = [[SideCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];        
        UIImage* separatorImg = [UIImage imageNamed:@"side_separator"];
        UIImageView* separatorView = [[UIImageView alloc] initWithFrame:CGRectMake(0, CELL_HEIGHT - separatorImg.size.height, separatorImg.size.width, separatorImg.size.height)];
        separatorView.image = separatorImg;
        [cell.contentView addSubview:separatorView];
        cell.textLabel.textColor = RGBCOLOR(150, 150, 150);
        cell.textLabel.font = [UIFont systemFontOfSize:16];
        cell.textLabel.shadowColor = RGBACOLOR(0, 0, 0 , 0.4);
        cell.textLabel.shadowOffset = CGSizeMake(0, -2);
        UIImageView* disclosure = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"side_disclosure_gray"]];
        cell.accessoryView = disclosure;
        cell.textLabel.frame = CGRectMake(18, 0, 100, 44);
        UIImageView *bgColorView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"side_selected_bg"]];
        [cell setSelectedBackgroundView:bgColorView];
        cell.textLabel.highlightedTextColor = RGBCOLOR(150, 150, 150);
    }
    
    NSArray* sec = [_sectionItems objectAtIndex:indexPath.section];
    cell.textLabel.text = [sec objectAtIndex:indexPath.row];
//    cell.selectionStyle  = UITableViewCellSelectionStyleNone;
    cell.backgroundColor = [UIColor clearColor];
    return cell;
}

#pragma mark - Table view delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return _sections.count;
}

-(UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    if (section == 1) {
        return _header1;
    } else if (section == 2) {
        return _header2;
    }
    return nil;
    
}
- (void)showMealList{
    [self showViewController:self.mealListViewController];
}

-(void)showMyMeals{
    [self showViewController:self.myMealsViewController];
}

-(void)showMessages{
    [self showViewController:self.conversationViewController];
}

-(void)showNotifications{
    [self showViewController:self.notificationViewController];
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
    
    UIViewController *controller = self.mealListViewController;
    switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
                case 0:
                    controller = self.userDetailsViewController;
                    self.userDetailsViewController.user = [Authentication sharedInstance].currentUser;
                    break;
                case 3:
                    controller = self.userListViewController;
                    ((UserListViewController*)controller).baseURL = [NSString stringWithFormat:@"%@://%@/api/v1/user/%d/following/?format=json", HTTPS, EOHOST, [Authentication sharedInstance].currentUser.uID];
                    controller.title = @"我的关注";
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
                case 2:
                    break;
            }
            
            break;
        case 2:
            switch (indexPath.row) {
                case 0:
                    controller = [[SettingsTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
                    break;
                case 2:
                    [self.sideMenu setMenuState:MFSideMenuStateClosed];
                    [[Authentication sharedInstance] logout];
                    [SVProgressHUD dismissWithSuccess:@"成功登出"];
                    controller = self.mealListViewController;
                    break;
            }
            break;
        default:
            [[[UIAlertView alloc] initWithTitle:@"Warning" message:@"Not implemented" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            break;
    }
    [self showViewController:controller];
}

-(void)showViewController:(UIViewController*)controller{
    if (controller != _lastViewController || self.sideMenu.navigationController.viewControllers.count > 1) {
        [self.sideMenu.navigationController setViewControllers:@[controller] animated:YES];
    }
    if (controller != self.userDetailsViewController) {
        [self.sideMenu.navigationController setToolbarHidden:YES];
    }
    _lastViewController = controller;
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
    switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
                case 0:
                    return 106;
                case 1:
                    return 75;
                default:
                    break;
            }
            break;
            
        default:
            break;
    }
    return 44;
}

#pragma mark NSObject
-(NSString*)description{
    return [NSString stringWithFormat:@"class: %@, %@", [self class], [super description]];
}

#pragma mark NSNotificationCenter
- (void)didLogout:(NSNotification*)notif {
    _myMealsViewController = nil;;
    _userListViewController = nil;
//    _socialViewController = nil;
    _userDetailsViewController = nil;
    _conversationViewController = nil;
}

- (void)unreadMsgUpdated:(NSNotification*)notif {
    _unreadMessageCount = [notif.object integerValue];
    [self.tableView reloadData];
    [[NSUserDefaults standardUserDefaults] setInteger:_unreadMessageCount forKey:UNREAD_MESSAGE_COUNT];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self notifyUnreadCount];
}

- (void)unreadNotifUpdated:(NSNotification*)notif {
    NSInteger unreadNotifCount = [notif.object integerValue];
    if (_lastViewController == self.notificationViewController && self.sideMenu.navigationController.viewControllers.count == 1) {
        //notification view is being displayed
        unreadNotifCount = 0;
        [XMPPHandler sharedInstance].unreadNotifCount = 0;
        [[XMPPHandler sharedInstance] markMessagesReadFrom:PUBSUB_SERVICE];
    } 

    [self.tableView reloadData];
    [[NSUserDefaults standardUserDefaults] setInteger:unreadNotifCount forKey:UNREAD_NOTIFICATION_COUNT];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self notifyUnreadCount];
}

-(void)notifyUnreadCount{
    [[NSNotificationCenter defaultCenter] postNotificationName:EOUnreadCount
                                                        object:[NSNumber numberWithInteger:[XMPPHandler sharedInstance].unreadNotifCount + _unreadMessageCount]
                                                      userInfo:nil];
}

#pragma mark UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    return YES;
}

-(void)avatarUpdated:(NSNotification*)notif {
    [self.tableView reloadData];
}

@end
