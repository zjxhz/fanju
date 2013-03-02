//
//  MealListViewController.m
//  EasyOrder
//
//  Created by igneus on 3/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MealListViewController.h"
#import "SCAppUtils.h"
#import "MealInfo.h"
#import "MealTableItem.h"
#import "MealTableItemCell.h"
#import "NetworkHandler.h"
#import "Const.h"
#import "AppDelegate.h"
#import "WEPopoverController.h"
#import "WEPopoverContentViewController.h"
#import "NSDictionary+ParseHelper.h"
#import "MealDetailViewController.h"
#import "MealListDataSource.h"
#import "UIViewController+MFSideMenu.h"
#import "Authentication.h"
#import "ActivationViewController.h"
#import "UserRegistrationViewController.h"
#import "SVProgressHUD.h"
#import "OverlayViewController.h"
#import "ImageDownloader.h"

@interface MealListViewController() <WEPopoverControllerDelegate>

@property (nonatomic, strong) WEPopoverController *popover;
@property (nonatomic, strong) IBOutlet UIView* loginView;
@property (nonatomic, strong) IBOutlet UIButton* loginButton;
@property (nonatomic, strong) IBOutlet UIButton* registerButton;
@property (nonatomic, strong) IBOutlet UIImageView* loginWithWeibo;
@property (nonatomic, strong) IBOutlet UIImageView* loginWithQQ;

@end

@implementation MealListViewController

@synthesize popover = _popover;

- (id) init{
    self = [super initWithStyle:UITableViewStylePlain];
    return self;
}

- (void)loadView {
    [super loadView];
    self.title = @"饭局";
    self.tabBarItem = [[UITabBarItem alloc] initWithTitle:self.title image:[UIImage imageNamed:@"fanju_icon.png"] tag:0];    
    //nav bar
    [SCAppUtils customizeNavigationController:self.navigationController];
    if ([[Authentication sharedInstance] isLoggedIn]) {
        [self setupSideMenuBarButtonItem];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didLogin:)
                                                 name:EODidLoginNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didLogout:)
                                                 name:EODidLogoutNotification
                                               object:nil];

    
    _thisWeek = [[UIView alloc] init];
    _thisWeek.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
    UIImageView *calendarImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 0, 14, 20)];//
    calendarImageView.contentMode = UIViewContentModeCenter;
    calendarImageView.image = [UIImage imageNamed:@"calendar"];
    UILabel *thisWeekLabel = [[UILabel alloc] initWithFrame:CGRectMake(35, 0, 60, 20)];
    thisWeekLabel.text = NSLocalizedString(@"ThisWeek", nil);
    thisWeekLabel.textColor = [UIColor whiteColor];
    thisWeekLabel.font = [UIFont boldSystemFontOfSize:12];
    thisWeekLabel.backgroundColor = [UIColor clearColor];
    [_thisWeek addSubview:calendarImageView];
    [_thisWeek addSubview:thisWeekLabel];
    
    _afterThisWeek = [[UIView alloc] init];
    _afterThisWeek.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
    UIImageView *calendarImageView2 = [[UIImageView alloc] initWithFrame:CGRectMake(10, 0, 14, 20)];
    calendarImageView2.contentMode = UIViewContentModeCenter;
    calendarImageView2.image = [UIImage imageNamed:@"calendar"];
    UILabel *afterThisWeekLabel = [[UILabel alloc] initWithFrame:CGRectMake(35, 0, 60, 20)];
    afterThisWeekLabel.text = NSLocalizedString(@"AfterThisWeek", nil);
    afterThisWeekLabel.textColor = [UIColor whiteColor];
    afterThisWeekLabel.font = [UIFont boldSystemFontOfSize:12];
    afterThisWeekLabel.backgroundColor = [UIColor clearColor];
    [_afterThisWeek addSubview:calendarImageView2];
    [_afterThisWeek addSubview:afterThisWeekLabel];
    
    
    AppDelegate *delegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    self.tableView.backgroundColor = [UIColor colorWithPatternImage:delegate.bgImage];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    // terminate all pending download connections
//    NSArray *allDownloads = [imageDownloadsInProgress allValues];
//    [allDownloads makeObjectsPerformSelector:@selector(cancelDownload)];
    NSLog(@"low memory, check what we can do here");
#warning TODO check what we can do here
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
    [self requestDataFromServer];
    self.loginWithWeibo.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(loginWithWeibo:)];
    [self.loginWithWeibo addGestureRecognizer:tapGestureRecognizer];
    
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
        } else {
            return _afterThisWeek;
        }
    }
    else { // section == 1 means there are meals both for this week and after this week
        return _afterThisWeek;
    }
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 22;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 340.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([[Authentication sharedInstance] isLoggedIn]) {
        MealDetailViewController *detail = [[MealDetailViewController alloc] init];
        MealTableItem *item = [self.dataSource tableView:self.tableView objectForRowAtIndexPath:indexPath];
        detail.mealInfo = item.mealInfo;
        [self.navigationController pushViewController:detail animated:YES];
    }
}


#pragma mark -
#pragma mark WEPopoverControllerDelegate implementation

- (void)popoverControllerDidDismissPopover:(WEPopoverController *)thePopoverController {
	//Safe to release the popover here
	self.popover = nil;
}

- (BOOL)popoverControllerShouldDismissPopover:(WEPopoverController *)thePopoverController {
	//The popover is automatically dismissed if you click outside it, unless you return NO here
	return YES;
}

-(void)reload{
    [self requestDataFromServer];
}
- (void) requestDataFromServer{
    [[NetworkHandler getHandler] requestFromURL:[NSString stringWithFormat:@"http://%@/api/v1/meal/?format=json&limit=0", EOHOST]
                                         method:GET
                                    cachePolicy:TTURLRequestCachePolicyNetwork
                                        success:^(id obj) {
                                            NSArray *meals = [obj objectForKeyInObjects];
                                            if (meals && [meals count] > 0) {
                                                MealListDataSource *ds = [[MealListDataSource alloc] init];
                                                
                                                for (NSDictionary *dict in meals) {
                                                    [ds addMeal:[MealTableItem itemWithMealInfo:[MealInfo mealInfoWithData:dict]]];
                                                }  
                                                self.dataSource = ds;
                                                [self loadImagesForOnscreenRows];
                                                if (isLoading) {
                                                    [self stopLoading];
                                                }
                                            }
                                        } failure:^{
                                            if (isLoading) {
                                                [self stopLoading];
                                            }
                                            [SVProgressHUD dismissWithError:@"获取饭局列表失败"];
                                        }];
}


- (void) removeSideMenuBarButtonItem {
//    self.navigationItem.leftBarButtonItem = nil;
    [self.navigationItem setLeftBarButtonItem:nil animated:NO];
}


-(IBAction)register:(id)sender{
    UIViewController* controller = [[UserRegistrationViewController alloc] initWithStyle:UITableViewStyleGrouped];
    [self.navigationController pushViewController:controller animated:YES];
}
-(IBAction)loginWithEmail:(id)sender{
    ActivationViewController* avc = [[ActivationViewController alloc] init];
    UINavigationController *controller = [[UINavigationController alloc] initWithRootViewController:avc];
//    self.modalPresentationStyle = UIModalPresentationCurrentContext;
    [[OverlayViewController sharedOverlayViewController] presentModalViewController:controller animated:YES];
    
//    UIViewController* rootViewController = [TTNavigator navigator].window.rootViewController;
//    rootViewController.modalPresentationStyle = UIModalPresentationCurrentContext;
//    [rootViewController presentModalViewController:controller animated:YES];
}

-(IBAction)loginWithWeibo:(id)sender{
    [Authentication sharedInstance].delegate = self;
    [[Authentication sharedInstance] loginAsSinaWeiboUser:self];
}

-(IBAction)loginWithQQ:(id)sender{
    
}

#pragma mark -
#pragma mark PullRefreshTableViewController

- (void)pullToRefresh {
    [self requestDataFromServer];
}


#pragma mark AuthenticationDelegate
-(void) sinaweiboDidLogin:(SinaWeibo *)sinaWeibo{
    [SVProgressHUD showWithStatus:@"正在获取微博用户信息……"];
}

-(void)userDidLogIn:(UserProfile*) user{
    //do nothing as login has been handled by notifications
}
-(void)userFailedToLogInWithError:(NSString*)error{
    self.tableView.frame = self.view.frame;
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


#pragma mark -
#pragma mark Table cell image support

- (void)startIconDownload:(MealInfo *)mealInfo forIndexPath:(NSIndexPath *)indexPath
{
    ImageDownloader *iconDownloader = [imageDownloadsInProgress objectForKey:indexPath];
    if (iconDownloader == nil && !mealInfo.finishLoadingAllImages)
    {
        iconDownloader = [[ImageDownloader alloc] init];
        iconDownloader.meal = mealInfo;
        iconDownloader.indexPathInTableView = indexPath;
        iconDownloader.delegate = self;
        [imageDownloadsInProgress setObject:iconDownloader forKey:indexPath];
        [iconDownloader startDownload];
    }
}

// this method is used in case the user scrolled into a set of cells that don't have their app icons yet
- (void)loadImagesForOnscreenRows
{
    NSArray *visiblePaths = [self.tableView indexPathsForVisibleRows];
    for (NSIndexPath *indexPath in visiblePaths)
    {
        MealTableItem *item = [self.dataSource tableView:self.tableView objectForRowAtIndexPath:indexPath];
        
        if (!item.mealInfo.finishLoadingAllImages) // avoid the app icon download if the app already has an icon
        {
            [self startIconDownload:item.mealInfo forIndexPath:indexPath];
        }
    }
}

- (void)mealImageDidLoad:(NSIndexPath*) indexPath withImage:(UIImage*)image{
    ImageDownloader *imageDownloader = [imageDownloadsInProgress objectForKey:indexPath];
    if (imageDownloader != nil)
    {
        MealTableItemCell *cell = (MealTableItemCell*)[self.tableView cellForRowAtIndexPath:imageDownloader.indexPathInTableView];
        [cell setMealImage:image];
    }
}

- (void)userSmallAvatarDidLoad:(NSIndexPath*) indexPath withImage:(UIImage*)image forUser:(UserProfile*)user{
    ImageDownloader *imageDownloader = [imageDownloadsInProgress objectForKey:indexPath];
    if (imageDownloader != nil)
    {
        MealTableItemCell *cell = (MealTableItemCell*)[self.tableView cellForRowAtIndexPath:imageDownloader.indexPathInTableView];
        [cell setAvatar:image forUser:user];
    }
}

- (void)didFinishLoad:(NSIndexPath*)indexPath{
    ImageDownloader *imageDownloader = [imageDownloadsInProgress objectForKey:indexPath];
    imageDownloader.meal.finishLoadingAllImages = YES;
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:imageDownloader.indexPathInTableView];
    [cell setNeedsDisplay];
    [imageDownloadsInProgress removeObjectForKey:indexPath];
}

#pragma mark -
#pragma mark Deferred image loading (UIScrollViewDelegate)

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    [self loadImagesForOnscreenRows];
}
@end
