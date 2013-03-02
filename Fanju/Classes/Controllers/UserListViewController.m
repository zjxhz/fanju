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
#import "NSDictionary+ParseHelper.h"
#import "NetworkHandler.h"
#import "NewUserDetailsViewController.h"
#import "SVProgressHUD.h"
#import "UserDetailViewController.h"
#import "UserListDataSource.h"
#import "UserListViewController.h"
#import "UserProfile.h"
#import "UserTableItem.h"
#import "UserTableItemCell.h"

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
    return self;
}


- (void)loadView {
    [super loadView];
    
    
    AppDelegate *delegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    self.tableView.backgroundColor = [UIColor colorWithPatternImage:delegate.bgImage]; 
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"自定义" style:UIBarButtonItemStyleBordered target:self action:@selector(filter:)];
    _customUserFilterViewController = [[CustomUserFilterViewController alloc] initWithNibName:@"CustomUserFilterViewController" bundle:nil];
    _customUserFilterViewController.delegate = self;
    self.autoresizesForKeyboard = YES;
    self.variableHeightRows = YES;    
}

-(void)filter:(id)sender{
    UIActionSheet *actions = [[UIActionSheet alloc] initWithTitle:@"筛选" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"全部",@"男",@"女",@"自定义", nil];
    [actions showInView:self.view];    
}


-(void)loadUsers{
    _loading = YES;
    NSString* urlWithFilter = _baseURL;
    if (_filter) {
        urlWithFilter = [NSString stringWithFormat:@"%@&%@", self.baseURL, _filter];
    }
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
                                            [self.tableView reloadData];
                                            if (isLoading) {
                                                [self stopLoading];
                                            }
                                            _loading = NO;
                                        } failure:^{
                                            if (isLoading) {
                                                [self stopLoading];
                                            }
                                            _loading = NO;
                                            [SVProgressHUD dismissWithError:@"获取数据失败"];
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
                                            NSLog(@"failed to load more orders");
#warning fail handling
                                        }];
}

-(void)setFilter:(NSString*)newFilter{
    //not both nil and not equals
    if (newFilter != _filter && ![newFilter isEqual:_filter]) {
        _filter = newFilter;
    }
    
    if (!_loading) {
        [self loadUsers];
    }
}

-(void)setBaseURL:(NSString *)baseURL{
    if (baseURL != _baseURL && ![baseURL isEqualToString:_baseURL]){
        _baseURL = baseURL;
    }
    
    if (!_loading) {
        [self loadUsers];
    }
}

- (id<UITableViewDelegate>)createDelegate {
    return self;
}

#pragma mark UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60.0;
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
            nav = [[UINavigationController alloc] initWithRootViewController:_customUserFilterViewController];
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
-(void)filterSelected:(NSString *)filter{
    [self setFilter:filter];
}

#pragma mark -
#pragma mark PullRefreshTableViewController
- (void)pullToRefresh {
    [self loadUsers];
}

@end
