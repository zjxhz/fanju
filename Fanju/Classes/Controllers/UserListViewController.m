//
//  UserListViewController.m
//  EasyOrder
//
//  Created by igneus on 3/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "Authentication.h"
#import "Const.h"
#import "CustomUserFilterViewController.h"
#import "NetworkHandler.h"
#import "UserDetailsViewController.h"
#import "SVProgressHUD.h"
#import "UserListDataSource.h"
#import "UserListViewController.h"
#import "UserTableItem.h"
#import "UserTableItemCell.h"
#import "LocationProvider.h"
#import "WidgetFactory.h"
#import "DictHelper.h"
#import "MBProgressHUD.h"
#import "ODRefreshControl.h"
#import "LoadMoreTableItem.h"
//#import "ISRefreshControl.h"


@interface UserListViewController(){
    MBProgressHUD* _hud;
}
@property(nonatomic, strong) ODRefreshControl* refreshControl;
//@property(nonatomic, strong) ISRefreshControl* refreshControl;
@property(nonatomic) BOOL upadateLocationBeforeLoadUsers;
@property(nonatomic, strong) RKPaginator* paginator;
@property(nonatomic, strong)    LoadMoreTableItem *loadMore;
@end


@implementation UserListViewController{
    NSManagedObjectContext* _mainQueueContext;
    NSDate *_lastUpdatedTime;
}
@synthesize baseURL = _baseURL;

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
//    self.tableView.separatorColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"separator"]];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg"]];
    _refreshControl = [[ODRefreshControl alloc] initInScrollView:self.tableView];
//    [self.tableView addSubview:_refreshControl];
    [_refreshControl addTarget:self action:@selector(loadUsersWithNewLocation) forControlEvents:UIControlEventValueChanged];
    RKManagedObjectStore* store = [RKObjectManager sharedManager].managedObjectStore;
    _mainQueueContext = store.mainQueueManagedObjectContext;
    return self;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if (!_hideFilterButton) {
        self.navigationItem.rightBarButtonItem = [[WidgetFactory sharedFactory]normalBarButtonItemWithTitle:@"筛选" target:self action:@selector(filter:)];
    }

    if (_showAddTagButton && ![[UserService service].loggedInUser.tags containsObject:_tag]) {
        self.toolbarItems = [self createToolbarItems];
        [self.navigationController setToolbarHidden:NO];
    }
}

-(NSArray*) createToolbarItems{
    UIBarButtonItem* flexiSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIImage* toolbarBg = [UIImage imageNamed:@"toolbar_bg"] ;
    UIImage* buttonBG = [UIImage imageNamed:@"confirm_btn_big"];
    UIButton* button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, buttonBG.size.width, buttonBG.size.height)];
    [button addTarget:self action:@selector(addTagToMine:) forControlEvents:UIControlEventTouchUpInside];
    [button setBackgroundImage:buttonBG forState:UIControlStateNormal];
    [button setTitle:@"添加到我的兴趣" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:18];
    [self.navigationController.toolbar setBackgroundImage:toolbarBg forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
    UIBarButtonItem* item = [[UIBarButtonItem alloc] initWithCustomView:button];
    return @[flexiSpace, item, flexiSpace];
}

-(void)addTagToMine:(id)sender{
    User* user = [UserService service].loggedInUser;
    NSArray* params = @[[DictHelper dictWithKey:@"tag" andValue:_tag.name]];
    NSString *requestStr = [NSString stringWithFormat:@"%@://%@/api/v1/user/%@/tags/?format=json", HTTPS, EOHOST, user.uID];
    [[NetworkHandler getHandler] requestFromURL:requestStr
                                         method:POST
                                     parameters:params
                                    cachePolicy:TTURLRequestCachePolicyNone
                                        success:^(id obj) {
                                            if ([[obj objectForKey:@"status"] isEqualToString:@"OK"]) {
                                                DDLogVerbose(@"tag added");
                                                _hud = [MBProgressHUD showHUDAddedTo:self.view animated:NO];
                                                _hud.mode = MBProgressHUDModeText;
                                                _hud.labelText = @"已添加到我的兴趣";
                                                [NSTimer scheduledTimerWithTimeInterval:1.5 target:self selector:@selector(dismissHUD) userInfo:nil repeats:NO];
                                                
                                                [user addTagsObject:_tag];
                                                
                                                [_mainQueueContext saveToPersistentStore:nil];
                                                [[Authentication sharedInstance] relogin];
                                                [self.navigationController.toolbar setHidden:YES];
                                                self.view.frame = CGRectMake(0, 0, 320, 416);
                                                self.tableView.frame = self.view.frame;
                                            } else {
                                                [SVProgressHUD dismissWithSuccess:@"添加失败"];
                                            }
                                        } failure:^{
                                            DDLogError(@"failed to save settings");
                                            [SVProgressHUD dismissWithError:@"添加失败"];
                                        }];

}

-(void)dismissHUD{
//    [SVProgressHUD dismiss];
    [_hud hide:YES];
}
-(void)viewWillDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [self.navigationController setToolbarHidden:YES];
}

-(void)setTitle:(NSString *)title{
    self.navigationItem.titleView = [[WidgetFactory sharedFactory]titleViewWithTitle:title];
}

- (void)loadView {
    [super loadView];
    
    AppDelegate *delegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    self.tableView.backgroundColor = [UIColor colorWithPatternImage:delegate.bgImage];

    self.autoresizesForKeyboard = YES;
    self.variableHeightRows = YES;    
}

-(void)filter:(id)sender{
    UIActionSheet *actions = [[UIActionSheet alloc] initWithTitle:@"筛选" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"全部",@"男",@"女",@"自定义", nil];
    [actions showInView:self.view];    
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [TTURLRequestQueue mainQueue].suspended = NO; //workaround, not really sure how it works
    self.tableView.frame = self.view.frame;
}

-(void)loadUsers{
    [self loadUsers:NO];
}

-(void)loadUsers:(BOOL)nextPage{
    RKObjectManager *manager = [RKObjectManager sharedManager];
    __weak typeof(self) weakSelf = self;
    NSString* requestWithPagination = [NSString stringWithFormat:@"%@?page=:currentPage&limit=:perPage%@", _baseURL, [self filerToString]];
    if (!nextPage) {
        _paginator = [manager paginatorWithPathPattern:requestWithPagination];
        UserListDataSource *ds = [[UserListDataSource alloc] init];
        self.dataSource = ds;
    }
    [_paginator setCompletionBlockWithSuccess:^(RKPaginator *paginator, NSArray *objects, NSUInteger page) {
        UserListDataSource *ds = weakSelf.dataSource;
        id lastItem = [ds.items lastObject];
        if ([lastItem isKindOfClass:[LoadMoreTableItem class]]) {
            [ds.items removeLastObject];
        }
        [ds.items addObjectsFromArray:objects];
        weakSelf.upadateLocationBeforeLoadUsers = YES;
        if ([weakSelf.paginator hasNextPage]) {
            weakSelf.loadMore = [[LoadMoreTableItem alloc] init];
            [ds.items addObject:weakSelf.loadMore];
        }
        [weakSelf refresh];
        [weakSelf.refreshControl endRefreshing];
    } failure:^(RKPaginator *paginator, NSError *error) {
        [weakSelf.refreshControl endRefreshing];
        DDLogError(@"failed to load users: %@", error);
        weakSelf.upadateLocationBeforeLoadUsers = YES;
    }];
    _paginator.perPage = 20;
    if (nextPage) {
        [_paginator loadNextPage];
    } else {
        [_paginator loadPage:1]; //page starts from 1
    }
}

-(NSString*)filerToString{
    NSMutableString* str = [[NSMutableString alloc] init];
    for (NSString* key in _filter) {
        [str appendFormat:@"&%@=%@", key, _filter[key]];
    }
    return str;
}

-(void)beginRefreshing{
    self.tableView.contentOffset = CGPointMake(0, -44);
    [_refreshControl beginRefreshing];
}

-(void)setFilter:(NSDictionary*)newFilter{
    [self beginRefreshing];
    _upadateLocationBeforeLoadUsers = NO;
    _filter = newFilter;
    [self loadUsers];
}

-(void)setBaseURL:(NSString *)baseURL{
    NSDate* now = [NSDate date];
    if ([baseURL isEqual:_baseURL] && _lastUpdatedTime && [now timeIntervalSinceDate:_lastUpdatedTime] < 300 ) {
        return;
    }
    _lastUpdatedTime = now;
    _upadateLocationBeforeLoadUsers = NO;
    _baseURL = baseURL;
    [self beginRefreshing];
    [self loadUsers];
}

- (id<UITableViewDelegate>)createDelegate {
    return self;
}

#pragma mark UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    id<TTTableViewDataSource> dataSource = (id<TTTableViewDataSource>)tableView.dataSource;
    id object = [dataSource tableView:tableView objectForRowAtIndexPath:indexPath];
    if ([object isKindOfClass:[LoadMoreTableItem class]]){
        return 50;
    }
    return 88;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    id<TTTableViewDataSource> dataSource = (id<TTTableViewDataSource>)tableView.dataSource;
    id object = [dataSource tableView:tableView objectForRowAtIndexPath:indexPath];
    if ([object isKindOfClass:[User class]]) {
        User *user = object;
        UserDetailsViewController *newDeail = [[UserDetailsViewController alloc] initWithStyle:UITableViewStylePlain];
        newDeail.user = user;
        [self.navigationController pushViewController:newDeail animated:YES];
    } else if ([object isKindOfClass:[LoadMoreTableItem class]]){
        if (_loadMore.loading) {
            return;
        }
        _loadMore.loading = YES;
        [self reloadLastRow];
        [self loadUsers:YES];
    }
}

-(void)reloadLastRow{
    UserListDataSource *ds = self.dataSource;
    NSArray *lastRow = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:(ds.items.count - 1) inSection:0]];
    [self.tableView reloadRowsAtIndexPaths:lastRow withRowAnimation:UITableViewRowAnimationAutomatic]; 
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    if (_hideNumberOfSameTags) {
        if ([cell isKindOfClass:[UserTableItemCell class]]) {
            UserTableItemCell* userCell = ( UserTableItemCell*)cell;
            userCell.numberOfSameTagsButton.hidden = YES;
        }
    }
}
#pragma mark UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    NSMutableDictionary* newFilter =  [NSMutableDictionary dictionary];
    UINavigationController *nav;
    switch (buttonIndex) {
        case 0:
            newFilter = nil;
            break;
        case 1:
            newFilter[@"gender"]=[NSNumber numberWithInteger:0];
            break;
        case 2:
            newFilter[@"gender"]=[NSNumber numberWithInteger:1];
            break;
        case 3:
            if (!_customUserFilterViewController) {
                _customUserFilterViewController = [[CustomUserFilterViewController alloc] init];
                _customUserFilterViewController.delegate = self;
            }
            nav = [[UINavigationController alloc] initWithRootViewController:_customUserFilterViewController];
           [nav.navigationBar setBackgroundImage:[UIImage imageNamed:@"topbar_bg"] forBarMetrics:UIBarMetricsDefault];
            [self presentViewController:nav animated:YES completion:^(void){
                
            }];
            return;
        case 4:
            return;
        default:
            break;
    }
    
    [self setFilter:newFilter];
}

#pragma mark CustomUserFilterViewControllerDelegate
-(void)filterSelected:(NSDictionary *)filter{
    [self setFilter:filter];
}

- (void)loadUsersWithNewLocation {
    if (_upadateLocationBeforeLoadUsers) {
        [[LocationProvider sharedProvider] updateLocationWithSuccess:^(CLLocation *location) {
            DDLogVerbose(@"load users for lat and lng: %f, %f", location.coordinate.latitude,  location.coordinate.longitude );
            NSMutableDictionary* newFilter = [NSMutableDictionary dictionary];
            newFilter[@"lat"]= [NSString stringWithFormat:@"%f", location.coordinate.latitude];
            newFilter[@"lng"]= [NSString stringWithFormat:@"%f", location.coordinate.longitude];
            DDLogVerbose(@"load users with filter %@", _filter);
            _filter = newFilter;
            [self loadUsers];
        } orFailed:^{
            DDLogError(@"failed to update location, just load users for current location");
            [self loadUsers];
        }];
    } else {
        [self loadUsers];
    }
}
@end
