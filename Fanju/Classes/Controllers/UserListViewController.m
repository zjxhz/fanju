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
#import "NewUserDetailsViewController.h"
#import "SVProgressHUD.h"
#import "UserListDataSource.h"
#import "UserListViewController.h"
#import "UserProfile.h"
#import "UserTableItem.h"
#import "UserTableItemCell.h"
#import "LocationProvider.h"
#import "WidgetFactory.h"
#import "DictHelper.h"
#import "MBProgressHUD.h"

@interface UserListViewController(){
    BOOL _upadateLocationBeforeLoadUsers;
    MBProgressHUD* _hud;
}

@end


@implementation UserListViewController
@synthesize baseURL = _baseURL;

+(UserListViewController*)recommendedUserListViewController{
    UserListViewController *c = [[UserListViewController alloc] initWithStyle:UITableViewStylePlain];
    c.baseURL = [NSString stringWithFormat:@"%@://%@/api/v1/user/%d/recommendations/?format=json", HTTPS, EOHOST, [Authentication sharedInstance].currentUser.uID];
    return c;
}

+(UserListViewController*)nearbyUserListViewController{
    UserListViewController *c = [[UserListViewController alloc] initWithStyle:UITableViewStylePlain];
    c.baseURL = [NSString stringWithFormat:@"%@://%@/api/v1/user/%d/users_nearby/?format=json", HTTPS, EOHOST, [Authentication sharedInstance].currentUser.uID];
    return c;
}

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
//    self.tableView.separatorColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"separator"]];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg"]];
    return self;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if (!_hideFilterButton) {
        self.navigationItem.rightBarButtonItem = [[WidgetFactory sharedFactory]normalBarButtonItemWithTitle:@"筛选" target:self action:@selector(filter:)];
    }

    if (_showAddTagButton && ![[Authentication sharedInstance].currentUser.tags containsObject:_tag]) {
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
    UserProfile* user = [Authentication sharedInstance].currentUser;
    NSArray* params = @[[DictHelper dictWithKey:@"tag" andValue:_tag.name]];
    NSString *requestStr = [NSString stringWithFormat:@"%@://%@/api/v1/user/%d/tags/?format=json", HTTPS, EOHOST, user.uID];
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
                                                [user.tags addObject:_tag];
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
    NSString* urlWithFilter = _baseURL;
    if (_filter) {
        urlWithFilter = [NSString stringWithFormat:@"%@&%@", self.baseURL, _filter];
    }
    DDLogVerbose(@"loading users from url: %@", urlWithFilter);
    [[NetworkHandler getHandler] requestFromURL:urlWithFilter
                                         method:GET
                                    cachePolicy:TTURLRequestCachePolicyNone 
                                        success:^(id obj) {
                                            NSDictionary* result = obj;
                                            NSArray *users = [obj objectForKeyInObjects];
                                            UserListDataSource *ds = [[UserListDataSource alloc] init];
              
                                            for (NSDictionary *dict in users) {
                                                UserProfile *profile = [UserProfile profileWithData:dict];
                                                if (profile) {                                                           
                                                    [ds.items addObject:[UserTableItem itemWithProfile:profile withAddButton:YES]];
                                                }
                                            }
                                            
                                            _loadMore = [[LoadMoreTableItem alloc] initWithResult:result fromBaseURL:urlWithFilter];
                                            if ([_loadMore hasMore]) {
                                                 [ds.items addObject:_loadMore];
                                            }
                                            
                                            self.dataSource = ds;
                                            if (isLoading) {
                                                [self stopLoading];
                                            }
                                            _upadateLocationBeforeLoadUsers = YES;
                                        } failure:^{
                                            if (isLoading) {
                                                [self stopLoading];
                                            }
                                            [SVProgressHUD dismissWithError:@"获取数据失败"];
                                            _upadateLocationBeforeLoadUsers = YES;
                                        }];

}


-(void) loadMoreUsers{
    if (![_loadMore hasMore]) {
        return;
    } 
    [[NetworkHandler getHandler] requestFromURL:[_loadMore nextPageURL]
                                         method:GET 
                                    cachePolicy:TTURLRequestCachePolicyNetwork
                                        success:^(id obj) {
                                            //load data
                                            NSDictionary* result = obj;
                                            NSArray *users = [obj objectForKeyInObjects];
                                            UserListDataSource *ds = self.dataSource;
                                            NSMutableArray * indexPaths = [NSMutableArray array];
                                            for (int i = 0; i < users.count; ++i) {
                                                NSDictionary *dict = [users objectAtIndex:i];
                                                
                                                UserProfile *profile = [UserProfile profileWithData:dict];
                                                [ds.items insertObject:[UserTableItem itemWithProfile:profile withAddButton:YES] atIndex:(ds.items.count - 1)];
                                                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:ds.items.count - 1 inSection:0];
                                                [indexPaths addObject:indexPath];
                                            }
                                            [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
                                            
                                            //update load more text and decide if it should be removed
                                            _loadMore.loading = NO;
                                            _loadMore.offset = [result offset];
                                            if (![_loadMore hasMore])  {
                                                [ds.items removeLastObject];
                                                NSArray *rowToDelete = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:(ds.items.count - 1) inSection:0]];
                                                [self.tableView  deleteRowsAtIndexPaths:rowToDelete withRowAnimation:UITableViewRowAnimationAutomatic];
                                            }
                                            [self.tableView reloadData];
                                        } failure:^{
                                            DDLogError(@"failed to load more orders");
#warning fail handling
                                        }];
}

-(void)setFilter:(NSString*)newFilter{
    _upadateLocationBeforeLoadUsers = NO;
    _filter = newFilter;
    [self startLoading];
}

-(void)setBaseURL:(NSString *)baseURL{
    _upadateLocationBeforeLoadUsers = NO;
    _baseURL = baseURL;
    [self startLoading];
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
    if ([object isKindOfClass:[UserTableItem class]]) {
        UserTableItem *item = object;
        NewUserDetailsViewController *newDeail = [[NewUserDetailsViewController alloc] initWithStyle:UITableViewStylePlain];
        newDeail.user = item.profile;
        [self.navigationController pushViewController:newDeail animated:YES];
    } else if ([object isKindOfClass:[LoadMoreTableItem class]]){
        if (_loadMore.loading) {
            return;
        }
        _loadMore.loading = YES;
        [self reloadLastRow];
        [self loadMoreUsers];
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
    NSString* newFilter =  nil;
    UINavigationController *nav;
    switch (buttonIndex) {
        case 0:
            newFilter = nil;
            break;
        case 1:
            newFilter = @"gender=0";
            break;
        case 2:
            newFilter = @"gender=1";
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
    
//    [self performSelector:@selector(setFilter) withObject:newFilter afterDelay:0.1];
    [self setFilter:newFilter];
}

#pragma mark CustomUserFilterViewControllerDelegate
-(void)filterSelected:(NSString *)filter{
    [self setFilter:filter];
}

#pragma mark -
#pragma mark PullRefreshTableViewController
- (void)pullToRefresh {
    if (_upadateLocationBeforeLoadUsers) {
        [[LocationProvider sharedProvider] updateLocationWithSuccess:^(CLLocation *location) {
            DDLogVerbose(@"load users for lat and lng: %f, %f", location.coordinate.latitude,  location.coordinate.longitude );
            NSString* newFilter = [NSString stringWithFormat:@"lat=%f&lng=%f", location.coordinate.latitude,
                                   location.coordinate.longitude];
            if (_filter) {
                NSUInteger latFilterLoc = [_filter rangeOfString:@"lat="].location;
                if (latFilterLoc != NSNotFound) {
                    _filter = [_filter substringFromIndex:latFilterLoc];
                }
                _filter = [NSString stringWithFormat:@"%@&%@", _filter, newFilter];
            } else {
                _filter = newFilter;
            }
            DDLogVerbose(@"load users with filter %@", _filter);
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
