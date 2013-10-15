
//
//  MealListViewController.m
//  EasyOrder
//
//  Created by igneus on 3/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MealListViewController.h"
#import "MealTableItem.h"
#import "NetworkHandler.h"
#import "Const.h"
#import "AppDelegate.h"
#import "NSDictionary+ParseHelper.h"
#import "MealDetailViewController.h"
#import "MealListDataSource.h"
#import "Authentication.h"
#import "UserRegistrationViewController.h"
#import "SVProgressHUD.h"
#import "OverlayViewController.h"
#import "ImageDownloader.h"
#import "MFSideMenu.h"
#import "UIViewController+MFSideMenu.h"
#import "WidgetFactory.h"
#import "RestKit/RestKit.h"
#import "DDAlertPrompt.h"
#import "NewSidebarViewController.h"
#import "UserService.h"

@interface MealListViewController()
@property (nonatomic, strong) IBOutlet UIImageView* loginView;
@property (nonatomic, strong) IBOutlet UIButton* loginButton;
@property (nonatomic, strong) IBOutlet UIButton* registerButton;
@property (nonatomic, strong) IBOutlet UIImageView* loginWithWeibo;
@property (nonatomic, strong) IBOutlet UIImageView* loginWithQQ;

@end

@implementation MealListViewController

- (id) init{
    self = [super initWithStyle:UITableViewStylePlain];
    return self;
}

- (void)loadView {
    [super loadView];
    self.navigationItem.titleView = [[WidgetFactory sharedFactory] titleViewWithTitle:@"饭聚"];
//    self.tabBarItem = [[UITabBarItem alloc] initWithTitle:self.title image:[UIImage imageNamed:@"fanju_icon.png"] tag:0];
//    if ([[Authentication sharedInstance] isLoggedIn]) {
//        [self setupSideMenuBarButtonItem];
//    }
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didLogin:)
                                                 name:EODidLoginNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didLogout:)
                                                 name:EODidLogoutNotification
                                               object:nil];

    
    _thisWeek = [self createHeader:@"ThisWeek"];
    _afterThisWeek = [self createHeader:@"AfterThisWeek"];
    _passedMeals = [self createHeader:@"PassedMeals"];
    AppDelegate *delegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    self.tableView.backgroundColor = [UIColor colorWithPatternImage:delegate.bgImage];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _refreshControl = [[ODRefreshControl alloc] initInScrollView:self.tableView];
    [_refreshControl addTarget:self action:@selector(requestDataFromServer) forControlEvents:UIControlEventValueChanged];
    _loginView.image = [UIImage imageNamed:@"login_bg"];
}

-(UIView*)createHeader:(NSString*)text{
    UIView* view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 22)];
    view.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
    UIImage* clockImage = [UIImage imageNamed:@"title_time"];
    UIImageView *clockImageView = [[UIImageView alloc] initWithImage:clockImage];
    clockImageView.frame = CGRectMake(9, 5, clockImage.size.width, clockImage.size.height);
    CGFloat x = clockImageView.frame.origin.x + clockImageView.frame.size.width + 6;
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(x, 0, 120, 23)];
    label.text = NSLocalizedString(text, nil);
    label.textColor = RGBCOLOR(245, 245, 245);
    label.font = [UIFont systemFontOfSize:14];
    label.backgroundColor = [UIColor clearColor];
    label.layer.shadowColor = RGBACOLOR(0, 0, 0, 0.5).CGColor;
    label.layer.shadowOffset = CGSizeMake(0, 1);
    [view addSubview:clockImageView];
    [view addSubview:label];
    return view;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    DDLogWarn(@"low memory, check what we can do here");
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.view sendSubviewToBack:self.tableView];
    //tableview will change position when back from login screen, set it right
    self.tableView.frame = self.view.frame;
    self.loginView.hidden = YES;
    if (![[Authentication sharedInstance] isLoggedIn]) {
        self.loginView.hidden = NO;
        CGRect frame = self.loginView.frame;
        self.loginView.frame = CGRectMake(0, self.view.bounds.size.height - frame.size.height, frame.size.width, frame.size.height);
    }
}

- (void)viewDidLoad{
    [super viewDidLoad];
    imageDownloadsInProgress = [NSMutableDictionary dictionary];
    self.autoresizesForKeyboard = YES;
    self.variableHeightRows = YES;
    self.loginWithWeibo.userInteractionEnabled = YES;
    UITapGestureRecognizer *weiboTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(loginWithWeibo:)];
    [self.loginWithWeibo addGestureRecognizer:weiboTap];
    
    self.loginWithQQ.userInteractionEnabled = YES;
    UITapGestureRecognizer *qqTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(loginWithQQ:)];
    [self.loginWithQQ addGestureRecognizer:qqTap];
    
    [self requestDataFromServer];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(alixPayResult:) name:ALIPAY_PAY_RESULT object:nil];
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (id<UITableViewDelegate>)createDelegate {
    return self;
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    MealListDataSource *ds = self.dataSource;
    if (section == 0) {
        if (ds.numberOfMealsForThisWeek > 0) {
            return _thisWeek;
        } else if(ds.numberOfMealsAfterThisWeek > 0){
            return _afterThisWeek;
        } else {
            return _passedMeals;
        }
    } else if(section == 1){
        if (ds.numberOfMealsForThisWeek == 0) {
            return _passedMeals;
        } else if(ds.numberOfMealsAfterThisWeek > 0){
            return _afterThisWeek;
        }
        return _passedMeals;
    } else {
        return _passedMeals;
    }
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 23;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 329.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([[UserService service] isLoggedIn]) {
        [_refreshControl endRefreshing];//endRefreshing crashes if controller is not visible
        MealDetailViewController *detail = [[MealDetailViewController alloc] init];
        Meal *meal = [self.dataSource tableView:self.tableView objectForRowAtIndexPath:indexPath];
        detail.meal = meal;
        [self.navigationController pushViewController:detail animated:YES];
    }
}


- (void) requestDataFromServer{
    RKObjectManager* manager = [RKObjectManager sharedManager];
    [manager getObjectsAtPath:@"meal/"
                   parameters:@{@"limit":@"0"}
                      success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                          _modelError = nil;
                          [self showError:NO];
                          DDLogVerbose(@"fetched results from /meal/");
                          MealListDataSource *ds = [[MealListDataSource alloc] init];
                          for (Meal* meal in mappingResult.array) {
                              [ds addMeal:meal];
                          }
                          self.dataSource = ds;
                          if (self.tableView.dataSource) { //datasource is nil when controller is not visible, e.g. pushed, which endRefreshing would cause crash 
                                [_refreshControl endRefreshing];
                          }
                      }
                      failure:^(RKObjectRequestOperation *operation, NSError *error) {
                          _modelError = error;
                          if ([self canShowModel]) {
                              [SVProgressHUD showErrorWithStatus:[error localizedDescription]];
                          } else {
                              [self showError:YES];
                          }
                          if (self.tableView.dataSource){
                              [_refreshControl endRefreshing];
                          }
                          DDLogError(@"failed from /meal/: %@", error);
                      }];
}

-(void)reload{
    [self requestDataFromServer];
}
- (void) removeSideMenuBarButtonItem {
    self.navigationItem.leftBarButtonItem = nil;
}


-(IBAction)register:(id)sender{
    UIViewController* controller = [[UserRegistrationViewController alloc] initWithStyle:UITableViewStyleGrouped];
    [self.navigationController pushViewController:controller animated:YES];
}

-(IBAction)loginWithWeibo:(id)sender{
    [Authentication sharedInstance].delegate = self;
    if ([EOHOST rangeOfString:@"localhost"].location != NSNotFound) { //quick hack as it's not possible to login as weibo user on localhost
        DDAlertPrompt *loginPrompt = [[DDAlertPrompt alloc] initWithTitle:@"登录(开发服务器)" delegate:self cancelButtonTitle:@"取消" otherButtonTitle:@"确定"];
        [loginPrompt show];
        return;
    }
    [[Authentication sharedInstance] loginAsSinaWeiboUser:self];
}

- (void)didPresentAlertView:(UIAlertView *)alertView {
	if ([alertView isKindOfClass:[DDAlertPrompt class]]) {
		DDAlertPrompt *loginPrompt = (DDAlertPrompt *)alertView;
		[loginPrompt.plainTextField becomeFirstResponder];
		[loginPrompt setNeedsLayout];
	}
}

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
	if (buttonIndex == [alertView cancelButtonIndex]) {
	} else {
		if ([alertView isKindOfClass:[DDAlertPrompt class]]) {
            DDAlertPrompt *loginPrompt = (DDAlertPrompt *)alertView;
            [[Authentication sharedInstance] loginWithUserName:loginPrompt.plainTextField.text password:loginPrompt.secretTextField.text];
		}
	}
}


-(IBAction)loginWithQQ:(id)sender{
    DDAlertPrompt *loginPrompt = [[DDAlertPrompt alloc] initWithTitle:@"登录(开发服务器)" delegate:self cancelButtonTitle:@"取消" otherButtonTitle:@"确定"];
    [loginPrompt show];
    return;
}

#pragma mark AuthenticationDelegate
-(void) sinaweiboDidLogin:(SinaWeibo *)sinaWeibo{
    [SVProgressHUD showWithStatus:@"正在获取微博用户信息……"];
}

- (void)sinaweiboLogInDidCancel:(SinaWeibo *)sinaweibo{
    [self.tableView reloadData];
    self.tableView.frame = self.view.frame;
//    if (self.isViewLoaded && self.view.window) {
//        [SVProgressHUD dismiss];
//    }
}

-(void)userDidLogIn:(UserProfile*) user{
    //do nothing as login has been handled by notifications
}
-(void)userFailedToLogInWithError:(NSString*)error{
    self.tableView.frame = self.view.frame;
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"登录失败" message:@"请检查用户名密码" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
    [alert show];
}

-(void)userDidLogout:(UserProfile*)user{
    //do nothing as logout has been handled by notifications
}

#pragma mark NSNotificationCenter
- (void)didLogin:(NSNotification*)notif {
    [self setupSideMenuBarButtonItem];
    self.loginView.hidden = YES;
    self.tableView.frame = self.view.frame;
    if (self.isViewLoaded && self.view.window) {
        [SVProgressHUD dismiss];
    }
    
}

- (void)didLogout:(NSNotification*)notif {
    [self removeSideMenuBarButtonItem];
    self.tableView.frame = self.view.frame;
    self.loginView.hidden = NO;
    CGRect frame = self.loginView.frame;
    self.loginView.frame = CGRectMake(0, self.view.bounds.size.height - frame.size.height, frame.size.width, frame.size.height);
}



//-(void)preloadImages:(NSArray*)indexPaths{
//    for (NSIndexPath* indexPath in indexPaths) {
//        MealTableItem* item = [self.dataSource tableView:self.tableView objectForRowAtIndexPath:indexPath];
//        [self preDownload:item.mealInfo.photoFullUrl];
//        for (UserProfile* participant in item.mealInfo.participants) {
//            [self preDownload:participant.avatarFullUrl];
//        }
//    }
//}
//
//-(void)preDownload:(NSString*)url{
//    TTURLRequest* request = [TTURLRequest requestWithURL:url delegate:self];
//    request.response = [[TTURLImageResponse alloc] init];
//    [request send];
//}

#pragma mark -
#pragma mark Deferred image loading (UIScrollViewDelegate)
-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
//    [self loadImagesForOnscreenRows];
}
@end
