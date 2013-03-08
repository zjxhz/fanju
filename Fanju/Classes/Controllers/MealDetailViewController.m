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
#import "SCAppUtils.h"
#import <MapKit/MapKit.h>
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



@implementation MealDetailViewController{
    MealDetailsViewDelegate* _mealDetailsViewDelegate;
    CGFloat _mapOriginY;

}

@synthesize mealInfo = _mealInfo;
@synthesize tabBar = _tabBar;



-(void) loadView{
    [super loadView];
    AppDelegate *delegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    self.tableView.backgroundColor = [UIColor colorWithPatternImage:delegate.bgImage];   
    [self initTabView];
}

- (void)updateJoinButton {
    UserProfile* currentUser = [[Authentication sharedInstance] currentUser];
    NSString *userID = currentUser ? [NSString stringWithFormat:@"%d", currentUser.uID] : nil;
    if (self.mealInfo.actualPersons >= self.mealInfo.maxPersons) {
        [_joinButton setTitle:@"卖光了" forState:UIControlStateNormal];
        _joinButton.backgroundColor = RGBCOLOR(0xF2, 0x2A, 0x39);
        [_joinButton removeTarget:self action:@selector(joinMeal:) forControlEvents:UIControlEventTouchDown];
    } else if (userID && [self.mealInfo hasJoined:userID]) {
        [_joinButton setTitle:@"已参加" forState:UIControlStateNormal];
        _joinButton.backgroundColor = RGBCOLOR(0xFF, 0xCC, 0);
        [_joinButton removeTarget:self action:@selector(joinMeal:) forControlEvents:UIControlEventTouchDown];
    } else {
        [_joinButton setTitle:@"参加饭局" forState:UIControlStateNormal];
        _joinButton.backgroundColor = RGBCOLOR(0, 0x99, 0);
        [_joinButton addTarget:self action:@selector(joinMeal:) forControlEvents:UIControlEventTouchDown];
    }
}

- (void) updateLikeButton{
    UserProfile* currentUser = [[Authentication sharedInstance] currentUser];
    NSString *userID = currentUser ? [NSString stringWithFormat:@"%d", currentUser.uID] : nil;
    [_likeButton setTitle:[NSString stringWithFormat:@"%d", _numberOfLikedPerson] forState:UIControlStateNormal];
    if (userID && [self.mealInfo hasLiked:userID]) {
        [_likeButton setTitleColor:RGBCOLOR(0xFF, 0x66, 0) forState:UIControlStateNormal];
        [_likeButton setImage:[UIImage imageNamed:@"like_big.png"] forState:UIControlStateNormal];
    } else {
        [_likeButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        [_likeButton setImage:[UIImage imageNamed:@"not_liked_big.png"] forState:UIControlStateNormal];
    }
}

- (void)initTabView {   
    _tabBar = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - TAB_BAR_HEIGHT, self.view.frame.size.width, TAB_BAR_HEIGHT)];
    _tabBar.backgroundColor = [UIColor clearColor];
    _joinButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 230, TAB_BAR_HEIGHT)];
    _joinButton.layer.borderColor = [UIColor grayColor].CGColor;
    _joinButton.layer.borderWidth = 1;
    _joinButton.titleLabel.textAlignment  = UITextAlignmentCenter;
    _joinButton.titleLabel.textColor = [UIColor whiteColor];
    _joinButton.titleLabel.font = [UIFont boldSystemFontOfSize:25];

    [self updateJoinButton];  
    _likeButton = [[UIButton alloc] initWithFrame:CGRectMake(230, 0, 90, TAB_BAR_HEIGHT)];
    _likeButton.backgroundColor = RGBCOLOR(0xEE, 0xEE, 0xEE);
    _likeButton.layer.borderWidth = 1;
    _likeButton.layer.borderColor = [UIColor grayColor].CGColor;
    UserProfile* currentUser = [[Authentication sharedInstance] currentUser];
    NSString *userID = currentUser ? [NSString stringWithFormat:@"%d", currentUser.uID] : nil;
    _initiallyLiked = [self.mealInfo hasLiked:userID];
    _like = _initiallyLiked;
    _numberOfLikedPerson = self.mealInfo.likes.count;
    [_likeButton addTarget:self action:@selector(likeButtonClicked:) forControlEvents:UIControlEventTouchDown];
    [_likeButton setImageEdgeInsets:UIEdgeInsetsMake(0, -10, 0, 0)]; // place the image a bit to the left
    [self updateLikeButton];
    
    [_tabBar addSubview:_joinButton];
    [_tabBar addSubview:_likeButton];
    
    [self.view addSubview:_tabBar];

}

-(void)viewDidLoad
{
    [super viewDidLoad];
    [SCAppUtils customizeNavigationController:self.navigationController];
    self.title = NSLocalizedString(@"MealDetail", nil);
    UIButton *back = [[UIButton alloc] init];
    [back setImage:[UIImage imageNamed:@"back.png"] forState:UIControlStateNormal];
    [back addTarget:self.navigationController 
            action:@selector(popViewControllerAnimated:) 
  forControlEvents:UIControlEventTouchDown];
    [back sizeToFit];
    UIBarButtonItem *temporaryBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:back];
    
    self.navigationItem.leftBarButtonItem = temporaryBarButtonItem;
    self.navigationItem.hidesBackButton = YES;
    
    UIButton* share = [UIButton buttonWithType:UIButtonTypeCustom];
    [share setImage:[UIImage imageNamed:@"share.png"] forState:UIControlStateNormal];
    [share addTarget:self action:@selector(onShareClicked:) forControlEvents:UIControlEventTouchDown];
    [share sizeToFit];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:share];
    
    [self.tableView setFrame:CGRectMake(0, 58-320, 320, 640)];
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
    
    itemsRow = [[NSMutableArray alloc] init];
    [sections addObject:@"Comments"]; 
    [self createLoadingView];
    [itemsRow addObject:_loadingOrNoCommentsLabel];
    [items addObject:itemsRow];
    
    
    TTSectionedDataSource* ds = [[TTSectionedDataSource alloc] initWithItems:items sections:sections];
    self.dataSource = ds;    
    [self requestDataFromServer];
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
    _detailsContentView = [[UIView alloc] initWithFrame:CGRectMake(H_GAP, V_GAP, DETAILS_CONTENT_VIEW_WIDTH, DETAILS_VIEW_HEIGHT)];
    _detailsContentView.backgroundColor = [UIColor clearColor];
    [_detailsView addSubview:_detailsContentView];
    _detailsView.backgroundColor = [UIColor clearColor];
    
    NSInteger y = 0;
    UILabel *topic = [[UILabel alloc] initWithFrame:CGRectMake(0, y, TOPIC_WIDTH, TOPIC_HEIGHT)];
    topic.text = self.mealInfo.topic;
    topic.font = [ UIFont boldSystemFontOfSize:18];
    topic.backgroundColor = [UIColor clearColor];
    [_detailsContentView addSubview:topic];
    
    TTShape* shape = [TTRoundedRectangleShape shapeWithRadius:4.5];
    UIColor* tintColor = RGBCOLOR(0xD9, 0xD9, 0xD9);
    TTStyle *style = [TTSTYLESHEET toolbarButtonForState:UIControlStateNormal shape:shape tintColor:tintColor font:[UIFont systemFontOfSize:12]];
    
    TTButton *menuButton = [[TTButton alloc] initWithFrame:CGRectMake(MENU_BUTTON_X, 0, MENU_BUTTON_WIDTH, MENU_BUTTON_HEIGH)];
    [menuButton setStyle:style forState:UIControlStateNormal];
    [menuButton setTitle:NSLocalizedString(@"Menu", nil)  forState:UIControlStateNormal];
    [menuButton addTarget:self action:@selector(displayMenu:) forControlEvents:UIControlEventTouchUpInside];
    [_detailsContentView addSubview:menuButton];
    
    y += TOPIC_HEIGHT;
    UILabel *type = [[UILabel alloc] initWithFrame:CGRectMake(0, y, DETAILS_CONTENT_VIEW_WIDTH, SMALL_LABEL_HEIGHT)];
    type.text = [NSString stringWithFormat:NSLocalizedString(@"MealType", nil), @"交友、烧烤、晚餐"];
    type.font = [ UIFont systemFontOfSize:12];
    type.backgroundColor = [UIColor clearColor];
    [_detailsContentView addSubview:type];
    
    y += SMALL_LABEL_HEIGHT;
    UILabel *timeAndCost = [[UILabel alloc] initWithFrame:CGRectMake(0, y, DETAILS_CONTENT_VIEW_WIDTH, SMALL_LABEL_HEIGHT)];
    timeAndCost.text = [NSString stringWithFormat:NSLocalizedString(@"TimeAndCost", nil),[DateUtil shortStringFromDate:self.mealInfo.time],self.mealInfo.price];
    timeAndCost.font = [ UIFont systemFontOfSize:12];
    timeAndCost.backgroundColor = [UIColor clearColor];
    [_detailsContentView addSubview:timeAndCost];
    
    y += SMALL_LABEL_HEIGHT;
    UILabel *restaurant = [[UILabel alloc] initWithFrame:CGRectMake(0, y, 45, SMALL_LABEL_HEIGHT)];
    restaurant.text = @"餐厅："; //TODO city/area
    restaurant.font = [ UIFont systemFontOfSize:12];
    restaurant.backgroundColor = [UIColor clearColor];
    [_detailsContentView addSubview:restaurant];

    NSInteger restaurantNameHeight = SMALL_LABEL_HEIGHT;
    NSString *restaurantNameStr = [NSString stringWithFormat:@"%@ %@", self.mealInfo.restaurant.address, self.mealInfo.restaurant.name];
    if (restaurantNameStr.length > 20) {
        restaurantNameHeight *= 2;
    }
    UILabel *restaurantName = [[UILabel alloc] initWithFrame:CGRectMake(SECOND_COLUMN_X, y, MAP_BUTTON_X - SECOND_COLUMN_X, restaurantNameHeight)];
    restaurantName.lineBreakMode = UILineBreakModeWordWrap;
    restaurantName.numberOfLines = restaurantNameStr.length > NUMBER_OF_CHARS_IN_ONE_LINE ? 2 : 1;    
    restaurantName.text = restaurantNameStr;//TODO city/area
    restaurantName.font = [ UIFont systemFontOfSize:12];
    restaurantName.backgroundColor = [UIColor clearColor];
    [_detailsContentView addSubview:restaurantName];

    _mapButton =  [[UIButton alloc] initWithFrame:CGRectMake(MAP_BUTTON_X, y, 40, 22)];
    [_mapButton setImage:[UIImage imageNamed:@"map.png"] forState:UIControlStateNormal];
    _mapButton.titleLabel.backgroundColor = RGBCOLOR(0xD9, 0xD9, 0xD9);
    [_detailsContentView addSubview:_mapButton];
    [_mapButton addTarget:self action:@selector(mapButtonClicked:) forControlEvents:UIControlEventTouchDown];
    
    y += restaurantNameHeight;

    _mapOriginY = y;
    _introduction = [[UILabel alloc] initWithFrame:CGRectMake(0, y, DETAILS_CONTENT_VIEW_WIDTH, SMALL_LABEL_HEIGHT)];
    [_introduction setNumberOfLines:0];
    _introduction.lineBreakMode = UILineBreakModeWordWrap;
    _introduction.text = [NSString stringWithFormat:NSLocalizedString(@"Introduction", nil), self.mealInfo.intro]; //TODO city/area
    _introduction.font = [ UIFont systemFontOfSize:12];
    _introduction.backgroundColor = [UIColor clearColor];
    [_detailsContentView addSubview:_introduction];
    
    y += SMALL_LABEL_HEIGHT;
    _numberOfPersons = [[UILabel alloc] initWithFrame:CGRectMake(0, y, DETAILS_CONTENT_VIEW_WIDTH, SMALL_LABEL_HEIGHT)];
    [self updateNumberOfParticipants];
    _numberOfPersons.font = [ UIFont systemFontOfSize:12];
    _numberOfPersons.backgroundColor = [UIColor clearColor];
    [_detailsContentView addSubview:_numberOfPersons];
        
    [self rebuildParticipantsView];    
}

-(void)displayMenu:(id)sender{
    TTButton* menuButton = sender;
    if (!_mealMenu) {
        [self updateMenuButton:menuButton withReadingStatus:YES];
        [self fetchMenu:sender];
    } else {
        [_menuPopover dismissPopoverAnimated:YES];
//        [_menuPopover presentPopoverFromRect:menuButton.frame inView:menuButton.superview permittedArrowDirections:UIPopoverArrowDirectionRight animated:YES];
//        [_menuPopover presentPopoverFromBarButtonItem:self.navigationItem.rightBarButtonItem permittedArrowDirections:UIPopoverArrowDirectionUp animated:NO];
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
//                                            _menuPopover = [[WEPopoverController alloc] initWithContentViewController:_menuContentViewController];
//                                            [_menuPopover presentPopoverFromRect:menuButton.frame inView:menuButton.superview permittedArrowDirections:UIPopoverArrowDirectionRight animated:YES];
//                                            [_menuPopover presentPopoverFromBarButtonItem:self.navigationItem.rightBarButtonItem permittedArrowDirections:UIPopoverArrowDirectionUp animated:NO];
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
    NSInteger y = _numberOfPersons.frame.origin.y + SMALL_LABEL_HEIGHT;
    _participants = [[UIView alloc] initWithFrame:CGRectMake(0, y, DETAILS_CONTENT_VIEW_WIDTH, PARTICIPANTS_HEIGHT)];
    _participants.backgroundColor = [UIColor clearColor];
    
    for (int i = 0; i < self.mealInfo.participants.count; i++) {//TODO to handle too many participants
        UserProfile *user = [self.mealInfo.participants objectAtIndex:i];
        UIImageView *img = [AvatarFactory avatarForUser:user frame:CGRectMake(40 * i, 0, 30, 30) delegate:self];
        [_participants addSubview:img];
    }
    [_detailsContentView addSubview:_participants];
    _mealDetailsViewDelegate.numberOfParticipantsExcludingHost = self.mealInfo.participants.count;
    
}

-(void) updateNumberOfParticipants{
     _numberOfPersons.text = [NSString stringWithFormat:NSLocalizedString(@"NumberOfPersons", nil), self.mealInfo.actualPersons, self.mealInfo.maxPersons]; }

- (void) mapButtonClicked:(id)sender{
    if (!_map) {
        _map = [[MKMapView alloc] initWithFrame:CGRectMake(0, _mapOriginY, MAP_WIDTH, MAP_HEIGHT - 5)];
        [_detailsContentView addSubview:_map];
        _map.layer.borderColor = [UIColor grayColor].CGColor;
        _map.layer.borderWidth = 1;
        _map.delegate = self;
        _map.hidden = TRUE;
        MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(self.mealInfo.restaurant.coordinate, 1000, 1000);
        MKCoordinateRegion adjustedRegion = [_map regionThatFits:viewRegion];
        [_map setRegion:adjustedRegion animated:YES];
        _location = [[Location alloc] initWithName:self.mealInfo.restaurant.name address:self.mealInfo.restaurant.address coordinate:self.mealInfo.restaurant.coordinate];
        [_map addAnnotation:_location];
    }
    
    _map.hidden = !_map.hidden;
    CGRect newRect;
    if (_map.hidden) {
        newRect = _introduction.frame;
        newRect.origin.y -= MAP_HEIGHT;
        _introduction.frame = newRect;
        
        newRect = _numberOfPersons.frame;
        newRect.origin.y -= MAP_HEIGHT;
        _numberOfPersons.frame = newRect;
        
        newRect = _participants.frame;
        newRect.origin.y -= MAP_HEIGHT;
        _participants.frame = newRect;
        [_mapButton setImage:[UIImage imageNamed:@"map.png"] forState:UIControlStateNormal];
        
        
    } else {
        newRect = _introduction.frame;
        newRect.origin.y += MAP_HEIGHT;
        _introduction.frame = newRect;
        
        newRect = _numberOfPersons.frame;
        newRect.origin.y += MAP_HEIGHT;
        _numberOfPersons.frame = newRect;
        
        newRect = _participants.frame;
        
        newRect.origin.y += MAP_HEIGHT;
        _participants.frame = newRect;
        [_mapButton setImage:[UIImage imageNamed:@"collapse.png"] forState:UIControlStateNormal];
    }
    _mealDetailsViewDelegate.mapHidden = _map.hidden;
    [self.tableView reloadData];
}

- (UIView*) createHostView{
    TTImageView *imgView = [[TTImageView alloc] initWithFrame:CGRectMake(0, 0, DISH_VIEW_WIDTH, DISH_VIEW_HEIGHT)];
    imgView.style = [TTShapeStyle styleWithShape:[TTSpeechBubbleShape shapeWithRadius:5 
                                                        pointLocation:314
                                                           pointAngle:270
                                                            pointSize:CGSizeMake(20,10)] next:
     [TTSolidFillStyle styleWithColor:[UIColor whiteColor] next:
     [TTSolidBorderStyle styleWithColor:[UIColor blackColor] width:1 next:nil]]];

    
    [imgView setContentMode:UIViewContentModeScaleAspectFill];
    [imgView setUrlPath:self.mealInfo.photoFullUrl];
    
    UIView *hostView = [[UIView alloc] initWithFrame:CGRectMake(0, 320-HOST_VIEW_HEIGHT, 320, HOST_VIEW_HEIGHT)];
    hostView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
    UserImageView *hostImg = [AvatarFactory avatarForUser:self.mealInfo.host frame:CGRectMake(8, 8, 41, 41)];
    [hostView addSubview:hostImg];
    
    UILabel *hostName = [[UILabel alloc] initWithFrame:CGRectMake(58, 8, 80, 20)];
    hostName.backgroundColor = [UIColor clearColor];
    hostName.text = self.mealInfo.host.name;
    hostName.textColor = [UIColor whiteColor];
    hostName.font = [UIFont boldSystemFontOfSize:14];
    [hostView addSubview:hostName];
    
    UILabel *statistic = [[UILabel alloc] initWithFrame:CGRectMake(58, 38, 200, 15)];
    statistic.backgroundColor = [UIColor clearColor];
    statistic.textColor = [UIColor whiteColor];
    //TODO numbers are faked 
    statistic.text = [NSString stringWithFormat:@"%@%d  %@%d  %@%d",NSLocalizedString(@"MealsCreated", nil), 9, NSLocalizedString(@"MealsJoined", nil), 30, NSLocalizedString(@"NumberOfFollowing", nil),78];
    statistic.font = [UIFont systemFontOfSize:12];
    [hostView addSubview:statistic];
    
    [imgView addSubview:hostView];
    return imgView;
}

- (id<UITableViewDelegate>)createDelegate {
    _mealDetailsViewDelegate = [[MealDetailsViewDelegate alloc] init];
    _mealDetailsViewDelegate.numberOfParticipantsExcludingHost = _mealInfo.participants.count;
    _mealDetailsViewDelegate.mapHidden = YES;
    return _mealDetailsViewDelegate;
}

- (IBAction)likeButtonClicked:(id)sender{ 
    [self sendLikeOrNotRequest];
    [_likeButton setEnabled:NO];
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

#pragma mark -
#pragma mark mapkit delegae
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation{
    MKPinAnnotationView *annotationView = (MKPinAnnotationView *)[_map dequeueReusableAnnotationViewWithIdentifier:@"Restaurant"];
    if (annotationView == nil) {
        annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"Restaurant"];
        annotationView.canShowCallout = YES;
        
        UIButton *rightButton= [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        annotationView.rightCalloutAccessoryView = rightButton;
        [rightButton addTarget:self action:@selector(openMapAndShowRoute:) forControlEvents:UIControlEventTouchDown];
    } else {
        annotationView.annotation = annotation;
    }
    
    annotationView.enabled = YES;
    annotationView.canShowCallout = YES;
    return annotationView;
}

-(void) openMapAndShowRoute:(id)sender{
//    CLLocationCoordinate2D user =  [[LocationProvider sharedProvider] lastLocation].coordinate;
    CLLocationCoordinate2D dest = self.mealInfo.restaurant.coordinate;
//    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://maps.google.com/maps?daddr=%f,%f&saddr=%@", dest.latitude, dest.longitude, NSLocalizedString(@"CurrentLocation", nil)]]];
//    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://maps.google.com/maps?daddr=%f,%f&saddr=%f,%f", dest.latitude, dest.longitude, user.latitude,user.longitude]]];
    
    NSString *route = [NSString stringWithFormat:@"http://maps.google.com/maps?saddr=%@&daddr=%g,%g", NSLocalizedString(@"CurrentLocation", nil), dest.latitude, dest.longitude];
//    NSString *route = [NSString stringWithFormat:@"http://maps.google.com/maps?saddr=%@&daddr=%@&ll=%g,%g&sll=%g,%g", NSLocalizedString(@"CurrentLocation", nil), self.mealInfo.restaurant.name, dest.latitude, dest.longitude,user.latitude,user.longitude];
    route = [route stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:route]];
}
-(void) mapViewDidFinishLoadingMap:(MKMapView *)mapView{
//    [_map selectAnnotation:_location animated:YES]; // seems not needed here
}

- (void)sendLikeOrNotRequest{
    if(![[Authentication sharedInstance] isLoggedIn]) {        
        // not logged in
        AppDelegate *delegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
        [delegate showLogin];
    } else {
        http_method_t method = _like ? DELETE : POST;//already liked? delete, or add
        [[NetworkHandler getHandler] requestFromURL:[NSString stringWithFormat:@"http://%@/api/v1/meal/%d/likes/", EOHOST, self.mealInfo.mID]
                                             method:method
                                        cachePolicy:TTURLRequestCachePolicyNone
                                            success:^(id obj) {
                                                if ([[obj objectForKey:@"status"] isEqualToString:@"OK"]) { 
                                                    NSLog(@"successfully set user like: %d, with info: %@", _like, [obj objectForKey:@"info"]);
                                                    _like = !_like;
                                                    _numberOfLikedPerson += _like ? 1 : -1;
                                                    UserProfile *me = [Authentication sharedInstance].currentUser;
                                                    if (_like) {
                                                        [self.mealInfo like:me];
                                                    } else {
                                                        [self.mealInfo dontLike:me];
                                                    }
                                                    
                                                    [_likeButton setEnabled:YES];
                                                    [self updateLikeButton];  
                                                    
                                                } else {
                                                    NSLog(@"failed to set user like:: %d, with error: %@", _like, [obj objectForKey:@"info"]);
                                                    [InfoUtil showError:obj];
                                                    [_likeButton setEnabled:YES];
                                                }
                                            } failure:^{
                                                NSLog(@"failed to set user like:: %d, reason unknown, probably network errors", _like);
                                                [InfoUtil showErrorWithString:@"操作失败，请稍后重试"];
                                                [_likeButton setEnabled:YES];
                                            }]; 
    }
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


