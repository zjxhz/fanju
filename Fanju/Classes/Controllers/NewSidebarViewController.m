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
#import "SearchUserViewController.h"
#import "SVWebViewController.h"

#define SIDEBAR_HEADER_HEIGHT 22
#define CELL_HEIGHT 44
@interface NewSidebarViewController (){
    BOOL _showLoginAfterLeftBarHides;
    NSInteger _unreadMessageCount;
    MKNumberBadgeView* _unreadMsgBadge;
    MKNumberBadgeView* _unreadNotifBadge;
    UIViewController* _lastViewController;
    BOOL _avatarLoaded;
}

@end

@implementation NewSidebarViewController
@synthesize delegate;
@synthesize mealListViewController = _mealListViewController;
@synthesize myMealsViewController = _myMealsViewController;
//@synthesize userListViewController = _userListViewController;
@synthesize followingsViewController = _followingsViewController;
@synthesize usersNearbyViewController = _usersNearbyViewController;
@synthesize similarUsersViewController = _similarUsersViewController;
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
        NSArray *sectionItems0 = @[@"", @"", @"关注"];
        NSArray *sectionItems1 = @[@"志趣相投", @"附近朋友", @"添加好友"];
        NSArray *sectionItems2 = @[ @"小贴士", @"登出"];
        _sectionItems = @[sectionItems0, sectionItems1, sectionItems2];
        self.tableView.dataSource = self;
        self.tableView.delegate = self;
        self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"sidebar_bg.png"]];
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
//        self.tableView.separatorColor = [UIColor blackColor];
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
                                                     name:UnreadNotificationCount object:nil];
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

//-(UserListViewController*) userListViewController{
//    if (!_userListViewController) {
//        _userListViewController = [[UserListViewController alloc] initWithStyle:UITableViewStylePlain];
//        [_userListViewController viewDidLoad];
//    }
//    return _userListViewController;
//}

-(UserListViewController*) followingsViewController{
    if (!_followingsViewController) {
        _followingsViewController = [[UserListViewController alloc] initWithStyle:UITableViewStylePlain];
        [_followingsViewController viewDidLoad];
//        _followingsViewController setBaseURL:<#(NSString *)#>
    }
    return _followingsViewController;
}

-(UserListViewController*) usersNearbyViewController{
    if (!_usersNearbyViewController) {
        _usersNearbyViewController = [[UserListViewController alloc] initWithStyle:UITableViewStylePlain];
        _usersNearbyViewController.upadateLocationBeforeLoadUsers = YES;
        [_usersNearbyViewController viewDidLoad];
        _usersNearbyViewController.hideDistanceUpdatedTime = YES;
        //        _followingsViewController setBaseURL:<#(NSString *)#>
    }
    return _usersNearbyViewController;
}

-(UserListViewController*) similarUsersViewController{
    if (!_similarUsersViewController) {
        _similarUsersViewController = [[UserListViewController alloc] initWithStyle:UITableViewStylePlain];
        [_similarUsersViewController viewDidLoad];
        //        _followingsViewController setBaseURL:<#(NSString *)#>
    }
    return _similarUsersViewController;
}


-(ConversationViewController*)conversationViewController{
    if (!_conversationViewController) {
        _conversationViewController = [[ConversationViewController alloc] init];
    }
    return _conversationViewController;
}

-(UserDetailsViewController*)userDetailsViewController{
    if (!_userDetailsViewController) {
        _userDetailsViewController = [[UserDetailsViewController alloc] init];
    }
    return _userDetailsViewController;
}

-(NotificationViewController*)notificationViewController{
    if (!_notificationViewController) {
        _notificationViewController = [[NotificationViewController alloc] initWithStyle:UITableViewStylePlain];
    }
    return _notificationViewController;
}

-(void)viewDidLoad{
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userUpdated:) name:NOTIFICATION_USER_UPDATE object:nil];
}

-(void)userUpdated:(NSNotification*)notif{
    [self.tableView reloadData];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
    appFrame.origin.y = 0;
    self.view.frame = appFrame;
    DDLogVerbose(@"setting side bar frame to: %@", NSStringFromCGRect(self.view.frame));
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
    User* loggedInUser = nil;
   
    if ([[UserService service] isLoggedIn]){
         loggedInUser = [UserService service].loggedInUser;
    }

    switch (indexPath.section) {
        case 0:
            if(indexPath.row == 0) {
                CellIdentifier = @"UserHeaderCell";
                NINetworkImageView* avatarView = nil;
                if (cell == nil) {
                    temp = [[UIViewController alloc] initWithNibName:CellIdentifier bundle:nil];
                    cell = (UserHeaderCell*)temp.view;
                    cell.backgroundColor = [UIColor clearColor];
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
                headerCell.nameLabel.text = loggedInUser.name;
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
                NSInteger unreadNotifCount = [NotificationService service].unreadNotifCount;
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
                avatarView.delegate = self;
                [avatarView setPathToNetworkImage:[URLService  absoluteURL:loggedInUser.avatar] forDisplaySize:CGSizeMake(40, 40) contentMode:UIViewContentModeScaleAspectFill];
                return cell;
            } else  if(indexPath.row == 1){
                CellIdentifier = @"SideMealCell";
                SideMealCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
                if (cell == nil) {
                    cell = [[SideMealCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
                    [cell.currentMealsButton addTarget:self action:@selector(showMealList) forControlEvents:UIControlEventTouchUpInside];
                    [cell.myMealsButton addTarget:self action:@selector(showMyMeals) forControlEvents:UIControlEventTouchUpInside];
                    [cell.createMealButton addTarget:self action:@selector(createMeal:) forControlEvents:UIControlEventTouchUpInside];
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

-(void)createMeal:(id)sender{
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"暂不支持从手机发起活动，请登录fanjoin.com" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
    [alert show];
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
    [self showMealList:NO];
}

- (void)showMealList:(BOOL)reload{
    [self showViewController:self.mealListViewController];
    if (reload) {
    [self.mealListViewController reload];
    }

}

-(void)showMyMeals{
    [self showViewController:self.myMealsViewController];
}

-(void)showMessages{
    [self showViewController:self.conversationViewController];
}

-(void)showNotifications{
    NotificationViewController* notificationViewController = [[NotificationViewController alloc] initWithStyle:UITableViewStylePlain];
    [self showViewController:notificationViewController];
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
    UIViewController *controller = self.mealListViewController;
    NSString *userID = [[UserService service].loggedInUser.uID stringValue];
    switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
                case 0:
                    controller = self.userDetailsViewController;
                    self.userDetailsViewController.user = [UserService service].loggedInUser;
                    break;
                case 2:
                    controller = self.followingsViewController;
                    ((UserListViewController*)controller).baseURL = [NSString stringWithFormat:@"user/%@/following/", userID];
                    controller.title = @"我的关注";
                    break;
                default:
                    break;
            }
            break;
        case 1:
            
            switch (indexPath.row) {
                case 0:
                    controller = self.similarUsersViewController;
                    ((UserListViewController*)controller).baseURL = [NSString stringWithFormat:@"user/%@/recommendations/", userID];
                    controller.title = @"志趣相投";
                    break;
                case 1:
                    controller = self.usersNearbyViewController;
                    ((UserListViewController*)controller).baseURL = [NSString stringWithFormat:@"user/%@/users_nearby/", userID];
                    controller.title = @"附近朋友";
                    break;
                case 2:
                    controller = [[SearchUserViewController alloc] init];
                    break;
            }
            
            break;
        case 2:
            switch (indexPath.row) {
                case 0:
                    controller = [[SVWebViewController alloc]initWithAddress:[URLService absoluteURL:@"/faq/mobile/"]];
                    controller.navigationItem.titleView = [[WidgetFactory sharedFactory] titleViewWithTitle:@"小贴士"];
                    break;
                case 1:
                    [self.sideMenu setMenuState:MFSideMenuStateClosed];
                    [[Authentication sharedInstance] logout];
                    [SVProgressHUD showSuccessWithStatus:@"成功登出"];
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
    if (controller != _userDetailsViewController) {
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
    _myMealsViewController = nil;
    _followingsViewController = nil;
    _similarUsersViewController = nil;
    _usersNearbyViewController = nil;
    _userDetailsViewController = nil;
    _conversationViewController = nil;
    _avatarLoaded = NO;
}

- (void)unreadMsgUpdated:(NSNotification*)notif {
    _unreadMessageCount = [notif.object integerValue];
    [self.tableView reloadData];
    [[NSUserDefaults standardUserDefaults] setInteger:_unreadMessageCount forKey:UNREAD_MESSAGE_COUNT];
    [[NSUserDefaults standardUserDefaults] synchronize];
    NSInteger unreadCount = _unreadMessageCount + [NotificationService service].unreadNotifCount;
    [self notifyUnreadCount:unreadCount];
}

- (void)unreadNotifUpdated:(NSNotification*)notif {
    NSInteger unreadNotifCount = [notif.object integerValue];
    if ([NotificationService service].suspend) {
        //notification view is being displayed
        unreadNotifCount = 0;
        [[NotificationService service] markAllNotificationsRead];
    } 

    [self.tableView reloadData];
    [self notifyUnreadCount:unreadNotifCount + _unreadMessageCount];
}

-(void)notifyUnreadCount:(NSInteger)unreadCount{
    [[NSNotificationCenter defaultCenter] postNotificationName:EOUnreadCount
                                                        object:[NSNumber numberWithInteger:unreadCount]
                                                      userInfo:nil];
    [UIApplication sharedApplication].applicationIconBadgeNumber = unreadCount;
}

#pragma mark UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    return YES;
}

-(void)avatarUpdated:(NSNotification*)notif {
    [self.tableView reloadData];
}

#pragma mark NINetworkImageViewDelegate
- (void)networkImageView:(NINetworkImageView *)imageView didLoadImage:(UIImage *)image{
    if (!_avatarLoaded) {
        [self.tableView reloadData];
        _avatarLoaded = YES;
    }
}

@end
