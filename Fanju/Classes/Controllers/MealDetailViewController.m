//
//  MealDetailViewController.m
//  EasyOrder
//
//  Created by igneus on 3/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MealDetailViewController.h"
#import "AppDelegate.h"
#import "NetworkHandler.h"
#import "Const.h"
#import "SVProgressHUD.h"
#import "Location.h"
#import "LocationProvider.h"
#import "AvatarFactory.h"
#import "MealComment.h"
#import "NSDictionary+ParseHelper.h"
#import "DateUtil.h"
#import <objc/runtime.h>
#import "InfoUtil.h"
#import "WBSendView.h"
#import "Authentication.h"
#import "SpeechBubble.h"
#import "ClosablePopoverViewController.h"
#import "OverlayViewController.h"
#import "NINetworkImageView.h"
#import "MapViewController.h"
#import "WidgetFactory.h"
#import "OrderDetailsViewController.h"
#import "JoinMealViewController.h"
#import "NewSidebarViewController.h"
#import "UserService.h"
#import "Restaurant.h"
#import "Order.h"
#import "CMPopTipView.h"
#import "MealDetailDataSource.h"
#import "MealDetailCell.h"

@implementation MealDetailViewController{
//    MealDetailsViewDelegate* _mealDetailsViewDelegate;
    Order* _myOrder;

    CMPopTipView *_navBarLeftButtonPopTipView;
    UIButton* _commentButton;
    NINetworkImageView *_mealImageView;
}

-(id)init{
    if (self = [super init]) {
//        _mealDetailsViewDelegate = [[MealDetailsViewDelegate alloc] init];
    }
    return self;
}

-(void) loadView{
    [super loadView];
    AppDelegate *delegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    self.tableView.backgroundColor = [UIColor colorWithPatternImage:delegate.bgImage];   
    [self initTabView];
}


-(void)viewOrder:(id)sender{
    OrderDetailsViewController *orderVC = [[OrderDetailsViewController alloc] init];
    orderVC.order = _myOrder;
    [self.navigationController pushViewController:orderVC animated:YES];
}



- (void)initTabView {
    UIImage* toolbarShadow = [UIImage imageNamed:@"toolbar_shadow"];
    _tabBar = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - TAB_BAR_HEIGHT, self.view.frame.size.width, TAB_BAR_HEIGHT)];
    _tabBar.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"toolbar_bg"]];
    UIImage* join_img = [UIImage imageNamed:@"toolbth1"];
    UIImage* comment_img = [UIImage imageNamed:@"meal_comment"];
    CGFloat x = (320 - join_img.size.width - comment_img.size.width) / 2;
    CGFloat y = (_tabBar.frame.size.height - join_img.size.height) / 2;
    _joinButton = [[UIButton alloc] initWithFrame:CGRectMake(x, y, join_img.size.width, join_img.size.height)];
    [_joinButton setBackgroundImage:join_img forState:UIControlStateNormal];    _joinButton.titleLabel.textAlignment  = UITextAlignmentCenter;
    _joinButton.titleLabel.textColor = [UIColor whiteColor];
    _joinButton.titleLabel.font = [UIFont boldSystemFontOfSize:19];

    if (_unfinishedOrder) {
        [_joinButton setTitle:@"去支付" forState:UIControlStateNormal];
        [_joinButton addTarget:self action:@selector(finishOrder:) forControlEvents:UIControlEventTouchDown];
    }
    
    x = _joinButton.frame.origin.x + _joinButton.frame.size.width;
    _commentButton = [[UIButton alloc] initWithFrame:CGRectMake(x, y, comment_img.size.width, comment_img.size.height)];
    [_commentButton setBackgroundImage:comment_img forState:UIControlStateNormal];
    
    [_tabBar addSubview:_joinButton];
    [_tabBar addSubview:_commentButton];
    [self.view addSubview:_tabBar];
    
    UIImageView* shadowView = [[UIImageView alloc] initWithFrame:CGRectMake(0, -toolbarShadow.size.height, toolbarShadow.size.width, toolbarShadow.size.height)];
    shadowView.image = toolbarShadow;
    [_tabBar addSubview:shadowView];
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    [self buildUI];
}

-(void)buildUI{
    self.tableView.showsVerticalScrollIndicator = NO;
    self.navigationItem.titleView = [[WidgetFactory sharedFactory]titleViewWithTitle:_meal.topic];
    self.navigationItem.rightBarButtonItem = [[WidgetFactory sharedFactory]normalBarButtonItemWithTitle:@"分享" target:self action:@selector(onShareClicked:)];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    MealDetailDataSource* ds = [[MealDetailDataSource alloc] init];
    ds.meal = _meal;
    ds.controller = self;
    self.dataSource = ds;
}

-(void)viewWillAppear:(BOOL)animated{
//    _mealDetailsViewDelegate.detailsHeight = _detailsView.frame.size.height;
    if (!_unfinishedOrder) {
        [self updateJoinButton];
    }
    [self.tableView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    [super viewWillAppear:animated];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.tableView removeObserver:self forKeyPath:@"contentOffset"];
}

-(void)updateJoinButton{
    User* loggedInUser = [UserService service].loggedInUser;
    for (Order* order in _meal.orders) {
        if ([order.user isEqual:loggedInUser]) {
            _myOrder = order;
            [_joinButton setTitle:@"已支付，查看订单" forState:UIControlStateNormal];
            [_joinButton addTarget:self action:@selector(viewOrder:) forControlEvents:UIControlEventTouchDown];
            return;
        }
    }
    NSDate* time = [MealService dateOfMeal:_meal];
    if([time compare:[NSDate date]] == NSOrderedAscending){
        [_joinButton setTitle:@"已结束" forState:UIControlStateNormal];
    }  else if ([self.meal.actualPersons integerValue] >= [self.meal.maxPersons integerValue]) {
        [_joinButton setTitle:@"卖光了" forState:UIControlStateNormal];
        [_joinButton setBackgroundImage:[UIImage imageNamed:@"sold_out"] forState:UIControlStateNormal];
        [_commentButton setBackgroundImage:[UIImage imageNamed:@"meal_comment_sold_out"] forState:UIControlStateNormal];
        [_joinButton removeTarget:self action:@selector(joinMeal:) forControlEvents:UIControlEventTouchDown];
    } else {
        [_joinButton setTitle:@"参加饭局" forState:UIControlStateNormal];
        [_joinButton addTarget:self action:@selector(joinMeal:) forControlEvents:UIControlEventTouchDown];
    }
}

-(void)finishOrder:(id)sender{
    JoinMealViewController* vc = [[JoinMealViewController alloc] init];
    vc.meal = self.meal;
    vc.numberOfPersons = [_unfinishedOrder.numberOfPersons integerValue];
    [self.navigationController pushViewController:vc animated:YES];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    CGRect frame = self.tableView.frame;
    frame.size.height = self.view.frame.size.height - TAB_BAR_HEIGHT; 
    self.tableView.frame = frame;
}

-(void)createLoadingView{
    _loadingOrNoCommentsLabel= [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, 20)];
    _loadingOrNoCommentsLabel.backgroundColor = [UIColor clearColor];
    _loadingOrNoCommentsLabel.textColor = [UIColor blackColor];
    _loadingOrNoCommentsLabel.font = [UIFont boldSystemFontOfSize:12];
    _loadingOrNoCommentsLabel.text = NSLocalizedString(@"Loading", nil);
    _loadingOrNoCommentsLabel.textAlignment = UITextAlignmentCenter;
}

//removing reloading view when the data is avaialbe, note that the
-(void)removeLoadingView{
    TTSectionedDataSource *ds = self.dataSource; 
    int lastSection = ds.sections.count - 1;
    [[ds.items objectAtIndex:lastSection] removeLastObject]; 
    NSIndexPath *path = [NSIndexPath indexPathForRow:0 inSection:lastSection];
    [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:path] withRowAnimation:UITableViewRowAnimationNone];

}

- (UIView*) createCommentView:(MealComment*) comment{
    int height = ((comment.from_person.username.length + comment.comment.length)  / 15 + 1) * 20;
    UIView *commentsView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, height + 30)];
    UIImageView* userView = [AvatarFactory avatarForUser:comment.from_person frame:CGRectMake(8, 8, 41, 41)];
    [commentsView addSubview:userView];
    
    SpeechBubble* speechBubble = [[SpeechBubble alloc] initWithText:[NSString stringWithFormat:@"%@: %@",comment.from_person.name, comment.comment] font:[UIFont boldSystemFontOfSize:15] origin:CGPointMake(50, 5) pointLocation:30 width:245];
    [commentsView addSubview:speechBubble];
    
    
    UILabel *time = [[UILabel alloc] initWithFrame:CGRectMake(60, height + 20, 120, 20)];
    time.text = [DateUtil shortStringFromDate:comment.time];
    time.font  = [UIFont systemFontOfSize:12];
    time.backgroundColor  =  [UIColor clearColor];
    time.textColor = [UIColor grayColor];
    [commentsView addSubview:time];
    
    return commentsView;
}

- (id<UITableViewDelegate>)createDelegate {
    return [[TTTableViewVarHeightDelegate alloc] init];
}

- (IBAction)joinMeal:(id)sender {
    if(![[Authentication sharedInstance] isLoggedIn]) {        
        // not logged in
        AppDelegate *delegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
        [delegate showLogin];
    } else {
        JoinMealViewController* vc = [[JoinMealViewController alloc] init];
        vc.meal = self.meal;
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (void) onShareClicked:(id)sender{
    [self shareToSinaWeibo];
//    if (_shareContentViewController == nil) {
//        _shareContentViewController = [[ShareTableViewController alloc] initWithStyle:UITableViewStylePlain];
//        _shareContentViewController.delegate = self;
//        _sharePopOver = [[WEPopoverController alloc] initWithContentViewController:_shareContentViewController];
//    }
//    [_sharePopOver presentPopoverFromBarButtonItem:self.navigationItem.rightBarButtonItem permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}

- (SinaWeibo *)sinaweibo{
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
//    appDelegate.sinaweibo.delegate = self;
    return appDelegate.sinaweibo;
}

#pragma mark _
#pragma mark ShareToDelegate
-(void)shareToSinaWeibo{
    [_sharePopOver dismissPopoverAnimated:YES];
    if (![[self sinaweibo] isLoggedIn]) {
        [[self sinaweibo] logIn];
    } else {
        [self sendWeiBo];
    }
}

-(void) sendWeiBo{
//    UIImage* image = [[Nimbus imageMemoryCache] objectWithName:[URLService  absoluteURL:_meal.photoURL]];
    MealDetailCell* detailsCell = (MealDetailCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    UIImage* image = detailsCell.mealImageView.image;
    NSString *defaultMessage = [NSString stringWithFormat:@"一个有趣的饭局：%@ http://%@/meal/%@/", _meal.topic, EOHOST, _meal.mID];
//    UIImage* image = _mealImageView.image;
    WBSendView *sendView = [[WBSendView alloc] initWithAppKey:WEIBO_APP_KEY appSecret:WEIBO_APP_SECRET text:defaultMessage image:image];
    sendView.delegate = self;
    sendView.backgroundColor = [UIColor whiteColor];
    [sendView show:YES];
}
#pragma mark _
#pragma mark SinaWeiboDelegate
- (void)sinaweiboDidLogIn:(SinaWeibo *)sinaweibo{
    [self sendWeiBo];     
}

-(void)sinaweibo:(SinaWeibo *)sinaweibo logInDidFailWithError:(NSError *)error{
    DDLogError(@"failed to login to sina weibo: %@", error.description);
}

#pragma mark _
#pragma mark WBSendViewDelegate
-(void)sendViewDidStartSending:(WBSendView *)view{
    [SVProgressHUD showWithStatus:@"正在发送" maskType:SVProgressHUDMaskTypeBlack];
}
- (void)sendViewDidFinishSending:(WBSendView *)view{
    [SVProgressHUD showSuccessWithStatus:@"发送成功！"];
    [view hide:YES];
}

- (void)sendView:(WBSendView *)view didFailWithError:(NSError *)error{
    [SVProgressHUD showErrorWithStatus:@"发送失败，请稍后重试"];
    DDLogVerbose(@"send weibo message failed with error: %@", error);
}

- (void)sendViewNotAuthorized:(WBSendView *)view{
    DDLogError(@"sending weibo while not authorized");
}

- (void)sendViewAuthorizeExpired:(WBSendView *)view{
    DDLogError(@"sending weibo while authorization expired");
}

#pragma mark NSObject
-(NSString*)description{
    return [NSString stringWithFormat:@"class: %@, %@", [self class], [super description]];
}

#pragma mark Key-Value observer
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    CGFloat offset = [[change objectForKey:@"new"] CGPointValue].y;
    MealDetailDataSource* ds = self.dataSource;
    [ds tableView:self.tableView contentOffsetDidChange:offset];
//    CGRect frame = _mealImageView.frame;
//    frame.origin.y = offset;
//    frame.size.height = DISH_VIEW_HEIGHT - offset;
//    _mealImageView.frame = frame;
    
}


@end


