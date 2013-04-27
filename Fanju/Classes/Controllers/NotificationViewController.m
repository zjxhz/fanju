//
//  NotificationViewController.m
//  EasyOrder
//
//  Created by Xu Huanze on 2/28/13.
//
//

#import "NotificationViewController.h"
#import "JSONKit.h"
#import "NetworkHandler.h"
#import "NSDictionary+ParseHelper.h"
#import "NINetworkImageView.h"
#import "XMPPHandler.h"
#import "FollowerEvent.h"
#import "DateUtil.h"
#import "NewUserDetailsViewController.h"
#import "JoinMealEvent.h"
#import "MealDetailViewController.h"
#import "VisitorEvent.h"
#import "EventFactory.h"
#import "MealEventCell.h"
#import "PhotoUploadedEvent.h"
#import "UploadPhotoEventCell.h"
#import "SimpleUserEventCell.h"
#import "WidgetFactory.h"
#import "SVProgressHUD.h"

@interface NotificationViewController (){
    NSMutableArray* _notifications;
}

@end

@implementation NotificationViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        _notifications = [NSMutableArray array];
        self.navigationItem.titleView = [[WidgetFactory sharedFactory] titleViewWithTitle:@"通知"];
        self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg"]];
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self requestEvents];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] postNotificationName:EOUnreadNotificationCount
                                                        object:[NSNumber numberWithInteger:0]
                                                      userInfo:nil];
    [[XMPPHandler sharedInstance] markMessagesReadFrom:PUBSUB_SERVICE];
}

-(void) requestEvents{
    NSFetchRequest *req = [[NSFetchRequest alloc] init];
    NSManagedObjectContext* context = [XMPPHandler sharedInstance].messageManagedObjectContext;
    req.entity = [NSEntityDescription entityForName:@"EOMessage" inManagedObjectContext:context];
    req.predicate = [NSPredicate predicateWithFormat:@"node != ''"];
    NSSortDescriptor *sortByTime = [[NSSortDescriptor alloc] initWithKey:@"time" ascending:NO];
    req.sortDescriptors = @[sortByTime];
    
    NSError* error;
    NSArray* objects = [context executeFetchRequest:req error:&error];
    for (EOMessage* message in objects) {
        [self createAndInsertEvent:message append:YES];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(notificationDidSave:)
                                                 name:EONotificationDidSaveNotification
                                               object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(messageDidDelete:)
//                                                 name:EOMessageDidDeleteNotification
//                                               object:nil]; TODO deletion
//    [[XMPPHandler sharedInstance] updateUnreadCount]; //manually update the unread count so that unread count on the side bar looks same with what is showing here TODO update unread count
}

-(void)createAndInsertEvent:(EOMessage*)message append:(BOOL)append{
    id event = [[EventFactory sharedFactory] createEvent:message];    
    if (event) {
        if (append) {
            [_notifications addObject:event];
        } else {
            [_notifications insertObject:event atIndex:0];
        }
        [self.tableView reloadData];
    }
}


-(void)notificationDidSave:(NSNotification*)notif{
    EOMessage* message = notif.object;
    [self createAndInsertEvent:message append:NO];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _notifications.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    EventBase* event = [_notifications objectAtIndex:indexPath.row];
    if ([event isKindOfClass:[PhotoUploadedEvent class]] || [event isKindOfClass:[JoinMealEvent class]]) {
        return 75;
    }
    return 55;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    UITableViewCell *cell = nil;
    EventBase* event = [_notifications objectAtIndex:indexPath.row];
    
    
    
    if ([event isKindOfClass:[JoinMealEvent class]]) {
        NSString* CellIdentifier = @"MealEventCell";
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (!cell) {
            UIViewController* temp = [[UIViewController alloc] initWithNibName:@"MealEventCell" bundle:nil];
            cell = (UITableViewCell*)temp.view;
        }
        MealEventCell* mealEventCell = (MealEventCell*)cell;
        CGRect frame = mealEventCell.avatar.frame;
        JoinMealEvent* je = (JoinMealEvent*)event;
        [mealEventCell.avatar setPathToNetworkImage:je.avatar forDisplaySize:frame.size contentMode:UIViewContentModeScaleAspectFill];
        mealEventCell.avatar.layer.cornerRadius = 5;
        mealEventCell.avatar.layer.masksToBounds = YES;
        mealEventCell.name.text = je.userName;
        mealEventCell.event.text = je.eventDescription;
        mealEventCell.topic.text = je.mealTopic;
        mealEventCell.time.text = [DateUtil userFriendlyStringFromDate:je.time];
        [mealEventCell.mealImage setPathToNetworkImage:je.mealPhoto forDisplaySize:mealEventCell.mealImage.frame.size contentMode:UIViewContentModeScaleAspectFill];
    } else if([event isKindOfClass:[PhotoUploadedEvent class]]){
        NSString* CellIdentifier = @"UploadPhotoEventCell";
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (!cell) {
            UIViewController* temp = [[UIViewController alloc] initWithNibName:CellIdentifier bundle:nil];
            cell = (UITableViewCell*)temp.view;
        }
        UploadPhotoEventCell* photoEventCell = (UploadPhotoEventCell*)cell;
        CGRect frame = photoEventCell.avatar.frame;
        PhotoUploadedEvent* pu = (PhotoUploadedEvent*)event;
        [photoEventCell.avatar setPathToNetworkImage:pu.avatar forDisplaySize:frame.size contentMode:UIViewContentModeScaleAspectFill];
        photoEventCell.avatar.layer.cornerRadius = 5;
        photoEventCell.avatar.layer.masksToBounds = YES;
        photoEventCell.name.text = pu.userName;
        photoEventCell.event.text = pu.eventDescription;
        photoEventCell.time.text = [DateUtil userFriendlyStringFromDate:pu.time];
        [photoEventCell.photo setPathToNetworkImage:pu.photo forDisplaySize:photoEventCell.photo.frame.size ];
        photoEventCell.clipsToBounds = YES;
        float degrees = 30; //the value in degrees
        photoEventCell.photo.transform = CGAffineTransformMakeRotation(degrees * M_PI/180.0);
    } else if([event isKindOfClass:[SimpleUserEvent class]]) {
        NSString* CellIdentifier = @"SimpleUserEventCell";
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (!cell) {
            UIViewController* temp = [[UIViewController alloc] initWithNibName:CellIdentifier bundle:nil];
            cell = (UITableViewCell*)temp.view;
        }
    }
    
    if ([event isKindOfClass:[SimpleUserEvent class]]) {
        SimpleUserEventCell* eventCell = (SimpleUserEventCell*)cell;
        SimpleUserEvent* userEvent = (SimpleUserEvent*)event;
        [self configureSimpleUserEventCell:eventCell forEvent:userEvent];
    }
    
    
//    UILabel* timeLabel = (UILabel* )cell.accessoryView;
//    timeLabel.text = [DateUtil userFriendlyStringFromDate:event.time];
    
//    if ([event isKindOfClass:[SimpleUserEvent class]]) {
//        SimpleUserEvent* se = (FollowerEvent*)event;
//        if (!se.user) {
//            se.user = [self loadUserFromCache:se.userID];
//        }
//        
//        if (se.user) {
//            [self configureCell:cell withUser:se.user];
//            cell.detailTextLabel.text = se.eventDescription;
//        } else {
//            [self configureLoadingCell:cell];
//        }
//    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

-(void)configureSimpleUserEventCell:(SimpleUserEventCell*)userEventCell forEvent:(SimpleUserEvent*)event{
    CGRect frame = userEventCell.avatar.frame;
    SimpleUserEvent* sue = (SimpleUserEvent*)event;
    [userEventCell.avatar setPathToNetworkImage:sue.avatar forDisplaySize:frame.size contentMode:UIViewContentModeScaleAspectFill];
    userEventCell.avatar.layer.cornerRadius = 5;
    userEventCell.avatar.layer.masksToBounds = YES;
    userEventCell.name.text = sue.userName;
    userEventCell.event.text = sue.eventDescription;
    userEventCell.time.text = [DateUtil userFriendlyStringFromDate:sue.time];
}

//-(void)configureCell:(UITableViewCell*)cell withUser:(UserProfile*)user{
//    cell.textLabel.text = user.name;
//    NSData* data =  [[TTURLCache sharedCache] dataForURL:[user smallAvatarFullUrl]];
//    UIImage* image = [UIImage imageWithData:data];
//    if (image) {
//        cell.imageView.image = image;
//    }
//}
//
//-(void)configureLoadingCell:(UITableViewCell*)cell{
//    cell.textLabel.text = @"正在加载……";
//    cell.detailTextLabel.text = @"";
//    cell.imageView.image = [UIImage imageNamed:@"anno"];
//}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id event = [_notifications objectAtIndex:indexPath.row];
    if([event isKindOfClass:[JoinMealEvent class]]){
        JoinMealEvent* je = (JoinMealEvent*)event;
        if (je.mealID) {
            [self pushMealDetailsView:je.mealID];
        }
    } else if ([event isKindOfClass:[SimpleUserEvent class]]) {
        SimpleUserEvent* se = event;
        if (se.userID) {
            [self pushUserDetails:se.userID];
        }
        
    } 
}

-(void)pushMealDetailsView:(NSInteger)mealID{
    MealDetailViewController *mealDetail = [[MealDetailViewController alloc] init];
    [[NetworkHandler getHandler] requestFromURL:[NSString stringWithFormat:@"http://%@/api/v1/meal/%d/?format=json", EOHOST, mealID]
                                         method:GET
                                    cachePolicy:TTURLRequestCachePolicyDefault
                                        success:^(id obj) {
                                            NSDictionary* dic = obj;
                                            MealInfo* meal = [MealInfo mealInfoWithData:dic];
                                            mealDetail.mealInfo = meal;
                                            [self.navigationController pushViewController:mealDetail animated:YES];
                                        } failure:^{
                                            NSLog(@"failed to get user  for id %d", mealID);
                                        }];
    

}
#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    return [touch.view isKindOfClass:[UIImageView class]];
}

-(void)avatarTapped:(UITapGestureRecognizer *)tap {
    if (UIGestureRecognizerStateEnded == tap.state) {
        CGPoint p = [tap locationInView:tap.view];
        NSIndexPath* indexPath = [self.tableView indexPathForRowAtPoint:p];
        id event = [_notifications objectAtIndex:indexPath.row];
        if ([event isKindOfClass:[SimpleUserEvent class]]) {
            SimpleUserEvent* se = event;
            [self pushUserDetails:se.userID];
        } else if([event isKindOfClass:[JoinMealEvent class]]){
            JoinMealEvent* je = (JoinMealEvent*)event;
            [self pushUserDetails:je.participantID];
        }
    }
}

-(void)pushUserDetails:(NSString*)userID{
    [[NetworkHandler getHandler] requestFromURL:[NSString stringWithFormat:@"http://%@/api/v1/user/%@/?format=json", EOHOST, userID]
                                         method:GET
                                    cachePolicy:TTURLRequestCachePolicyDefault
                                        success:^(id obj) {
                                            NSDictionary* dic = obj;
                                            UserProfile* user = [UserProfile profileWithData:dic];
                                            NewUserDetailsViewController* detailViewController = [[NewUserDetailsViewController alloc] initWithStyle:UITableViewStylePlain];
                                            detailViewController.user = user;
                                            [self.navigationController pushViewController:detailViewController animated:YES];
                                        } failure:^{
                                            NSLog(@"failed to get user  for id %@", userID);
                                        }];
}

@end
