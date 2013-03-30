//
//  SocialNetworkViewController.m
//  EasyOrder
//
//  Created by igneus on 3/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SocialNetworkViewController.h"
#import "NetworkHandler.h"
#import "Const.h"
#import "AppDelegate.h"
#import "UserListViewController.h"
#import "UserListDataSource.h"
#import "UserProfile.h"
#import "UserTableItem.h"
#import "NSDictionary+ParseHelper.h"
#import "Authentication.h"
#import "FeedTableItemCell.h"
#import "OrderTableItem.h"
#import "SVProgressHUD.h"
#import "NewUserDetailsViewController.h"
#import "LoadMoreTableItem.h"

@interface FeedListDataSource : TTListDataSource

@end

@implementation FeedListDataSource

- (Class)tableView:(UITableView*)tableView cellClassForObject:(id) object {
    
	if ([object isKindOfClass:[OrderTableItem class]]) {  
		return [FeedTableItemCell class];  
	}
    
	return [super tableView:tableView
	     cellClassForObject:object];
}
@end

@interface SocialNetworkViewController () <UITableViewDelegate>{
    UISegmentedControl* _seg;
    LoadMoreTableItem *_loadMore;
}

@end

@implementation SocialNetworkViewController
-(id) init{
    if (self = [super init]) {
        self.title = @"关注";
        self.tabBarItem = [[UITabBarItem alloc] initWithTitle:self.title image:[UIImage imageNamed:@"compose-at.png"] tag:0]; 
    }
    return self;
}

- (void)loadView {
    [super loadView];

    TTButton *btn = [TTButton buttonWithStyle:@"embossedButton:" title:NSLocalizedString(@"Addfollowing", nil)];
    [btn addTarget:self 
            action:@selector(addFollowing) 
  forControlEvents:UIControlEventTouchDown];
    btn.font = [UIFont systemFontOfSize:13];
    [btn sizeToFit];
    UIBarButtonItem *temporaryBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:btn];
    self.navigationItem.rightBarButtonItem = temporaryBarButtonItem;
    
    AppDelegate *delegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    self.tableView.backgroundColor = [UIColor colorWithPatternImage:delegate.bgImage]; 
    
    _seg = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"关注", @"动态", nil]];
    _seg.segmentedControlStyle = UISegmentedControlStyleBar;
    [_seg setSelectedSegmentIndex:0];
    [_seg addTarget:self action:@selector(selectionChanged:) forControlEvents:UIControlEventValueChanged];
    self.navigationItem.titleView = _seg;
}

-(void) selectionChanged:(id)sender{
    UISegmentedControl *seg = sender;
    if (seg.selectedSegmentIndex == 0) {
        [self requestFollowings];
    } else {
        [self requestFeeds];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.autoresizesForKeyboard = YES;
    self.variableHeightRows = YES;
    [self requestFollowings];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.tableView.frame = self.view.frame;
}

-(void)requestFollowings{
    NSString *baseURL = [NSString stringWithFormat:@"%@://%@/api/v1/user/%d/following/?format=json", HTTPS, EOHOST, [Authentication sharedInstance].currentUser.uID];
    [[NetworkHandler getHandler] requestFromURL:baseURL
                                         method:GET
                                    cachePolicy:TTURLRequestCachePolicyNone
                                        success:^(id obj) {
                                            if (isLoading) {
                                                [self stopLoading];
                                            }
                                            NSArray *users = [obj objectForKeyInObjects];
                                            UserListDataSource *ds = [[UserListDataSource alloc] init];
                                            if (users && [users count] > 0) {
                                                [[Authentication sharedInstance].currentUser.followings removeAllObjects];
                                                for (NSDictionary *dict in users) {
                                                    UserProfile *profile = [UserProfile profileWithData:dict];
                                                    if (profile) {                                                           
                                                        [ds.items addObject:[UserTableItem itemWithProfile:profile withAddButton:NO]];
                                                    }
                                                    [[Authentication sharedInstance].currentUser.followings addObject:[NSString stringWithFormat:@"%d", profile.uID]];
                                                }
                                                
                                                _loadMore = [[LoadMoreTableItem alloc] initWithResult:obj fromBaseURL:baseURL];
                                                if ([_loadMore hasMore]) {
                                                    [ds.items addObject:_loadMore];
                                                }
                                                
                                            } else {
                                                UIAlertView *alter = [[UIAlertView alloc] initWithTitle:@"没有关注的用户" message:@"您还没有关注的用户，去看看有什么值得关注的用户吧" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:@"以后再说",nil];
                                                [alter show];
                                            }
                                            self.dataSource = ds;
                                            if (ds.items.count == 0) {//force set delegate if datasource contains no data
                                                self.tableView.delegate = self;
                                            }
                                            [[Authentication sharedInstance] synchronize];
                                            
                                        } failure:^{
                                            [SVProgressHUD dismissWithError:@"获取关注列表失败"];
                                            if (isLoading) {
                                                [self stopLoading];
                                            }
                                        }];	
}

-(void) loadMoreFollowings{
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
                                            if (users && [users count] > 0) {
                                                for (NSDictionary *dict in users) {
                                                    UserProfile *profile = [UserProfile profileWithData:dict];
                                                    [ds.items insertObject:[UserTableItem itemWithProfile:profile withAddButton:NO] atIndex:(ds.items.count - 1)];
                                                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:ds.items.count - 1 inSection:0];
                                                    [indexPaths addObject:indexPath];

                                                    [[Authentication sharedInstance].currentUser.followings addObject:[NSString stringWithFormat:@"%d", profile.uID]];
                                                }
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
                                            NSLog(@"failed to load more followings");
#warning fail handling
                                        }];
}

-(void)requestFeeds{
    NSString *requestStr = [NSString stringWithFormat:@"%@://%@/api/v1/user/%d/feeds/", HTTPS, EOHOST, [Authentication sharedInstance].currentUser.uID];
    [[NetworkHandler getHandler] requestFromURL:requestStr
                                         method:GET
                                    cachePolicy:TTURLRequestCachePolicyNone
                                        success:^(id obj) {
                                            if (isLoading) {
                                                [self stopLoading];
                                            }
                                            NSArray *orders = [obj objectForKeyInObjects];
                                            if (orders && [orders count] > 0) {
                                                FeedListDataSource *ds = [[FeedListDataSource alloc] init];
                                                for (NSDictionary *dict in orders) {
                                                    OrderInfo *order = [OrderInfo orderInfoWithData:dict];

                                                    if (order) {                                                           
                                                        [ds.items addObject:[OrderTableItem itemWithOrderInfo:order]];
                                                    }
                                                }
                                                self.dataSource = ds;
                                                [[Authentication sharedInstance] synchronize];
                                            }
                                            
                                        } failure:^{
                                            if (isLoading) {
                                                [self stopLoading];
                                            }
                                        }];	
}

- (void) addFollowing {
    UserListViewController* vc = [[UserListViewController alloc] init];
    vc.baseURL = [NSString stringWithFormat:@"%@://%@/api/v1/user/%d/recommendations/?format=json", HTTPS, EOHOST, [Authentication sharedInstance].currentUser.uID];
    [self.navigationController pushViewController:vc animated:YES];
}

- (id<UITableViewDelegate>)createDelegate {
    return self;
}

#pragma mark UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    id<TTTableViewDataSource> dataSource = (id<TTTableViewDataSource>)tableView.dataSource;
    id object = [dataSource tableView:tableView objectForRowAtIndexPath:indexPath];
    if ([object isKindOfClass:[UserTableItem class]]) {
        UserProfile *profile = ((UserTableItem *)[[(UserListDataSource*)self.dataSource items] objectAtIndex:indexPath.row]).profile;
        NewUserDetailsViewController *detailVC = [[NewUserDetailsViewController alloc] initWithStyle:UITableViewStylePlain];
        detailVC.user = profile;
        detailVC.delegate = self;
        [self.navigationController pushViewController:detailVC
                                             animated:YES];
    } else if ([object isKindOfClass:[LoadMoreTableItem class]]){
        if (_loadMore.loading) {
            return;
        }
        _loadMore.loading = YES;
        [self reloadLastRow];
        [self loadMoreFollowings];
    }
}
-(void)reloadLastRow{
    UserListDataSource *ds = self.dataSource;
    NSArray *lastRow = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:(ds.items.count - 1) inSection:0]];
    [self.tableView reloadRowsAtIndexPaths:lastRow withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

#pragma mark UserDetailViewControllerDelegate
-(void)userFollowed:(UserProfile*)user{
    [self.tableView reloadData];
}

-(void)userUnfollowed:(UserProfile*)user{
    [self.tableView reloadData];
}
#pragma  mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 0) {
        [self addFollowing];
    }
}

#pragma mark -
#pragma mark PullRefreshTableViewController

- (void)pullToRefresh {
    if (_seg.selectedSegmentIndex == 0) {
        [self requestFollowings];
    } else {
        [self requestFeeds];
    }
}
@end
