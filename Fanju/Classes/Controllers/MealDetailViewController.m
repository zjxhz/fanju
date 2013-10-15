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
#import "UserService.h"
#import "User.h"
#import "UIImage+Resize.h"
#import "DictHelper.h"

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

-(void) loadComments{
    RKObjectManager* manager = [RKObjectManager sharedManager];
    NSString* path = [NSString stringWithFormat:@"mealcomment/"];
    [manager getObjectsAtPath:path
                   parameters:@{@"limit":@"0", @"meal":_meal.mID}
                      success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                          _modelError = nil;
                          //set meal to comment as the meal info is not included in the result message
                          for (MealComment* comment in mappingResult.array) {
                              comment.meal = _meal;
                          }
                          RKManagedObjectStore* store = [RKObjectManager sharedManager].managedObjectStore;
                          NSManagedObjectContext* context = store.mainQueueManagedObjectContext;
                          NSError* error;
                          if(![context saveToPersistentStore:&error]){
                              DDLogError(@"failed to set meal for comments: %@", error);
                          }
                          DDLogVerbose(@"fetched comments from %@", path);
                          MealDetailDataSource *ds = self.dataSource;
                          ds.comments = [NSMutableArray arrayWithArray:mappingResult.array];
                          [self.tableView reloadData];
                          dispatch_async(dispatch_get_main_queue(), ^{
                              if (_scrollToComment) {
                                  NSIndexPath* indexPath = [ds tableView:self.tableView indexPathForObject:_scrollToComment];
                                  if (indexPath) { //comments can be deleted or not approved
                                      NSInteger maxRow = [self.tableView numberOfRowsInSection:1] - 1;
                                      if (indexPath.row > maxRow) {
                                          DDLogError(@"trying to scroll to row %d which is out of scope: %d", indexPath.row, maxRow);
                                      } else {
                                          [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:NO];
                                          UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
                                          UIColor* originalColor = cell.backgroundColor;
                                          cell.backgroundColor = [UIColor orangeColor];
                                          [UIView animateWithDuration:0.6 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^
                                           {
                                               cell.backgroundColor = originalColor;
                                           } completion: nil];
                                      }
                                  } else {
                                      if ([self.navigationController visibleViewController] == self) {
                                          [InfoUtil showAlert:@"评论已经被用户删除"];
                                      }
                                  
                                  }
                              }
                          });
                      }
                      failure:^(RKObjectRequestOperation *operation, NSError *error) {
                          if ([self.navigationController visibleViewController] == self) {
                              [SVProgressHUD showErrorWithStatus:@"评论加载失败，请重试"];
                          }
                          MealDetailDataSource *ds = self.dataSource;
                          ds.loadFail = YES;
                          DDLogError(@"failed from %@: %@", path, error);
                      }];
}

-(void)viewOrder:(id)sender{
    OrderDetailsViewController *orderVC = [[OrderDetailsViewController alloc] init];
    orderVC.order = _myOrder;
    [self.navigationController pushViewController:orderVC animated:YES];
}



- (void)initTabView {
    UIImage* toolbarShadow = [UIImage imageNamed:@"toolbar_shadow"];
    _tabBar = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - TAB_BAR_HEIGHT, self.view.bounds.size.width, TAB_BAR_HEIGHT)];
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
    [_commentButton addTarget:self action:@selector(commentOnMeal:) forControlEvents:UIControlEventTouchUpInside];
    [_commentButton setBackgroundImage:comment_img forState:UIControlStateNormal];
    
    [_tabBar addSubview:_joinButton];
    [_tabBar addSubview:_commentButton];
    [self.view addSubview:_tabBar];
    
    UIImageView* shadowView = [[UIImageView alloc] initWithFrame:CGRectMake(0, -toolbarShadow.size.height, toolbarShadow.size.width, toolbarShadow.size.height)];
    shadowView.image = toolbarShadow;
    [_tabBar addSubview:shadowView];
    _tabBar.hidden = YES;
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    [self buildUI];
}

-(void)commentOnMeal:(id)sender{
    SendCommentViewController* vc = [[SendCommentViewController alloc] init];
    vc.sendCommentDelegate = self;
    vc.meal = _meal;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentModalViewController:nav animated:YES];
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
    [self loadComments];
}

-(void)viewWillAppear:(BOOL)animated{
//    _mealDetailsViewDelegate.detailsHeight = _detailsView.frame.size.height;
    if (!_unfinishedOrder) {
        [self updateJoinButton];
    }
    [self.tableView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    [super viewWillAppear:animated];
    [TTURLRequestQueue mainQueue].suspended = NO;//no need to suspend, viewDidAppear may never be called(e.g. after dismiss a modal view) then it will be suspended forever
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    @try {
        [self.tableView removeObserver:self forKeyPath:@"contentOffset"];
    }
    @catch (NSException *exception) {
        DDLogError(@"failed to remove observer for contentOffset, probably it was removed already for a reason i don't know: %@", exception);
    }
}

-(void)updateJoinButton{
    [_joinButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
    User* loggedInUser = [UserService service].loggedInUser;
    for (Order* order in _meal.orders) {
        if ([order.user isEqual:loggedInUser]) {
            _myOrder = order;
            if (_meal.price.floatValue == 0.0) {
                [_joinButton setTitle:@"我已报名" forState:UIControlStateNormal];
                [_joinButton addTarget:self action:@selector(cancelOrder:) forControlEvents:UIControlEventTouchUpInside];
            } else {
                [_joinButton setTitle:@"已支付，查看订单" forState:UIControlStateNormal];
                [_joinButton addTarget:self action:@selector(viewOrder:) forControlEvents:UIControlEventTouchUpInside];
            }
            return;
        }
    }
    NSDate* time = [MealService dateOfMeal:_meal];
    if([time compare:[NSDate date]] == NSOrderedAscending){
        [_joinButton setTitle:@"已结束" forState:UIControlStateNormal];
    }  else if ([self.meal.actualPersons integerValue] >= [self.meal.maxPersons integerValue]) {
        [_joinButton setTitle:@"爆满" forState:UIControlStateNormal];
        [_joinButton setBackgroundImage:[UIImage imageNamed:@"sold_out"] forState:UIControlStateNormal];
        [_commentButton setBackgroundImage:[UIImage imageNamed:@"meal_comment_sold_out"] forState:UIControlStateNormal];
        [_joinButton removeTarget:self action:@selector(joinMeal:) forControlEvents:UIControlEventTouchDown];
    } else {
        [_joinButton setTitle:@"我要报名" forState:UIControlStateNormal];
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
    _tabBar.frame = CGRectMake(0, self.view.bounds.size.height - TAB_BAR_HEIGHT, self.view.bounds.size.width, TAB_BAR_HEIGHT);
    _tabBar.hidden = NO;
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

- (id<UITableViewDelegate>)createDelegate {
    return [[MealDetailsViewDelegate alloc] init];
}

- (IBAction)joinMeal:(id)sender {
    if (_meal.price.floatValue == 0.0) {
        NSString *mealID = [NSString stringWithFormat:@"%@", self.meal.mID];
        NSString *numberOfPerson = [NSString stringWithFormat:@"%d", 1];
        NSArray *params = @[[DictHelper dictWithKey:@"meal_id" andValue:mealID],
                            [DictHelper dictWithKey:@"num_persons" andValue:numberOfPerson]];
        [[NetworkHandler getHandler] requestFromURL:[NSString stringWithFormat:@"http://%@/api/v1/user/%d/order/", EOHOST, [Authentication sharedInstance].currentUser.uID]
                                             method:POST
                                         parameters:params
                                        cachePolicy:TTURLRequestCachePolicyNone
                                            success:^(id obj) {
                                                NSDictionary* dic = obj;
                                                //note: as order has attribute "status" too if success status will set to the status of the order
                                                if ([dic[@"status"] isEqual:@"NOK"]) {
                                                    [SVProgressHUD showErrorWithStatus:dic[@"info"]];
                                                } else {
                                                    [self setAsPaid];
                                                }
                                            } failure:^{
                                                [SVProgressHUD showErrorWithStatus:@"加入失败，请稍后重试"];
                                            }];
    } else {
        JoinMealViewController* vc = [[JoinMealViewController alloc] init];
        vc.meal = self.meal;
        [self.navigationController pushViewController:vc animated:YES];
    }
}

-(IBAction)cancelOrder:(id)sender{
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:nil message:@"要取消报名吗？" delegate:self cancelButtonTitle:@"不取消" otherButtonTitles:@"取消报名", nil];
    [alert show];
}

-(void)doCancelOrder{
    [[NetworkHandler getHandler] requestFromURL:[NSString stringWithFormat:@"http://%@/order/cancel/%@/", EOHOST, _myOrder.oID]
                                         method:POST
                                     parameters:nil
                                    cachePolicy:TTURLRequestCachePolicyNone
                                        success:^(id obj) {
                                            NSDictionary* dic = obj;
                                            //note: as order has attribute "status" too if success status will set to the status of the order
                                            if ([dic[@"status"] isEqual:@"NOK"]) {
                                                [SVProgressHUD showErrorWithStatus:dic[@"info"]];
                                            } else {
//                                                [_joinButton setTitle:@"我要报名" forState:UIControlStateNormal];
//                                                [_joinButton removeTarget:self action:@selector(cancelOrder:) forControlEvents:UIControlEventTouchUpInside];
//                                                [_joinButton addTarget:self action:@selector(joinMeal:) forControlEvents:UIControlEventTouchUpInside];
                                                [SVProgressHUD showSuccessWithStatus:@"已取消报名"];
                                                [self reloadMeal];
                                            }
                                        } failure:^{
                                            [SVProgressHUD showErrorWithStatus:@"取消失败，请联系客服"];
                                        }];
}

-(void)setAsPaid{
    NSString *mealID = [NSString stringWithFormat:@"%@", self.meal.mID];
    NSString *numberOfPerson = [NSString stringWithFormat:@"%d", 1];
    NSArray *params = @[[DictHelper dictWithKey:@"meal_id" andValue:mealID],
                        [DictHelper dictWithKey:@"num_persons" andValue:numberOfPerson]];
    [[NetworkHandler getHandler] requestFromURL:[NSString stringWithFormat:@"http://%@/meal/%@/", EOHOST, mealID]
                                         method:POST
                                     parameters:params
                                    cachePolicy:TTURLRequestCachePolicyNone
                                        success:^(id obj) {
                                            [SVProgressHUD showSuccessWithStatus:@"加入成功，请准时参加。若不能参加，请取消报名"];
//                                            [_joinButton setTitle:@"已经报名" forState:UIControlStateNormal];
//                                            [_joinButton removeTarget:self action:@selector(joinMeal:) forControlEvents:UIControlEventTouchUpInside];
//                                            [_joinButton addTarget:self action:@selector(cancelOrder:) forControlEvents:UIControlEventTouchUpInside];
                                            [self reloadMeal];
                                        } failure:^{
                                            [SVProgressHUD showErrorWithStatus:@"加入失败，请稍后重试"];
                                        }];
}

-(void)reloadMeal{
    RKObjectManager* manager = [RKObjectManager sharedManager];
    NSString* path = [NSString stringWithFormat:@"meal/%@/", _meal.mID];
    [manager getObject:nil path:path parameters:nil success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        _meal = mappingResult.firstObject;
        MealDetailDataSource* ds =  self.dataSource;
        ds.meal = _meal;
        [self.tableView reloadData];
        [self updateJoinButton];
        [[NewSidebarViewController sideBar].mealListViewController.tableView reloadData];
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        DDLogError(@"failed to refresh data: %@", error);
    }];
}
- (void) onShareClicked:(id)sender{
//    ShareTableViewController* vc = [[ShareTableViewController alloc] init];
//    vc.delegate = self;
//    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
//    [self presentModalViewController:nav animated:YES];
    UIActionSheet* action = [[UIActionSheet alloc] initWithTitle:@"分享到" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"新浪微博",@"微信好友",@"微信朋友圈", nil];
    [action showFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES];
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

-(void) shareToWeixinContact{
    [self shareToWeixin:WXSceneSession];
}
-(void) shareToWeixinTimeline{
    [self shareToWeixin:WXSceneTimeline];
}

-(void)shareToWeixin:(int)scene{
    DDLogInfo(@"weixin installed: %d, support api: %d", [WXApi isWXAppInstalled], [WXApi isWXAppSupportApi]);
    
    WXMediaMessage *message = [WXMediaMessage message];
    message.title = [NSString stringWithFormat:@"分享一个活动：%@", _meal.topic];
    message.description = _meal.introduction;
    MealDetailCell* detailsCell = (MealDetailCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    UIImage* image = detailsCell.mealImageView.image;
    image = [image imageScaledToSize:CGSizeMake(image.size.width * (120.0/image.size.height), 120)]; //image must be resized or share will fail
    [message setThumbImage:image];
    
    
    WXWebpageObject *ext = [WXWebpageObject object];
    ext.webpageUrl = [URLService absoluteURL:[NSString stringWithFormat:@"/meal/%@/", _meal.mID]];
    message.mediaObject = ext;
    
    SendMessageToWXReq* req = [[SendMessageToWXReq alloc] init];
    req.bText = NO;
    req.message = message;
    req.scene = scene;
    
    [WXApi sendReq:req];
}

-(void) sendWeiBo{
//    UIImage* image = [[Nimbus imageMemoryCache] objectWithName:[URLService  absoluteURL:_meal.photoURL]];
    MealDetailCell* detailsCell = (MealDetailCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    UIImage* image = detailsCell.mealImageView.image;
    NSString *defaultMessage = [NSString stringWithFormat:@"一个有趣的活动：%@ http://%@/meal/%@/", _meal.topic, EOHOST, _meal.mID];
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

#pragma mark SendCommentDelegate
-(void)didSendComment:(MealComment*)comment{
    MealDetailDataSource* ds = self.dataSource;
    if (!ds.comments) {
        ds.comments = [NSMutableArray array];
    }
    [ds.comments addObject:comment];
    [self refresh];
    dispatch_async(dispatch_get_main_queue(), ^{
        NSIndexPath* lastRow = [NSIndexPath indexPathForRow:[self.tableView numberOfRowsInSection:1] - 1 inSection:1];
        [self.tableView scrollToRowAtIndexPath:lastRow atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    });
}

-(void)didFailSendComment{
    DDLogError(@"FAILED TO SEND COMMENT");
}

#pragma mark UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    switch (buttonIndex) {
        case 0:
            [self shareToSinaWeibo];
            break;
        case 1:
            [self shareToWeixinContact];
            break;
        case 2:
            [self shareToWeixinTimeline];
            break;
        default:
            break;
    }
}

#pragma mark UIAlertViewDelegate

// Called when a button is clicked. The view will be automatically dismissed after this call returns
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 1) {
        [self doCancelOrder];
    }
}
@end


