//
//  MyMealsViewController.m
//  EasyOrder
//
//  Created by 浣泽 徐 on 4/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MyMealsViewController.h"
#import "MealThumbnailTableItemCell.h"
#import "WEPopoverController.h"
#import "NetworkHandler.h"
#import "Const.h"
#import "NSDictionary+ParseHelper.h"
#import "AppDelegate.h"
#import "MealInvitation.h"
#import "MealInvitationTableItem.h"
#import "MealInvitationTableItemCell.h"
#import "OrderDetailsViewController.h"
#import "Authentication.h"
#import "LoadMoreTableItem.h"
#import "LoadMoreTableItemCell.h"
#import "AKSegmentedControl.h"
#import "OrderListDataSource.h"
#import "ODRefreshControl.h"
#import "MealDetailViewController.h"

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

@implementation MyMealsViewController{
    ODRefreshControl* _refreshControl;
}


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
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.variableHeightRows = YES;
    
    UIImage* myMealsImg = [UIImage imageNamed:@"seg_meals"];
    UIImage* mealInvitationImg = [UIImage imageNamed:@"seg_invitation"];
    UIImage* myMealsPushImg = [UIImage imageNamed:@"seg_meals_push"];
    UIImage* mealInvitationPushImg = [UIImage imageNamed:@"seg_invitation_push"];
    
    AKSegmentedControl *seg = [[AKSegmentedControl alloc] initWithFrame:CGRectMake(0, 0, myMealsImg.size.width + mealInvitationImg.size.width, myMealsImg.size.height)];
    seg.segmentedControlMode = AKSegmentedControlModeSticky;
    [seg setSelectedIndex:0];
    UIButton* bl = [self createSegmentButton:@"我的饭局" withNormalImage:myMealsImg pushImage:myMealsPushImg];
    UIButton* br = [self createSegmentButton:@"饭局邀请" withNormalImage:mealInvitationImg pushImage:mealInvitationPushImg];
    [seg setButtonsArray:@[bl, br]];
    [seg addTarget:self action:@selector(selectionChanged:) forControlEvents:UIControlEventValueChanged];
    self.navigationItem.titleView = seg;
    
    _refreshControl = [[ODRefreshControl alloc] initInScrollView:self.tableView];
    [_refreshControl addTarget:self action:@selector(loadOrders) forControlEvents:UIControlEventValueChanged];
}

-(UIButton*)createSegmentButton:(NSString*)title withNormalImage:(UIImage*)push pushImage:(UIImage*)normal{
    UIButton* b = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, normal.size.width, normal.size.height)];
    b.titleLabel.font = [UIFont systemFontOfSize:12];
    [b setTitleColor:RGBCOLOR(80, 80, 80) forState:UIControlStateNormal];
    [b setTitleColor:RGBCOLOR(220, 220, 220) forState: UIControlStateSelected];
    [b setTitleColor:RGBCOLOR(220, 220, 220) forState:UIControlStateHighlighted];
    [b setTitleColor:RGBCOLOR(220, 220, 220) forState:UIControlStateHighlighted | UIControlStateSelected];
    [b setTitleShadowColor:RGBACOLOR(0, 0, 0, 0.4) forState:UIControlStateHighlighted];
    [b setTitleShadowColor:RGBACOLOR(0, 0, 0, 0.2) forState:UIControlStateNormal];
    [b setBackgroundImage:normal forState:UIControlStateNormal];
    [b setBackgroundImage:push forState:UIControlStateSelected];
    [b setBackgroundImage:push forState:UIControlStateHighlighted];
    [b setBackgroundImage:push forState:UIControlStateSelected | UIControlStateHighlighted];
    [b setTitle:title forState:UIControlStateNormal];
    return b;
}

-(void) selectionChanged:(id)sender{
//    AKSegmentedControl *seg = sender;
//    if (seg.selectedIndexes.firstIndex == 1) {
//        UIAlertView *a = [[UIAlertView alloc] initWithTitle:@"未实现" message:@"未实现功能" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
//        [a show];
//        seg.selectedIndexes = [NSIndexSet indexSetWithIndex:0];
//    }
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
                                                [ds addOrder:[OrderInfo orderInfoWithData:dict]];
                                            }     
                                            NSInteger offset = [result offset];
                                            NSInteger totalCount = [result totalCount];
                                            NSInteger limit = [result limit];
                                            
                                            if (limit != 0 && totalCount > limit) {
                                                _loadMore  = [[LoadMoreTableItem alloc] init] ;
                                                _loadMore.offset = offset;
                                                _loadMore.amount = totalCount;
                                                _loadMore.limit = limit;
                                                _loadMore.baseURL = baseURL;
//                                                [ds.items addObject:_loadMore];
                                            }
                                            self.dataSource = ds;
                                            [_refreshControl endRefreshing];
                                            
                                        } failure:^{
                                            [_refreshControl endRefreshing];
                                            NSLog(@"failed to load orders");
                                        }];
}

//-(void) loadMoreOrders{
//    if (![_loadMore hasMore]) {
//        return;
//    } 
//    [[NetworkHandler getHandler] requestFromURL:[_loadMore nextPageURL]
//                                         method:GET 
//                                    cachePolicy:TTURLRequestCachePolicyNetwork
//                                        success:^(id obj) {
//                                            //load data
//                                            NSDictionary* result = obj;
//                                            NSArray *orders = [obj objectForKeyInObjects];
//                                            OrderListDataSource *ds = self.dataSource;
//                                            NSMutableArray * indexPaths = [NSMutableArray array];
//                                            for (int i = 0; i < orders.count; ++i) {
//                                                NSDictionary *dict = [orders objectAtIndex:i];
//                                                [ds.items insertObject:[OrderTableItem itemWithOrderInfo:[OrderInfo orderInfoWithData:dict]] atIndex:(ds.items.count - 1)];
//                                                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:ds.items.count - 1 inSection:0];
//                                                [indexPaths addObject:indexPath];
//                                            }
//                                            [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
//                                            
//                                            
//                                            //update load more text and decide if it should be removed
//                                             _loadMore.loading = NO;
////                                            [self reloadLastRow];
//                                            _loadMore.offset = [result offset];
//                                            if (![_loadMore hasMore])  {
//                                                [ds.items removeLastObject];
//                                                NSArray *rowToDelete = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:(ds.items.count - 1) inSection:0]];
//                                                [self.tableView  deleteRowsAtIndexPaths:rowToDelete withRowAnimation:UITableViewRowAnimationAutomatic];
//                                            }
//                                            [self.tableView reloadData];
//                                            
//                                        } failure:^{
//                                            NSLog(@"failed to load more orders");
//#warning fail handling
//                                        }];
//}

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
    _payingOrdersHeader = [self createHeader:@"30分钟内未支付的饭局"];
    _upcomingOrdersHeader = [self createHeader:@"最近的饭局"];
    _passedOrdersHeader = [self createHeader:@"已经结束的饭局"];
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
    return 23;
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    OrderListDataSource* ds = self.dataSource;
    if (section == 0) {
        if (ds.payingOrders.count > 0) {
            return _payingOrdersHeader;
        } else if(ds.upcomingOrders.count > 0){
            return _upcomingOrdersHeader;
        } else {
            return _passedOrdersHeader;
        }
    } else if(section == 1){
        if(ds.payingOrders.count > 0){
            return ds.upcomingOrders.count > 0 ? _upcomingOrdersHeader : _passedOrdersHeader;
        } else {
            return _passedOrdersHeader;
        }
    } else {
        return _passedOrdersHeader;
    }
}

-(UIView*)createHeader:(NSString*)text{
    UIView* view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 22)];
    view.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
    UIImage* clockImage = [UIImage imageNamed:@"title_time"];
    UIImageView *clockImageView = [[UIImageView alloc] initWithImage:clockImage];
    clockImageView.frame = CGRectMake(9, 5, clockImage.size.width, clockImage.size.height);
    CGFloat x = clockImageView.frame.origin.x + clockImageView.frame.size.width + 6;
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(x, 0, 250, 23)];
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


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
     MyInvitationsDataSource *ds = self.dataSource;
    if ([_loadMore hasMore] && indexPath.row == ds.items.count - 1) {
        return 50;
    }
    return 123.0;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    //tableview will change position when back from login screen, set it right
    self.tableView.frame = self.view.frame;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    id obj = [self.dataSource tableView:tableView objectForRowAtIndexPath:indexPath];
    if ([obj isKindOfClass:[OrderInfo class]]) {
        
        OrderInfo* order = obj;
        if (order.status == 1) {//unpaid
            MealDetailViewController* mealVC = [[MealDetailViewController alloc] init];
            mealVC.unfinishedOrder = order;
            mealVC.mealInfo = order.meal;
            [self.navigationController pushViewController:mealVC animated:YES];
        } else {
            OrderDetailsViewController *details = [[OrderDetailsViewController alloc] initWithNibName:@"OrderDetailsViewController" bundle:nil];
            details.order = order;
            [self.navigationController pushViewController:details
                                                 animated:YES];
        }
    } else if ([obj isKindOfClass:[LoadMoreTableItem class]]){
        if (_loadMore.loading) {
            return;
        }
        _loadMore.loading = YES;
        [self reloadLastRow];
//        [self loadMoreOrders];
    }
}

-(void)reloadLastRow{
    MyInvitationsDataSource *ds = self.dataSource;
    NSArray *lastRow = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:(ds.items.count - 1) inSection:0]];
    [self.tableView reloadRowsAtIndexPaths:lastRow withRowAnimation:UITableViewRowAnimationAutomatic]; 
}

@end
