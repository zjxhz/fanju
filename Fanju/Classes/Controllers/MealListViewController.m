//
//  MealListViewController.m
//  EasyOrder
//
//  Created by igneus on 3/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MealListViewController.h"
#import "MealInfo.h"
#import "MealTableItem.h"
#import "MealTableItemCell.h"
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

@interface MealListViewController()
@property (nonatomic, strong) IBOutlet UIView* loginView;
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
    self.title = @"饭聚";
    self.tabBarItem = [[UITabBarItem alloc] initWithTitle:self.title image:[UIImage imageNamed:@"fanju_icon.png"] tag:0];
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

    
    _thisWeek = [self createHeader:@"ThisWeek"];
    _afterThisWeek = [self createHeader:@"AfterThisWeek"];   
    AppDelegate *delegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    self.tableView.backgroundColor = [UIColor colorWithPatternImage:delegate.bgImage];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}


-(UIView*)createHeader:(NSString*)text{
    UIView* view = [[UIView alloc] init];
    view.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
    UIImage* clockImage = [UIImage imageNamed:@"title_time"];
    UIImageView *clockImageView = [[UIImageView alloc] initWithImage:clockImage];
    clockImageView.frame = CGRectMake(9, 4, clockImage.size.width, clockImage.size.height);
    CGFloat x = clockImageView.frame.origin.x + clockImageView.frame.size.width + 6;
    UILabel *thisWeekLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, 2, 120, 20)];
    thisWeekLabel.text = NSLocalizedString(text, nil);
    thisWeekLabel.textColor = RGBCOLOR(245, 245, 245);
    thisWeekLabel.font = [UIFont systemFontOfSize:14];
    thisWeekLabel.backgroundColor = [UIColor clearColor];
    [view addSubview:clockImageView];
    [view addSubview:thisWeekLabel];
    return view;
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
    self.loginWithWeibo.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(loginWithWeibo:)];
    [self.loginWithWeibo addGestureRecognizer:tapGestureRecognizer];
    [self requestDataFromServer];
    
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
    return 23;
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
    [self.navigationItem setLeftBarButtonItem:nil animated:NO];
}


-(IBAction)register:(id)sender{
    UIViewController* controller = [[UserRegistrationViewController alloc] initWithStyle:UITableViewStyleGrouped];
    [self.navigationController pushViewController:controller animated:YES];
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
        NSLog(@"start downloading images for index path: (%d,%d)", indexPath.section, indexPath.row);
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
    NSMutableArray* preloadedPaths = [NSMutableArray array];
    NSIndexPath* lastIndexPath = [visiblePaths lastObject];
    [preloadedPaths addObjectsFromArray:[self indexPathsUnder:lastIndexPath count:2]];
    [self preloadImages:preloadedPaths];
}

-(void)preloadImages:(NSArray*)indexPaths{
    for (NSIndexPath* indexPath in indexPaths) {
        MealTableItem* item = [self.dataSource tableView:self.tableView objectForRowAtIndexPath:indexPath];
        [self preDownload:item.mealInfo.photoFullUrl];
        for (UserProfile* participant in item.mealInfo.participants) {
            [self preDownload:participant.smallAvatarFullUrl];
        }
    }
}

-(void)preDownload:(NSString*)url{
    TTURLRequest* request = [TTURLRequest requestWithURL:url delegate:self];
    request.response = [[TTURLImageResponse alloc] init];
    [request send];
}
-(NSArray*)indexPathsUnder:(NSIndexPath*)indexPath count:(NSInteger)count{
    NSMutableArray* indexPaths = [NSMutableArray array];
    NSIndexPath* current = indexPath;
    for(int i = 0; i < count; ++i){
        if (current.row + 1 < [self.dataSource tableView:self.tableView numberOfRowsInSection:current.section]) {
            current = [NSIndexPath indexPathForRow:current.row + 1 inSection:current.section];
        } else if (current.section < [self.dataSource numberOfSectionsInTableView:self.tableView]){
            current = [NSIndexPath indexPathForRow:0 inSection:current.section + 1];
        } else{
            break;
        }
        [indexPaths addObject:current];
    }
    return indexPaths;
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
-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    [self loadImagesForOnscreenRows];
}
@end
