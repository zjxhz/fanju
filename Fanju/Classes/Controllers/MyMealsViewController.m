//
//  MyMealsViewController.m
//  EasyOrder
//
//  Created by 浣泽 徐 on 4/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MyMealsViewController.h"
#import "OrderTableItem.h"
#import "MealTableItemCell.h"
#import "MealThumbnailTableItemCell.h"
#import "WEPopoverController.h"
#import "NetworkHandler.h"
#import "Const.h"
#import "NSDictionary+ParseHelper.h"
#import "AppDelegate.h"
#import "MealInvitation.h"
#import "MealInvitationTableItem.h"
#import "MealInvitationTableItemCell.h"
#import "SCAppUtils.h"
#import "OrderDetailsViewController.h"
#import "Authentication.h"
#import "LoadMoreTableItem.h"
#import "LoadMoreTableItemCell.h"

@interface OrderListDataSource : TTListDataSource

@end

@implementation OrderListDataSource

- (Class)tableView:(UITableView*)tableView cellClassForObject:(id) object {
    
	if ([object isKindOfClass:[OrderTableItem class]]) {  
		return [MealThumbnailTableItemCell class];  
	} else if ([object isKindOfClass:[LoadMoreTableItem class]]){
        return [LoadMoreTableItemCell class];
    }
    
	return [super tableView:tableView
	     cellClassForObject:object];
}

@end

@interface MyInvitationsDataSource : TTListDataSource 

@end

@implementation MyInvitationsDataSource

- (Class)tableView:(UITableView*)tableView cellClassForObject:(id) object {
    
	if ([object isKindOfClass:[MealInvitationTableItem class]]) {  
		return [MealInvitationTableItemCell class];  
	}
    
	return [super tableView:tableView
	     cellClassForObject:object];
}
@end

@implementation MyMealsViewController


- (id) init{
    if (self = [super init]) {        
        self.title = @"我的饭局";
        self.tabBarItem = [[UITabBarItem alloc] initWithTitle:self.title image:[UIImage imageNamed:@"messages.png"] tag:0]; 
    }
    return self;
}
- (void)loadView {
    [super loadView];
    AppDelegate *delegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    self.tableView.backgroundColor = [UIColor colorWithPatternImage:delegate.bgImage]; 
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.variableHeightRows = YES;
    UISegmentedControl *seg = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"我的饭局", @"饭局邀请", nil]];
    seg.segmentedControlStyle = UISegmentedControlStyleBar;
    [seg setSelectedSegmentIndex:0];
    [seg addTarget:self action:@selector(selectionChanged:) forControlEvents:UIControlEventValueChanged];
    self.navigationItem.titleView = seg;
}

-(void) selectionChanged:(id)sender{
    UISegmentedControl *seg = sender;
    if (seg.selectedSegmentIndex == 1) {
        UIAlertView *a = [[UIAlertView alloc] initWithTitle:@"未实现" message:@"未实现功能" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
        [a show];
        seg.selectedSegmentIndex = 0;
    }
}
-(void) loadOrders{
    int userID = [Authentication sharedInstance].currentUser.uID;
    NSString* baseURL = [NSString stringWithFormat:@"http://%@/api/v1/user/%d/order/?format=json", EOHOST, userID] ;
    [[NetworkHandler getHandler] requestFromURL:baseURL method:GET cachePolicy:TTURLRequestCachePolicyNetwork
                                        success:^(id obj) {
                                            NSDictionary *result = obj;
                                            NSArray *orders = [result objectForKeyInObjects];
                                            
                                            OrderListDataSource *ds = [[OrderListDataSource alloc] init];
                                            
                                            for (NSDictionary *dict in orders) {
                                                [ds.items addObject:[OrderTableItem itemWithOrderInfo:[OrderInfo orderInfoWithData:dict]]];
                                            }     
                                            NSInteger offset = [result offset];
                                            NSInteger totalCount = [result totalCount];
                                            NSInteger limit = [result limit];
                                            
                                            if (limit != 0 && totalCount > limit) {
                                                _loadMore  = [LoadMoreTableItem itemWithText:@"加载更多"] ;
                                                _loadMore.offset = offset;
                                                _loadMore.amount = totalCount;
                                                _loadMore.limit = limit;
                                                _loadMore.baseURL = baseURL;
                                                [ds.items addObject:_loadMore];
                                            }
                                            self.dataSource = ds;
                                            
                                        } failure:^{
#warning fail handling
                                        }];
}

-(void) loadMoreOrders{
    if (![_loadMore hasMore]) {
        return;
    } 
    [[NetworkHandler getHandler] requestFromURL:[_loadMore nextPageURL]
                                         method:GET 
                                    cachePolicy:TTURLRequestCachePolicyNetwork
                                        success:^(id obj) {
                                            //load data
                                            NSDictionary* result = obj;
                                            NSArray *orders = [obj objectForKeyInObjects];
                                            OrderListDataSource *ds = self.dataSource;
                                            NSMutableArray * indexPaths = [NSMutableArray array];
                                            for (int i = 0; i < orders.count; ++i) {
                                                NSDictionary *dict = [orders objectAtIndex:i];
                                                [ds.items insertObject:[OrderTableItem itemWithOrderInfo:[OrderInfo orderInfoWithData:dict]] atIndex:(ds.items.count - 1)];
                                                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:ds.items.count - 1 inSection:0];
                                                [indexPaths addObject:indexPath];
                                            }
                                            [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
                                            
                                            
                                            //update load more text and decide if it should be removed
                                             _loadMore.loading = NO;
//                                            [self reloadLastRow];
                                            _loadMore.offset = [result offset];
                                            if (![_loadMore hasMore])  {
                                                [ds.items removeLastObject];
                                                NSArray *rowToDelete = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:(ds.items.count - 1) inSection:0]];
                                                [self.tableView  deleteRowsAtIndexPaths:rowToDelete withRowAnimation:UITableViewRowAnimationAutomatic];
                                            } else {
                                                _loadMore.text = @"加载更多" ;
                                            }
                                            [self.tableView reloadData];
                                            
                                        } failure:^{
                                            NSLog(@"failed to load more orders");
#warning fail handling
                                        }];
}

- (void)loadInvitationsWithOffset:(NSInteger)offset{
    int userID = [Authentication sharedInstance].currentUser.uID;
    [[NetworkHandler getHandler] requestFromURL:[NSString stringWithFormat:@"http://%@/api/v1/user/%d/invitation/?format=json", EOHOST, userID] 
                                         method:GET cachePolicy:TTURLRequestCachePolicyNetwork
                                       success:^(id obj) {
                                            NSArray *invitations = [obj objectForKeyInObjects];
                                            if (invitations) {
                                                MyInvitationsDataSource *ds = [[MyInvitationsDataSource alloc] init];
                                                for (NSDictionary *dict in invitations) {
                                                    [ds.items addObject:[MealInvitationTableItem itemWithMealInvitation:[MealInvitation mealInvitationWithData:dict]]];
                                                }
                                                self.dataSource = ds;
                                            }
                                        } failure:^{
                                            
                                        }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [SCAppUtils customizeNavigationController:self.navigationController];
    [self loadOrders];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (id<UITableViewDelegate>)createDelegate {
    return self;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
     MyInvitationsDataSource *ds = self.dataSource;
    if ([_loadMore hasMore] && indexPath.row == ds.items.count - 1) {
        return 50;
    }
    return 125.0;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    //tableview will change position when back from login screen, set it right
    self.tableView.frame = self.view.frame;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    id obj = [self.dataSource tableView:tableView objectForRowAtIndexPath:indexPath];
    if ([obj isKindOfClass:[OrderTableItem class]]) {
        OrderTableItem *item = obj;
        OrderInfo* order = item.orderInfo;
        OrderDetailsViewController *details = [[OrderDetailsViewController alloc] initWithNibName:@"OrderDetailsViewController" bundle:nil];
        details.meal = order.meal;
        details.code = order.code;
        details.numerOfPersons = order.numerOfPersons;
        [self.navigationController pushViewController:details
                                             animated:YES];
    } else if ([obj isKindOfClass:[LoadMoreTableItem class]]){
        if (_loadMore.loading) {
            return;
        }
        _loadMore.text = @"加载中……";
        _loadMore.loading = YES;
        [self reloadLastRow];
        [self loadMoreOrders];
    }
}

-(void)reloadLastRow{
    MyInvitationsDataSource *ds = self.dataSource;
    NSArray *lastRow = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:(ds.items.count - 1) inSection:0]];
    [self.tableView reloadRowsAtIndexPaths:lastRow withRowAnimation:UITableViewRowAnimationAutomatic]; 
}

@end
