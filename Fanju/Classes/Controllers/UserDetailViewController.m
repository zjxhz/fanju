//
//  UserDetailViewController.m
//  EasyOrder
//
//  Created by igneus on 3/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UserDetailViewController.h"
#import "AppDelegate.h"
#import "NetworkHandler.h"
#import "Const.h"
#import "NSDictionary+ParseHelper.h"
#import "SVProgressHUD.h"
#import "AvatarFactory.h"
#import "SpeechBubble.h"
#import "OrderInfo.h"
#import "DateUtil.h"
#import "CommentListDataSource.h"
#import "CommentTableItem.h"
#import "Authentication.h"
#import "InfoUtil.h"
#import "Const.h"
#import "UserMoreDetailViewController.h"

#define TAG_MSG @"发消息"
#define TAG_COMMENT @"发评论"
#define TAB_BAR_HEIGHT 44

@implementation TTTableViewVarHeightDelegate(NoHeader)
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0;
}
@end

@interface UserDetailViewController () <TTPostControllerDelegate>
@property (weak, nonatomic) IBOutlet UILabel *name;
@property (weak, nonatomic) IBOutlet UILabel *lastupdate;
@property (strong, nonatomic) TTImageView *avatar;
@property (strong, nonatomic) TTTableViewController *table;
@property (weak, nonatomic) IBOutlet UILabel *nextMealLabel;
@property (weak, nonatomic) IBOutlet UILabel *nextMealTimeLabel;
@property (strong, nonatomic) SpeechBubble *motto;
@property (weak, nonatomic) IBOutlet UIView *detailView;
@property (weak, nonatomic) IBOutlet UILabel* college;
@property (weak, nonatomic) IBOutlet UILabel* occupation;
@property (weak, nonatomic) IBOutlet UIView* tabBar;
@property (weak, nonatomic) IBOutlet UIButton* followOrNot;
@end

@implementation UserDetailViewController
@synthesize name = _name;
@synthesize lastupdate = _lastupdate;
@synthesize avatar = _avatar;
@synthesize profile = _profile;
@synthesize table = _table;
@synthesize nextMealLabel = _nextMealLabel;
@synthesize nextMealTimeLabel = _nextMealTimeLabel;
@synthesize motto = _motto;
@synthesize detailView = _detailView;
@synthesize college = _college;
@synthesize occupation  = _occupation;
@synthesize tabBar = _tabBar;
@synthesize followOrNot = _followOrNot;
@synthesize delegate = _delegate;

-(id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        self.hidesBottomBarWhenPushed = YES;
    }
    return self;
}
- (void) loadView{
    [super loadView];
    AppDelegate *delegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    self.tableView.backgroundView = [[UIView alloc] initWithFrame:self.tableView.bounds];
    self.tableView.backgroundView.backgroundColor = [UIColor colorWithPatternImage:delegate.bgImage]; 
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    TTButton *btn = [TTButton buttonWithStyle:@"embossedBackButton:" title:NSLocalizedString(@"Back", nil)];
    [btn addTarget:self.navigationController 
            action:@selector(popViewControllerAnimated:) 
  forControlEvents:UIControlEventTouchDown];
    btn.font = [UIFont systemFontOfSize:13];
    [btn sizeToFit];
    
    UIBarButtonItem *temporaryBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:btn];
    
    self.navigationItem.leftBarButtonItem = temporaryBarButtonItem;
    self.navigationItem.hidesBackButton = YES;
    
    _avatar = [AvatarFactory avatarForUser:_profile frame:CGRectMake(10, 10, 60, 60)];
    [self.view addSubview:_avatar];

    [self.name setText:_profile.username];
    
    self.lastupdate.text = [NSString stringWithFormat:@"位置更新于：%@", _profile.locationUpdatedTime == nil ? @"未知":_profile.locationUpdatedTime];
    self.variableHeightRows = YES;
    self.tableView.backgroundColor = [UIColor clearColor]; 
    [self requestMessages];
    [self requestNextMeal];
}

-(void) requestNextMeal{
    _nextMealLabel.text = @"";
    _nextMealTimeLabel.text = @"";
    int userID = [Authentication sharedInstance].currentUser.uID;
    [[NetworkHandler getHandler] requestFromURL:[NSString stringWithFormat:@"http://%@/api/v1/user/%d/order/?format=json&order_by=meal__time", EOHOST, userID] method:GET cachePolicy:TTURLRequestCachePolicyNetwork
                                        success:^(id obj) {
                                            NSArray *orders = [obj objectForKeyInObjects];
                                            if (orders && [orders count] > 0) {
                                                OrderInfo *order = [OrderInfo orderInfoWithData:[orders objectAtIndex:0]];
                                                _nextMealLabel.text = order.meal.topic;
                                                _nextMealTimeLabel.text = [DateUtil shortStringFromDate:order.meal.time];
                                            }
                                        } failure:^{
                                            _nextMealLabel.text = @"最近没有饭局";
                                        }];
}
-(void) requestMessages{
    NSString *requestStr = [NSString stringWithFormat:@"http://%@/api/v1/user/%d/messages/?type=1&format=json", EOHOST, self.profile.uID];
    [[NetworkHandler getHandler] requestFromURL:requestStr
                                         method:GET
                                    cachePolicy:TTURLRequestCachePolicyNone 
                                        success:^(id obj) {                        
                                            CommentListDataSource *ds = [[CommentListDataSource alloc] init];
                                            NSArray *comments = [obj objectForKeyInObjects];
                                            if (comments && [comments count] > 0) {
                                                for (NSDictionary *comment in comments) {
                                                    UserProfile *from_person = [UserProfile profileWithData:[comment objectForKey:@"from_person"]];
                                                    NSString* user_comment = [comment objectForKey:@"message"];
                                                    CommentTableItem *item = [CommentTableItem itemFromUser:from_person withComment:user_comment];
                                                    [ds.items addObject:item];
                                                }  
                                            } else {
                                                [ds.items addObject:[TTTableSubtitleItem itemWithText:@"暂时还没有评论" subtitle:@"来抢沙发吧"]];
                                            }
                                            self.dataSource = ds;
                                        } failure:^{
                                            
                                        }];
}
-(void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    _motto = [[SpeechBubble alloc] initWithText:_profile.motto font:[UIFont systemFontOfSize:12] origin:CGPointMake(15, 82) pointLocation:50 width:290];
    [self.view addSubview:_motto];
    //replace the detail frame as the motto height is unknown
    CGRect frame = _detailView.frame;
    frame.origin.y = _motto.frame.origin.y + _motto.frame.size.height + 10;
    _detailView.frame = frame;
    _occupation.text = _profile.occupation;
    _college.text = _profile.college;
    
    int totalHeight = self.view.bounds.size.height ;
    int y = frame.origin.y + frame.size.height + 10;
    int tableViewHeight = totalHeight - y - TAB_BAR_HEIGHT;
    [self.tableView setFrame:CGRectMake(0, y, 320, tableViewHeight)];
    NSLog(@"table view height: %d", tableViewHeight);
    if([Authentication sharedInstance].currentUser.uID == _profile.uID){
        _tabBar.hidden = YES;
    }   else {
        _tabBar.hidden = NO;
        [self.view bringSubviewToFront:_tabBar];
        _tabBar.frame = CGRectMake(0, totalHeight - TAB_BAR_HEIGHT, 320, TAB_BAR_HEIGHT);
    }
    
    [self updateFollowOrNotButton];
    self.title = _profile.name;

}

-(void) updateFollowOrNotButton{
    if ([[Authentication sharedInstance].currentUser isFollowing:_profile]) {
        [_followOrNot setTitle:@"取消关注" forState:UIControlStateNormal];
    } else {
        [_followOrNot setTitle:@"关注" forState:UIControlStateNormal];
    }
}

- (IBAction)followOrNot:(id)sender {
    if ([_followOrNot.titleLabel.text isEqualToString:@"关注"] ) {
        [self follow];
    } else {
        [self unfollow];
    }
}

-(void)unfollow{
    int myID = [[Authentication sharedInstance] currentUser].uID;
    int userIdToBeUnfollowed = _profile.uID;
    NSArray *params = [NSArray array];
    http_method_t method = DELETE;
    NSString* url = [NSString stringWithFormat:@"%@://%@/api/v1/user/%d/following/%d/", HTTPS, EOHOST, myID, userIdToBeUnfollowed];
    
    _followOrNot.enabled = NO;
    _followOrNot.userInteractionEnabled = NO;
    [[NetworkHandler getHandler] requestFromURL:url
                                         method:method
                                     parameters:params
                                    cachePolicy:TTURLRequestCachePolicyNone
                                        success:^(id obj) {
                                            if ([[obj objectForKey:@"status"] isEqualToString:@"OK"]) {
                                                [SVProgressHUD showSuccessWithStatus:[obj objectForKey:@"info"]];
                                                NSString* unfollowedUID = [NSString stringWithFormat:@"%d",userIdToBeUnfollowed];
                                                [[[Authentication sharedInstance] currentUser].followings removeObject:unfollowedUID];
                                                [[Authentication sharedInstance] synchronize];
                                                [self updateFollowOrNotButton];
                                            } else {
                                                [InfoUtil showError:obj];
                                            }
                                            _followOrNot.enabled = YES;
                                            _followOrNot.userInteractionEnabled = YES;
                                            [_delegate userUnfollowed:_profile];
                                        } failure:^{
                                            [InfoUtil showErrorWithString:BLAME_NETWORK_ERROR_MESSAGE];
                                            _followOrNot.enabled = YES;
                                            _followOrNot.userInteractionEnabled = YES;
                                        }];
}

-(void)follow{
    int myID = [Authentication sharedInstance].currentUser.uID;
    NSArray *params = [NSArray arrayWithObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%d", self.profile.uID], @"value", @"user_id", @"key", nil]];
    http_method_t method = POST;
    NSString* url = [NSString stringWithFormat:@"%@://%@/api/v1/user/%d/following/", HTTPS, EOHOST, myID];
    _followOrNot.enabled = NO;
    _followOrNot.userInteractionEnabled = NO;
    [[NetworkHandler getHandler] requestFromURL:url
                                         method:method
                                     parameters:params
                                    cachePolicy:TTURLRequestCachePolicyNone
                                        success:^(id obj) {
                                            if ([[obj objectForKey:@"status"] isEqualToString:@"OK"]) {
                                                [SVProgressHUD showSuccessWithStatus:[obj objectForKey:@"info"]];
                                                NSString* followingUserID = [NSString stringWithFormat:@"%d",_profile.uID];
                                                [[Authentication sharedInstance].currentUser.followings addObject:followingUserID];
                                                [[Authentication sharedInstance] synchronize];
                                                [self updateFollowOrNotButton];
                                            } else {
                                                [SVProgressHUD dismissWithError:[obj objectForKey:@"info"]];
                                            }
                                            _followOrNot.enabled = YES;
                                            _followOrNot.userInteractionEnabled = YES;
                                            [_delegate userFollowed:_profile];
                                        } failure:^{
                                            [SVProgressHUD dismissWithError:BLAME_NETWORK_ERROR_MESSAGE];
                                            _followOrNot.enabled = YES;
                                            _followOrNot.userInteractionEnabled = YES;
                                        }];
}

- (IBAction)sendMsg:(id)sender {
    TTPostController* controller = [[TTPostController alloc] init];
    controller.delegate = self;
    controller.title = TAG_MSG;
    [controller showInView:self.view animated:YES];
}

- (IBAction)comment:(id)sender {
    TTPostController* controller = [[TTPostController alloc] init];
    controller.delegate = self;
    controller.title = TAG_COMMENT;
    [controller showInView:self.view animated:YES];
}

- (void)viewDidUnload {
    [self setName:nil];
    [self setLastupdate:nil];
    [self setAvatar:nil];
    [super viewDidUnload];
}

-(IBAction)block:(id)sender{
    UIAlertView *a = [[UIAlertView alloc] initWithTitle:@"未实现" message:@"未实现功能" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
    [a show];
}

-(IBAction)more:(id)sender{
    UserMoreDetailViewController* more = [[UserMoreDetailViewController alloc] initWithStyle:UITableViewStyleGrouped editable:NO];
    more.profile = _profile;
    [self.navigationController pushViewController:more animated:YES];
}

#pragma mark TTPostControllerDelegate
- (BOOL)postController:(TTPostController*)postController willPostText:(NSString*)text {
    BOOL messageOrComment = [postController.title isEqualToString:TAG_MSG];//YES=message, NO=comment
    NSArray *params = [NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys: messageOrComment ? @"0" : @"1", @"value", @"type", @"key", nil], 
                       [NSDictionary dictionaryWithObjectsAndKeys:text, @"value", @"message", @"key", nil], nil];
    [[NetworkHandler getHandler] requestFromURL:[NSString stringWithFormat:@"%@://%@/api/v1/user/%d/messages/", HTTPS, EOHOST, self.profile.uID]
                     method:POST
                 parameters:params
                cachePolicy:TTURLRequestCachePolicyNone
                    success:^(id obj) {
                        if ([[obj objectForKey:@"status"] isEqualToString:@"OK"]) {
                            if (messageOrComment) {
                                [SVProgressHUD showSuccessWithStatus:@"消息发送成功，但是现在还没有地方可以查看消息"];
                            } else {
                                [SVProgressHUD showSuccessWithStatus:[obj objectForKey:@"info"]];
                                CommentListDataSource *ds = self.dataSource;
                                [ds.items addObject:[CommentTableItem itemFromUser:[Authentication sharedInstance].currentUser withComment:text]]; 
                                [self.tableView reloadData];
                            }
                        } else {
                            [InfoUtil showError:obj];
                        }
                    } failure:^{
                        [InfoUtil showErrorWithString:BLAME_NETWORK_ERROR_MESSAGE];
                    }];
    
    return YES;
}

@end
