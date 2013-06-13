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

@implementation MealDetailViewController{
    MealDetailsViewDelegate* _mealDetailsViewDelegate;
    Order* _myOrder;
    NSArray* _participants;
    CMPopTipView *_navBarLeftButtonPopTipView;
    UIButton* _commentButton;
    NINetworkImageView *_mealImageView;
}

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
}

-(void)viewWillAppear:(BOOL)animated{
    _mealDetailsViewDelegate.detailsHeight = _detailsView.frame.size.height;
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
- (void) initDetailsView{
    _detailsView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 0)];
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
    UILabel* topicLabel = [self createRightLabel:CGPointMake(x, y) width:INTRO_WIDTH maxHeight:INTRO_HEIGHT text:_meal.introduction lines:4];
    
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
    UILabel* timeLabel = [self createRightLabel:CGPointMake(x, y) width:INTRO_WIDTH maxHeight:12 text:[MealService dateTextOfMeal:_meal] lines:1];
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
    NSString *addressStr = [NSString stringWithFormat:@"%@ %@", self.meal.restaurant.address, self.meal.restaurant.name];
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
//        [_menuPopover dismissPopoverAnimated:YES];
//        [self.navigationController presentModalViewController:_cpc animated:NO];
        [self.view addSubview:_menuContentViewController.view];
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
    [[NetworkHandler getHandler] requestFromURL:[NSString stringWithFormat:@"http://%@/api/v1/meal/%@/menu/", EOHOST, self.meal.mID]
                                         method:GET
                                    cachePolicy:TTURLRequestCachePolicyNone
                                        success:^(id obj){
                                            [self updateMenuButton:menuButton withReadingStatus:NO];
                                            //the only object in meal/id/menu/
                                            NSDictionary* data = [[obj objectForKeyInObjects] objectAtIndex:0];
                                            _mealMenu = [MealMenu mealMenuWithData:data];
                                            
                                            
                                            _menuContentViewController = [[MenuViewController alloc] init];
                                            _menuContentViewController.mealMenu = _mealMenu;
                                            [self.view addSubview:_menuContentViewController.view];
                                        }
                                        failure:^(void){
                                            [self updateMenuButton:menuButton withReadingStatus:NO];
                                            DDLogError(@"failed to fetch menu");
                                            [SVProgressHUD showErrorWithStatus:@"获取菜单失败"];
                                        }];

    
}

-(void) rebuildParticipantsView {
    if (_participantsView != nil) {
        [_participantsView removeFromSuperview];
    }
    NSInteger y = _numberOfPersons.frame.origin.y + _numberOfPersons.frame.size.height + 8;
    _participantsView = [[UIScrollView alloc] initWithFrame:CGRectMake(9, y, 320 - 9, PARTICIPANTS_VIEW_HEIGHT)];
    _participantsView.showsHorizontalScrollIndicator = NO;
    _participantsView.backgroundColor = [UIColor clearColor];
    _participants = [MealService participantsOfMeal:_meal];
    _participantsView.contentSize = CGSizeMake( (PARTICIPANTS_WIDTH + PARTICIPANTS_GAP ) * _participants.count, PARTICIPANTS_HEIGHT);

    for (int i = 0; i < _participants.count; i++) {
        id obj = _participants[i];
        UIImageView* avatarView = nil;
        if ([obj isKindOfClass:[GuestUser class]]) {
            avatarView = [AvatarFactory guestAvatarWithBg:NO];
        } else {
            avatarView = [AvatarFactory avatarWithBg:obj];
        }
        avatarView.frame = CGRectMake(55*i, 0, 53, 53);
        avatarView.tag = i;
        avatarView.userInteractionEnabled = YES;
        if ([obj isKindOfClass:[User class]]) {
            UIGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(avatarTapped:)];
            [avatarView addGestureRecognizer:tap];
        } else {
            UIGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(guestTapped:)];
            [avatarView addGestureRecognizer:tap];
        }
        
        [_participantsView addSubview:avatarView];
//        [_participantsView addSubview:contentView];
    }
    [_detailsView addSubview:_participantsView];
    CGRect frame = _detailsView.frame;
    frame.size.height  = y + PARTICIPANTS_VIEW_HEIGHT;
    _detailsView.frame = frame;
}

-(void)avatarTapped:(UITapGestureRecognizer*)tap{
    UIView* view = tap.view;
    NSInteger tag = view.tag;
    UserDetailsViewController* userDetails = [[UserDetailsViewController alloc] init];
    userDetails.user = _participants[tag];
    [self.navigationController pushViewController:userDetails animated:YES];
}

-(void)guestTapped:(UITapGestureRecognizer*)tap{
    if (!_navBarLeftButtonPopTipView) {
        _navBarLeftButtonPopTipView = [[CMPopTipView alloc] init] ;
        _navBarLeftButtonPopTipView.dismissTapAnywhere = YES;
    } else {
        [_navBarLeftButtonPopTipView dismissAnimated:NO];
    }
    UIView* view = tap.view;
    NSInteger tag = view.tag;
    GuestUser* guest = _participants[tag];
    NSString* message = [NSString stringWithFormat:@"%@邀请的朋友", guest.host.name];
    _navBarLeftButtonPopTipView.message = message;
    _navBarLeftButtonPopTipView.backgroundColor = [UIColor blackColor];
//    navBarLeftButtonPopTipView.delegate = self;
    [_navBarLeftButtonPopTipView presentPointingAtView:view inView:self.view animated:YES];
//    [navBarLeftButtonPopTipView presentPointingAtBarButtonItem:self.navigationItem.leftBarButtonItem animated:YES];
    // Dismiss a CMPopTipView
//    [navBarLeftButtonPopTipView dismissAnimated:YES];
}
-(void) updateNumberOfParticipants{
     _numberOfPersons.text = [NSString stringWithFormat:@"%@/%@", _meal.actualPersons, _meal.maxPersons];
    [_numberOfPersons sizeToFit];
}

- (void) mapButtonClicked:(id)sender{
    MapViewController* map = [[MapViewController alloc] initWithTitle:_meal.restaurant.name];
    map.restaurant = _meal.restaurant;
    [self.navigationController pushViewController:map animated:YES];
}

- (UIView*) createHostView{
    UIView* hostView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, DISH_VIEW_WIDTH, DISH_VIEW_HEIGHT)];
    _mealImageView = [[NINetworkImageView alloc] initWithFrame:CGRectMake(0, 0, 320, DISH_VIEW_HEIGHT)];
    _mealImageView.clipsToBounds = YES;

    [_mealImageView setContentMode:UIViewContentModeScaleAspectFill];
    [_mealImageView setPathToNetworkImage:[URLService  absoluteURL:_meal.photoURL] forDisplaySize:CGSizeMake(320, 213)];
    UIImage* cost_bg = [UIImage imageNamed:@"renjun_mon"];
    UIImageView* cost_view = [[UIImageView alloc] initWithImage:cost_bg];
    cost_view.frame = CGRectMake(9, 0, cost_bg.size.width, cost_bg.size.height);
    UILabel* cost_label = [[UILabel alloc] initWithFrame:CGRectMake(21, 1.5, 60, 20)];
    cost_label.backgroundColor = [UIColor clearColor];
    cost_label.textColor = RGBCOLOR(220, 220, 220);

    cost_label.text = [NSString stringWithFormat:@"人均：¥%.0f", [_meal.price floatValue]];
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
    
    [hostView addSubview:_mealImageView];
    [hostView addSubview:cost_view];
    [hostView addSubview:cost_label];
    [hostView addSubview:menuBtn];
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
        JoinMealViewController* vc = [[JoinMealViewController alloc] init];
        vc.meal = self.meal;
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)viewDidUnload {
    [super viewDidUnload];
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
    NSString *defaultMessage = [NSString stringWithFormat:@"一个有趣的饭局：%@ http://%@/meal/%@/", _meal.topic, EOHOST, _meal.mID];
    UIImage* image = _mealImageView.image;
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

#pragma mark UIScrollViewDelegate
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    CGFloat offset = [[change objectForKey:@"new"] CGPointValue].y;
    CGRect frame = _mealImageView.frame;
    frame.origin.y = offset;
    frame.size.height = DISH_VIEW_HEIGHT - offset;
    _mealImageView.frame = frame;
}
-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
//    CGFloat offset = scrollView.contentOffset.y;
//    CGRect frame = _mealImageView.frame;
////    frame.origin.y = offset;
//    frame.size.height = 140 - offset;
//    _mealImageView.frame = frame;
}

@end


