//
//  MealDetailCell.m
//  Fanju
//
//  Created by Xu Huanze on 6/14/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import "MealDetailCell.h"
#import "NINetworkImageView.h"
#import "Meal.h"
#import "Restaurant.h"
#import "MapViewController.h"
#import "AvatarFactory.h"
#import "UserDetailsViewController.h"
#import "MenuViewController.h"
#import "NetworkHandler.h"
#import "SVProgressHUD.h"
#import "CMPopTipView.h"

#define DISH_VIEW_HEIGHT 140
#define DISH_VIEW_WIDTH 320
#define H_GAP 7
#define V_GAP 13
#define RIGHT_LABEL_NORMAL_WIDTH 250
#define ADDRESS_WIDTH 210
#define PARTICIPANTS_WIDTH 53
#define PARTICIPANTS_HEIGHT PARTICIPANTS_WIDTH
#define PARTICIPANTS_GAP 2
#define PARTICIPANTS_VIEW_HEIGHT 68

static CGFloat theCellHeight;

@implementation MealDetailCell{
    Meal* _meal;
    UIView* _detailsView;
    UILabel *_numberOfPersons;
    UIScrollView *_participantsView;
    NSArray* _participants;
    UILabel* _topicLabel;
    UILabel* _timeLabel;
    UILabel* _addressLabel;
    MenuViewController *_menuContentViewController;
    MealMenu* _mealMenu;
    CMPopTipView *_navBarLeftButtonPopTipView;
}


+ (CGFloat)tableView:(UITableView*)tableView rowHeightForObject:(id)object{
    if ([object isKindOfClass:[Meal class]]) {
        return theCellHeight ? theCellHeight : 416;
    }
    return 0;
}

+(CGFloat)cellHeight{
    return theCellHeight;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}


-(void)setObject:(id)object{
    [super setObject:object];
    if (!object || object == _meal) {
        return;
    }
    _meal = object;
    [self buildUI];
}


-(void)buildUI{
    [self.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.contentView addSubview:[self createHostView]];
    [self.contentView addSubview:[self createDetailsView]];
}


- (UIView*) createHostView{
    UIView* hostView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, DISH_VIEW_WIDTH, DISH_VIEW_HEIGHT)];
    _mealImageView = [[NINetworkImageView alloc] initWithFrame:CGRectMake(0, 0, 320, DISH_VIEW_HEIGHT)];
    _mealImageView.clipsToBounds = YES;
    
    [_mealImageView setContentMode:UIViewContentModeScaleAspectFill];
    [_mealImageView setPathToNetworkImage:[URLService  absoluteURL:_meal.photoURL] forDisplaySize:CGSizeMake(320, 213)];
    UIImage* cost_bg = [[UIImage imageNamed:@"meal_details_cost"] resizableImageWithCapInsets:UIEdgeInsetsMake(22, 40, 22, 39)];
    UIImageView* costView = [[UIImageView alloc] initWithImage:cost_bg];
    costView.frame = CGRectMake(9, 0, 0, cost_bg.size.height);
    UILabel* costLabel = [[UILabel alloc] initWithFrame:CGRectMake(21, 4, 60, 20)];
    costLabel.backgroundColor = [UIColor clearColor];
    costLabel.textColor = RGBCOLOR(220, 220, 220);
    
    costLabel.text = [NSString stringWithFormat:@"人均：¥%.2f", [_meal.price floatValue]];
    costLabel.font = [UIFont systemFontOfSize:12];
    [costLabel sizeToFit];
    CGRect costFrame = costView.frame;
    costFrame.size.width = costLabel.frame.size.width + 12*2;
    costView.frame = costFrame;
    
    
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
    [hostView addSubview:costView];
    [hostView addSubview:costLabel];
    [hostView addSubview:menuBtn];
    return hostView;
}

- (UIView*)createDetailsView{
    _detailsView = [[UIView alloc] initWithFrame:CGRectMake(0, DISH_VIEW_HEIGHT, 320, 0)];
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
    UILabel* topicLabel = [self createRightLabel:CGPointMake(x, y) width:RIGHT_LABEL_NORMAL_WIDTH text:_meal.introduction];
    
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
    UILabel* timeLabel = [self createRightLabel:CGPointMake(x, y) width:RIGHT_LABEL_NORMAL_WIDTH text:[MealService dateTextOfMeal:_meal]];
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
    NSString *addressStr = [NSString stringWithFormat:@"%@ %@", _meal.restaurant.address, _meal.restaurant.name];
    UILabel* addressLabel = [self createRightLabel:CGPointMake(x, y) width:ADDRESS_WIDTH text:addressStr];
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
    _numberOfPersons = [self createRightLabel:CGPointMake(x, y) width:RIGHT_LABEL_NORMAL_WIDTH text:@"99/99"];
    [_detailsView addSubview:_numberOfPersons];
    _numberOfPersons.text = [NSString stringWithFormat:@"%@/%@", _meal.actualPersons, _meal.maxPersons];
    [_numberOfPersons sizeToFit];
    
    
    //participants
    [self rebuildParticipantsView];
    return _detailsView;
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
    theCellHeight = frame.origin.y + frame.size.height;
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

-(UILabel*)createRightLabel:(CGPoint)origin width:(CGFloat)width  text:(NSString*)text{
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

-(void)tableView:(UITableView*)tableView contentOffsetDidChange:(CGFloat)offset{
    if (offset > 0) {
        return;
    }
    CGRect frame = _mealImageView.frame;
    frame.origin.y = offset;
    frame.size.height = DISH_VIEW_HEIGHT - offset;
    _mealImageView.frame = frame;
}

-(void)fetchMenu:(id)sender{
    TTButton* menuButton = sender;
    [[NetworkHandler getHandler] requestFromURL:[NSString stringWithFormat:@"http://%@/api/v1/meal/%@/menu/", EOHOST, _meal.mID]
                                         method:GET
                                    cachePolicy:TTURLRequestCachePolicyNone
                                        success:^(id obj){
                                            [self updateMenuButton:menuButton withReadingStatus:NO];
                                            //the only object in meal/id/menu/
                                            NSDictionary* data = [[obj objectForKeyInObjects] objectAtIndex:0];
                                            _mealMenu = [MealMenu mealMenuWithData:data];
                                            _menuContentViewController = [[MenuViewController alloc] init];
                                            _menuContentViewController.mealMenu = _mealMenu;
                                            [_controller.view addSubview:_menuContentViewController.view];
                                        }
                                        failure:^(void){
                                            [self updateMenuButton:menuButton withReadingStatus:NO];
                                            DDLogError(@"failed to fetch menu");
                                            [SVProgressHUD showErrorWithStatus:@"获取菜单失败"];
                                        }];
    
    
}


-(void)displayMenu:(id)sender{
    TTButton* menuButton = sender;
    if (!_mealMenu) {
        [self updateMenuButton:menuButton withReadingStatus:YES];
        [self fetchMenu:sender];
    } else {
        //        [_menuPopover dismissPopoverAnimated:YES];
        //        [self.navigationController presentModalViewController:_cpc animated:NO];
        [_controller.view addSubview:_menuContentViewController.view];
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

- (void) mapButtonClicked:(id)sender{
    MapViewController* map = [[MapViewController alloc] initWithTitle:_meal.restaurant.name];
    map.restaurant = _meal.restaurant;
    [_controller.navigationController pushViewController:map animated:YES];
}


-(void)avatarTapped:(UITapGestureRecognizer*)tap{
    UIView* view = tap.view;
    NSInteger tag = view.tag;
    UserDetailsViewController* userDetails = [[UserDetailsViewController alloc] init];
    userDetails.user = _participants[tag];
    [_controller.navigationController pushViewController:userDetails animated:YES];
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
    [_navBarLeftButtonPopTipView presentPointingAtView:view inView:_controller.view animated:YES];
}
@end
