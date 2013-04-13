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
#import "NewUserDetailsViewController.h"
#import "SpeechBubble.h"
#import "ClosablePopoverViewController.h"
#import "OverlayViewController.h"
#import "NINetworkImageView.h"
#import "MapViewController.h"
#import "WidgetFactory.h"
#import "OrderInfo.h"
#import "OrderDetailsViewController.h"

@implementation MealDetailViewController{
    MealDetailsViewDelegate* _mealDetailsViewDelegate;
    OrderInfo* _myOrder;

}

@synthesize mealInfo = _mealInfo;
@synthesize tabBar = _tabBar;

-(id)init{
    if (self = [super init]) {
        _mealDetailsViewDelegate = [[MealDetailsViewDelegate alloc] init];
    }
    return self;
}

-(void) loadView{
    [super loadView];
    AppDelegate *delegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    self.tableView.backgroundColor = [UIColor colorWithPatternImage:delegate.bgImage];   
    [self initTabView];
}

- (void)updateJoinButton {
    [self requestOrderStatus];
//    UserProfile* currentUser = [[Authentication sharedInstance] currentUser];
//    NSString *userID = currentUser ? [NSString stringWithFormat:@"%d", currentUser.uID] : nil;
//    if (self.mealInfo.actualPersons >= self.mealInfo.maxPersons) {
//        [_joinButton setTitle:@"卖光了" forState:UIControlStateNormal];
////        _joinButton.backgroundColor = RGBCOLOR(0xF2, 0x2A, 0x39);
//        [_joinButton removeTarget:self action:@selector(joinMeal:) forControlEvents:UIControlEventTouchDown];
//    } else if (userID && [self.mealInfo hasJoined:userID]) {
//        [_joinButton setTitle:@"已参加" forState:UIControlStateNormal];
////        _joinButton.backgroundColor = RGBCOLOR(0xFF, 0xCC, 0);
//        [_joinButton removeTarget:self action:@selector(joinMeal:) forControlEvents:UIControlEventTouchDown];
//    } else {
//        [_joinButton setTitle:@"参加饭局" forState:UIControlStateNormal];
////        _joinButton.backgroundColor = RGBCOLOR(0, 0x99, 0);
//        [_joinButton addTarget:self action:@selector(joinMeal:) forControlEvents:UIControlEventTouchDown];
//    }
}

-(void)requestOrderStatus{
    UserProfile* currentUser = [[Authentication sharedInstance] currentUser];
    [[NetworkHandler getHandler] requestFromURL:[NSString stringWithFormat:@"http://%@/api/v1/order/?&meal__id=%d&customer__id=%d&format=json", EOHOST, self.mealInfo.mID, currentUser.uID]
                                         method:GET
                                    cachePolicy:TTURLRequestCachePolicyDefault
                                        success:^(id obj) {
                                            NSArray *orders = [obj objectForKeyInObjects];
                                            if (orders && [orders count] > 0){
                                                NSDictionary* data = orders[0];
                                                _myOrder = [OrderInfo orderInfoWithData:data];
                                                if (_myOrder.status == 1) {
                                                    if (self.mealInfo.actualPersons >= self.mealInfo.maxPersons) {
                                                        [_joinButton setTitle:@"卖光了" forState:UIControlStateNormal];
                                                        [_joinButton removeTarget:self action:@selector(joinMeal:) forControlEvents:UIControlEventTouchDown];
                                                    } else {
                                                        [_joinButton setTitle:@"去支付" forState:UIControlStateNormal];
                                                        [_joinButton addTarget:self action:@selector(payForOrder:) forControlEvents:UIControlEventTouchDown];
                                                    }
                                                } else if(_myOrder.status > 1){
                                                    [_joinButton setTitle:@"已支付，查看订单" forState:UIControlStateNormal];
                                                    [_joinButton addTarget:self action:@selector(viewOrder:) forControlEvents:UIControlEventTouchDown];
                                                } else {
                                                    NSLog(@"illegal order status: %d", _myOrder.status);
                                                }
                                            } else {
                                                if (self.mealInfo.actualPersons >= self.mealInfo.maxPersons) {
                                                    [_joinButton setTitle:@"卖光了" forState:UIControlStateNormal];
                                                    [_joinButton removeTarget:self action:@selector(joinMeal:) forControlEvents:UIControlEventTouchDown];
                                                } else {
                                                    [_joinButton setTitle:@"参加饭局" forState:UIControlStateNormal];
                                                    [_joinButton addTarget:self action:@selector(joinMeal:) forControlEvents:UIControlEventTouchDown];
                                                }
                                            }
                                            [UIView animateWithDuration:0.9 animations:^{
                                                _tabBar.hidden = NO;
                                            }];
                                        } failure:^{
                                            NSLog(@"failed to get order status for id %@", _mealID);
                                        }];
}

-(void)payForOrder:(id)sender{
    NSLog(@"Not implemented yet");    
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
    UIImage* join_img_push = [UIImage imageNamed:@"toolbth1_push"];
    CGFloat x = JOIN_BUTTON_X;
    CGFloat y = (_tabBar.frame.size.height - join_img.size.height + toolbarShadow.size.height) / 2;
    _joinButton = [[UIButton alloc] initWithFrame:CGRectMake(JOIN_BUTTON_X, y, join_img.size.width, join_img.size.height)];
    [_joinButton setBackgroundImage:join_img forState:UIControlStateNormal];
    [_joinButton setBackgroundImage:join_img_push forState:UIControlStateSelected | UIControlStateHighlighted ];
    _joinButton.titleLabel.textAlignment  = UITextAlignmentCenter;
    _joinButton.titleLabel.textColor = [UIColor whiteColor];
    _joinButton.titleLabel.font = [UIFont boldSystemFontOfSize:19];

    _tabBar.hidden = YES;
    [self updateJoinButton];
    
    UIImage* comment_img = [UIImage imageNamed:@"toolbth2"];
    UIImage* comment_img_push = [UIImage imageNamed:@"toolbth2_push"];
    x = _joinButton.frame.origin.x + _joinButton.frame.size.width;
    UIButton* commentButton = [[UIButton alloc] initWithFrame:CGRectMake(x, y, comment_img.size.width, comment_img.size.height)];
    [commentButton setBackgroundImage:comment_img forState:UIControlStateNormal];
    [commentButton setBackgroundImage:comment_img_push forState:UIControlStateSelected | UIControlStateHighlighted ];
    
    [_tabBar addSubview:_joinButton];
    [_tabBar addSubview:commentButton];
    [self.view addSubview:_tabBar];
    
    UIImageView* shadowView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, toolbarShadow.size.width, toolbarShadow.size.height)];
    shadowView.image = toolbarShadow;
    [_tabBar addSubview:shadowView];
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    if (self.mealInfo) {
        [self buildUI];
    } else if(self.mealID){
        [self requetMealDetails];
    }
}

-(void)requetMealDetails{
    [[NetworkHandler getHandler] requestFromURL:[NSString stringWithFormat:@"http://%@/api/v1/meal/%@/?format=json&limit=0", EOHOST, _mealID]
                                        method:GET
                                cachePolicy:TTURLRequestCachePolicyDefault
                                        success:^(id obj) {
                                            NSDictionary* dic = obj;
                                            MealInfo* meal = [MealInfo mealInfoWithData:dic];
                                            self.mealInfo = meal;
                                            [self buildUI];
                                        } failure:^{
                                            NSLog(@"failed to get meal for id %@", _mealID);
                                            [SVProgressHUD dismissWithError:@"获取饭局失败"];
                                        }];

}
-(void)buildUI{
    self.tableView.showsVerticalScrollIndicator = NO;
    self.navigationItem.titleView = [[WidgetFactory sharedFactory]titleViewWithTitle:_mealInfo.topic];
    
    self.navigationItem.leftBarButtonItem = [[WidgetFactory sharedFactory]backButtonWithTarget:self.navigationController action:@selector(popViewControllerAnimated:)];
    self.navigationItem.hidesBackButton = YES;
    self.navigationItem.rightBarButtonItem = [[WidgetFactory sharedFactory]normalBarButtonItemWithTitle:@"分享" target:self action:@selector(onShareClicked:)];
    
    self.tableView.separatorColor = [UIColor clearColor];
    NSMutableArray* items = [[NSMutableArray alloc] init];
    NSMutableArray* sections = [[NSMutableArray alloc] init];
    
    [sections addObject:@"Host"];
    NSMutableArray* itemsRow = [[NSMutableArray alloc] init];
    [itemsRow addObject:[self createHostView]];
    [items addObject:itemsRow];
    
    [sections addObject:@"Details"];
    itemsRow = [[NSMutableArray alloc] init];
    [self initDetailsView];
    [itemsRow addObject:_detailsView];
    [items addObject:itemsRow];
    
    //    itemsRow = [[NSMutableArray alloc] init];
    //    [sections addObject:@"Comments"];
    //    [self createLoadingView];
    //    [itemsRow addObject:_loadingOrNoCommentsLabel];
    //    [items addObject:itemsRow];
    
    
    TTSectionedDataSource* ds = [[TTSectionedDataSource alloc] initWithItems:items sections:sections];
    self.dataSource = ds;
    //    [self requestDataFromServer];
}

-(void)viewWillAppear:(BOOL)animated{
    _mealDetailsViewDelegate.detailsHeight = _detailsView.frame.size.height;
    [super viewWillAppear:animated];
}
-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    CGRect frame = self.tableView.frame;
    frame.origin.x = 0;
    frame.origin.y = 0;
    frame.size.height = 480 - 20 - 44 - TAB_BAR_HEIGHT; //- status, nav, tab
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

- (void) requestDataFromServer{
    TTSectionedDataSource *ds = self.dataSource;    
    [[NetworkHandler getHandler] requestFromURL:[NSString stringWithFormat:@"http://%@/api/v1/meal/%d/comments/?format=json", EOHOST, self.mealInfo.mID]
                                         method:GET
                                    cachePolicy:TTURLRequestCachePolicyNetwork
                                        success:^(id obj) {   
                                            NSArray* comments = [obj objectForKeyInObjects];
                                            if (comments && [comments count] > 0) {   
                                                [self removeLoadingView];
                                                int lastSectionIndex = (ds.items.count - 1);
                                                NSMutableArray* lastSection =  [ds.items objectAtIndex:lastSectionIndex];
                                                for (NSDictionary *dict in comments) {
                                                    MealComment *comment = [[MealComment alloc] initWithData:dict];
                                                    [lastSection addObject:[self createCommentView:comment]];
                                                } 
                                                
                                                [self.tableView reloadData];                                               
//                                                NSIndexSet *updatedSections = [NSIndexSet indexSetWithIndex:lastSectionIndex];	 
//                                                [self.tableView reloadSections:updatedSections withRowAnimation:UITableViewRowAnimationNone];
                                            }
                                            else {
                                                _loadingOrNoCommentsLabel.text = NSLocalizedString(@"NoComments", nil);
                                            }
                                        } failure:^{
                                            //TODO what if failed?	
                                        }];

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
- (void) initDetailsView{
    _detailsView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, DETAILS_VIEW_HEIGHT)];
    _detailsView.backgroundColor = [UIColor clearColor];
    _detailsView.backgroundColor = [UIColor clearColor];
    
    //introduction
    NSInteger x = H_GAP;
    NSInteger y = V_GAP;
    UIImage* image_janjie = [UIImage imageNamed:@"icon_jianjie"];
    UIImageView *icon_jianjie = [[UIImageView alloc] initWithImage:image_janjie];
    icon_jianjie.frame = CGRectMake(x, y, image_janjie.size.width, image_janjie.size.height);
    [_detailsView addSubview:icon_jianjie];
    
    x = icon_jianjie.frame.size.width + icon_jianjie.frame.origin.x + 3;
    UILabel* jianjie = [self createLeftLabel:CGPointMake(x, y) text:@"简介："];
    [_detailsView addSubview:jianjie];
    
    x = jianjie.frame.size.width + jianjie.frame.origin.x;
    UILabel* topicLabel = [self createRightLabel:CGPointMake(x, y) width:INTRO_WIDTH maxHeight:INTRO_HEIGHT text:_mealInfo.intro lines:4];
    
    [_detailsView addSubview:topicLabel];
    
    //time
    y = topicLabel.frame.size.height + topicLabel.frame.origin.y + V_GAP;
    x = H_GAP;
    UIImage* image_time = [UIImage imageNamed:@"icon_time"];
    UIImageView *icon_time = [[UIImageView alloc] initWithImage:image_time];
    icon_time.frame = CGRectMake(x, y, image_time.size.width, image_time.size.height);
    [_detailsView addSubview:icon_time];

    x = icon_time.frame.size.width + icon_time.frame.origin.x + 3;
    UILabel* time = [self createLeftLabel:CGPointMake(x, y) text:@"时间："];
    [_detailsView addSubview:time];
    
    x = time.frame.origin.x + time.frame.size.width;
    UILabel* timeLabel = [self createRightLabel:CGPointMake(x, y) width:INTRO_WIDTH maxHeight:12 text:[_mealInfo timeText] lines:1];
    [_detailsView addSubview:timeLabel];
    
    //address
    y = timeLabel.frame.size.height + timeLabel.frame.origin.y + V_GAP;
    x = H_GAP;
    UIImage* image_address = [UIImage imageNamed:@"icon_add"];
    UIImageView *icon_address = [[UIImageView alloc] initWithImage:image_address];
    icon_address.frame = CGRectMake(x, y, image_address.size.width, image_address.size.height);
    [_detailsView addSubview:icon_address];
    
    x = icon_address.frame.size.width + icon_address.frame.origin.x + 3;
    UILabel* address = [self createLeftLabel:CGPointMake(x, y) text:@"地点："];
    [_detailsView addSubview:address];
    
    x = address.frame.origin.x + address.frame.size.width;
    NSString *addressStr = [NSString stringWithFormat:@"%@ %@", self.mealInfo.restaurant.address, self.mealInfo.restaurant.name];
    UILabel* addressLabel = [self createRightLabel:CGPointMake(x, y) width:ADDRESS_WIDTH maxHeight:ADDRESS_HEIGHT text:addressStr lines:2];
    [_detailsView addSubview:addressLabel];
    
    
    UIImage* map = [UIImage imageNamed:@"map"];
    UIImage* map_push = [UIImage imageNamed:@"map_push"];
    x = 320 - map.size.width - 10;
    _mapButton = [[UIButton alloc] initWithFrame:CGRectMake(x, y, map.size.width, map.size.height)];
    [_mapButton setBackgroundImage:map forState:UIControlStateNormal];
    [_mapButton setBackgroundImage:map_push forState:UIControlStateHighlighted | UIControlStateSelected];
    [_mapButton addTarget:self action:@selector(mapButtonClicked:) forControlEvents:UIControlEventTouchDown];
    [_detailsView addSubview:_mapButton];
    
    //number of participants
    y = addressLabel.frame.size.height + addressLabel.frame.origin.y + V_GAP;
    x = H_GAP;
    UIImage* image_person = [UIImage imageNamed:@"icon_pers"];
    UIImageView *icon_person = [[UIImageView alloc] initWithImage:image_person];
    icon_person.frame = CGRectMake(x, y, image_person.size.width, image_person.size.height);
    [_detailsView addSubview:icon_person];
    
    x = icon_person.frame.size.width + icon_person.frame.origin.x + 3;
    UILabel* persons = [self createLeftLabel:CGPointMake(x, y) text:@"人数："];
    [_detailsView addSubview:persons];
    
    x = persons.frame.origin.x + persons.frame.size.width;
    _numberOfPersons = [self createRightLabel:CGPointMake(x, y) width:NUM_OF_PERSONS_WIDTH maxHeight:NUM_OF_PERSONS_HEIGHT text:@"99/99" lines:1];
    [_detailsView addSubview:_numberOfPersons];
    [self updateNumberOfParticipants];
    
    //participants
    [self rebuildParticipantsView];
}

-(UILabel*)createLeftLabel:(CGPoint)origin text:(NSString*)text{
    UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(origin.x, origin.y, 0, 0)];
    label.textColor = RGBCOLOR(120, 120, 120);
    label.font = [UIFont systemFontOfSize:12];
    label.backgroundColor = [UIColor clearColor];
    label.text = text;
    [label sizeToFit];
    return label;
}

-(UILabel*)createRightLabel:(CGPoint)origin width:(CGFloat)width maxHeight:(CGFloat)maxHeight text:(NSString*)text lines:(NSInteger)lines{
    UIFont* textFont = [UIFont systemFontOfSize:12];
    UIColor* rightTextColor = RGBCOLOR(80, 80, 80);
//    CGSize size = [_mealInfo.topic sizeWithFont:textFont constrainedToSize:CGSizeMake(width, maxHeight)];//sizeWithFont:textFont forWidth:width lineBreakMode:NSLineBreakByWordWrapping];
//    CGFloat height = size.height > maxHeight ? maxHeight : size.height;
//    UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(origin.x, origin.y, TOPIC_WIDTH, height)];
    UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(origin.x, origin.y, width, 0)];
    label.font = textFont;
    label.textColor = rightTextColor;
    label.text = text;
    label.numberOfLines = 0;//lines;
    [label sizeToFit];
    label.backgroundColor = [UIColor clearColor];
    return label;
}

-(void)displayMenu:(id)sender{
    TTButton* menuButton = sender;
    if (!_mealMenu) {
        [self updateMenuButton:menuButton withReadingStatus:YES];
        [self fetchMenu:sender];
    } else {
        [_menuPopover dismissPopoverAnimated:YES];
        [self.navigationController presentModalViewController:_cpc animated:NO];
    }
}

-(void)updateMenuButton:(TTButton*)menuButton withReadingStatus:(BOOL)isReading{
    if (isReading) {
        [menuButton setTitle:@"读取中" forState:UIControlStateNormal];
        menuButton.userInteractionEnabled = NO;
    } else {
        [menuButton setTitle:@"菜式" forState:UIControlStateNormal];
        menuButton.userInteractionEnabled = YES;
    }
//    [menuButton sizeToFit];
}

-(void)fetchMenu:(id)sender{
    TTButton* menuButton = sender;
    [[NetworkHandler getHandler] requestFromURL:[NSString stringWithFormat:@"http://%@/api/v1/meal/%d/menu/", EOHOST, self.mealInfo.mID]
                                         method:GET
                                    cachePolicy:TTURLRequestCachePolicyNone
                                        success:^(id obj){
                                            [self updateMenuButton:menuButton withReadingStatus:NO];
                                            //the only object in meal/id/menu/
                                            NSDictionary* data = [[obj objectForKeyInObjects] objectAtIndex:0];
                                            _mealMenu = [MealMenu mealMenuWithData:data];
                                            _menuContentViewController = [[MenuTableViewController alloc] initWithStyle:UITableViewStylePlain];
                                            _menuContentViewController.menu = _mealMenu;
                                            _cpc = [[ClosablePopoverViewController alloc] initWithContentViewController:_menuContentViewController];
                                            
                                            [[OverlayViewController sharedOverlayViewController] presentModalViewController:_cpc animated:NO];
                                        }
                                        failure:^(void){
                                            [self updateMenuButton:menuButton withReadingStatus:NO];
                                            [SVProgressHUD dismissWithError:@"获取菜单失败"];
                                        }];

    
}

-(void) rebuildParticipantsView {
    if (_participants != nil) {
        [_participants removeFromSuperview];
    }
    NSInteger y = _numberOfPersons.frame.origin.y + _numberOfPersons.frame.size.height + 8;
    _participants = [[UIScrollView alloc] initWithFrame:CGRectMake(9, y, 320 - 9, 68)];
    _participants.showsHorizontalScrollIndicator = NO;
    _participants.backgroundColor = [UIColor clearColor];
    _participants.contentSize = CGSizeMake( (PARTICIPANTS_WIDTH + PARTICIPANTS_GAP ) * _mealInfo.participants.count, PARTICIPANTS_HEIGHT);
    for (int i = 0; i < self.mealInfo.participants.count; i++) {
        UIImage* photo_bg = [UIImage imageNamed:@"p_photo_bg"];
        UIView* contentView = [[UIView alloc] initWithFrame:CGRectMake((photo_bg.size.width + PARTICIPANTS_GAP) * i , 0, PARTICIPANTS_WIDTH, photo_bg.size.height)];
        UIImageView* photo_bg_view = [[UIImageView alloc] initWithImage:photo_bg];
        [contentView addSubview:photo_bg_view];
        UserProfile *user = [self.mealInfo.participants objectAtIndex:i];
        UIImageView *avatarView = [AvatarFactory avatarForUser:user frame:CGRectMake(3.5, 3.5, 46, 46) delegate:self withCornerRadius:NO];
        [contentView addSubview:avatarView];
        [_participants addSubview:contentView];
    }
    [_detailsView addSubview:_participants];
    CGRect frame = _detailsView.frame;
    frame.size.height = _participants.frame.origin.y + _participants.frame.size.height;
    _detailsView.frame = frame;
}

-(void) updateNumberOfParticipants{
     _numberOfPersons.text = [NSString stringWithFormat:@"%d/%d", _mealInfo.actualPersons, _mealInfo.maxPersons];
    [_numberOfPersons sizeToFit];
}

- (void) mapButtonClicked:(id)sender{
    MapViewController* map = [[MapViewController alloc] initWithTitle:_mealInfo.restaurant.name];
    map.info = _mealInfo.restaurant;
    [self.navigationController pushViewController:map animated:YES];
}

- (UIView*) createHostView{
    UIView* hostView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, DISH_VIEW_WIDTH, DISH_VIEW_HEIGHT)];
    NINetworkImageView *imgView = [[NINetworkImageView alloc] initWithFrame:CGRectMake(0, 0, DISH_VIEW_WIDTH, DISH_VIEW_HEIGHT)];

    [imgView setContentMode:UIViewContentModeScaleAspectFill];
    [imgView setPathToNetworkImage:self.mealInfo.photoFullUrl forDisplaySize:CGSizeMake(DISH_VIEW_WIDTH, DISH_VIEW_HEIGHT)];
    UIImage* cost_bg = [UIImage imageNamed:@"renjun_mon"];
    UIImageView* cost_view = [[UIImageView alloc] initWithImage:cost_bg];
    cost_view.frame = CGRectMake(9, 0, cost_bg.size.width, cost_bg.size.height);
    UILabel* cost_label = [[UILabel alloc] initWithFrame:CGRectMake(21, 2, 60, 20)];
    cost_label.backgroundColor = [UIColor clearColor];
    cost_label.textColor = RGBCOLOR(200, 200, 200);
    cost_label.text = [NSString stringWithFormat:@"人均：¥%.0f", _mealInfo.price];
    cost_label.font = [UIFont systemFontOfSize:12];
    
    UIImage* menu = [UIImage imageNamed:@"caishi_bth"];
    UIImage* menu_push = [UIImage imageNamed:@"caishi_bth_push"];
    UIButton* menuBtn = [[UIButton alloc] initWithFrame:CGRectMake(265, 99, menu.size.width, menu.size.height)];
    [menuBtn setBackgroundImage:menu forState:UIControlStateNormal];
    [menuBtn setBackgroundImage:menu_push forState:UIControlStateSelected | UIControlStateHighlighted ];
    [menuBtn setTitle:@"菜式" forState:UIControlStateNormal];
    menuBtn.titleLabel.textColor = RGBCOLOR(220, 220, 220);
    menuBtn.titleLabel.font = [UIFont systemFontOfSize:12];
    [menuBtn addTarget:self action:@selector(displayMenu:) forControlEvents:UIControlEventTouchUpInside];
    
    [hostView addSubview:imgView];
    [hostView addSubview:cost_view];
    [hostView addSubview:cost_label];
    [hostView addSubview:menuBtn];
    
    NSLog(@"frame of meal: %@", NSStringFromCGRect(imgView.frame));
    return hostView;
}

- (id<UITableViewDelegate>)createDelegate {
    return _mealDetailsViewDelegate;
}

- (IBAction)joinMeal:(id)sender {
    if(![[Authentication sharedInstance] isLoggedIn]) {        
        // not logged in
        AppDelegate *delegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
        [delegate showLogin];
    } else {
        CreateOrderViewController* order = [[CreateOrderViewController alloc] initWithNibName:nil bundle:nil];
        order.mealInfo = self.mealInfo;
        order.delegate = self;
        [self.navigationController pushViewController:order animated:YES];
    }
}

-(void) orderCeatedWithUser:(UserProfile *)user numberOfPersons:(NSInteger)num_persons{
    UserProfile *me = [Authentication sharedInstance].currentUser;
    [self.mealInfo join:me withTotalNumberOfPersons:num_persons];
    [self updateNumberOfParticipants];
    [self rebuildParticipantsView];
    [self updateJoinButton];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (void) onShareClicked:(id)sender{
    if (_shareContentViewController == nil) {
        _shareContentViewController = [[ShareTableViewController alloc] initWithStyle:UITableViewStylePlain];
        _shareContentViewController.delegate = self;
        _sharePopOver = [[WEPopoverController alloc] initWithContentViewController:_shareContentViewController];
    }
    [_sharePopOver presentPopoverFromBarButtonItem:self.navigationItem.rightBarButtonItem permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
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
    NSString *defaultMessage = [NSString stringWithFormat:@"我发现了一个有意思的饭局：%@ http://www.fanjoin.com", self.mealInfo.topic];
    WBSendView *sendView = [[WBSendView alloc] initWithAppKey:WEIBO_APP_KEY appSecret:WEIBO_APP_SECRET text:defaultMessage image:[[TTURLCache sharedCache] imageForURL:[NSString stringWithFormat:@"http://%@%@", EOHOST, self.mealInfo.photoURL]]];
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
    NSLog(@"failed to login to sina weibo: %@", error.description);
}

#pragma mark _
#pragma mark WBSendViewDelegate
- (void)sendViewDidFinishSending:(WBSendView *)view{
    [SVProgressHUD showSuccessWithStatus:@"发送成功！"];
    [view hide:YES];
}

- (void)sendView:(WBSendView *)view didFailWithError:(NSError *)error{
    [InfoUtil showErrorWithString:@"发送失败，请稍后重试"];
    NSLog(@"send weibo message failed with error: %@", error.description);
}

#pragma mark UserImageViewDelegate
-(void)userImageTapped:(UserProfile*)user{
    NewUserDetailsViewController *detailVC = [[NewUserDetailsViewController alloc] initWithStyle:UITableViewStylePlain];
    detailVC.user = user;
    [self.navigationController pushViewController:detailVC
                                         animated:YES];
}

#pragma mark NSObject
-(NSString*)description{
    return [NSString stringWithFormat:@"class: %@, %@", [self class], [super description]];
}

@end


