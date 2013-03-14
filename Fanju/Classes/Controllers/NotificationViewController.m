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
        self.title = @"消息";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self requestEvents];
}

-(void) requestEvents{
    NSFetchRequest *req = [[NSFetchRequest alloc] init];
    NSManagedObjectContext* context = [XMPPHandler sharedInstance].messageManagedObjectContext;
    req.entity = [NSEntityDescription entityForName:@"EOMessage" inManagedObjectContext:context];
//    req.predicate = [NSPredicate predicateWithFormat:@"node.length > 0"]; //TODO notification filtering
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
    NSDictionary* data = [message.payload objectFromJSONString];
    id event = [[EventFactory sharedFactory] createEvent:message];
    if ([event isKindOfClass:[SimpleUserEvent class]]) {
        SimpleUserEvent* sue = event;
        sue.userID = [data valueForKey:sue.userFieldName];
        [self setOrFetchUser:sue propertyName:@"user" userID:sue.userID];
    } else if([event isKindOfClass:[JoinMealEvent class]]){
        JoinMealEvent* je = event;
        NSString* participantID = [data valueForKey:@"participant"];
        je.participantID = participantID;
        [self setOrFetchUser:je propertyName:@"participant" userID:participantID];
        
        NSString* mealID = [data valueForKey:@"meal"];
        je.mealID = mealID;
        MealInfo* meal = [self loadMealFromCache:mealID];
        
        if (meal) {
            je.meal = meal;
            [self.tableView reloadData];
        } else {//user info not found in cache, touch the network and save it to cache for later use
            [[NetworkHandler getHandler] requestFromURL:[self mealURL:mealID] method:GET cachePolicy:TTURLRequestCachePolicyDefault success:^(id obj){
                [self.tableView reloadData];
            } failure:^{
                NSLog(@"failed to load meal in notifications");
            }];
        }
        
    }
    if (event) {
        EventBase* eb = event;
        eb.time = message.time;
        if (append) {
            [_notifications addObject:event];
        } else {
            [_notifications insertObject:event atIndex:0];
        }
        [self.tableView reloadData];
    }
}

-(void)setOrFetchUser:(id)target propertyName:(NSString*)propertyName userID:(NSString*)userID{
    UserProfile* user = [self loadUserFromCache:userID];
    
    if (user) {
        [target setValue:user forKey:propertyName];
        [self loadUserAvatar:user];
        [self.tableView reloadData];
    } else {//user info not found in cache, touch the network and save it to cache for later use
        [[NetworkHandler getHandler] requestFromURL:[self userURL:userID] method:GET cachePolicy:TTURLRequestCachePolicyDefault success:^(id obj){
            [self.tableView reloadData];
        } failure:^{
            NSLog(@"failed to load users in notifications");
        }];
    }
}

-(UserProfile*)loadUserFromCache:(NSString*)userID{
    NSString* url = [self userURL:userID];
    NSData* cachedData = [[TTURLCache sharedCache] dataForURL:url];
    NSDictionary* dict = [cachedData objectFromJSONData];
    if (dict) {
        return [UserProfile profileWithData:dict];
    }
    return nil;
}

-(MealInfo*)loadMealFromCache:(NSString*)mealID{
    NSString* url = [NSString stringWithFormat:@"http://%@/api/v1/meal/%@/?format=json", EOHOST, mealID];
    NSData* cachedData = [[TTURLCache sharedCache] dataForURL:url];
    NSDictionary* dict = [cachedData objectFromJSONData];
    if (dict) {
        return [MealInfo mealInfoWithData:dict];
    }
    return nil;
}

-(NSString*)userURL:(NSString*)userID{
   return [NSString stringWithFormat:@"http://%@/api/v1/simple_user/%@/?format=json", EOHOST, userID];
}

-(NSString*)mealURL:(NSString*)mealID{
    return [NSString stringWithFormat:@"http://%@/api/v1/meal/%@/?format=json", EOHOST, mealID];
}

-(void)loadUserAvatar:(UserProfile*)user{
    TTURLRequest* request = [TTURLRequest requestWithURL:[user smallAvatarFullUrl] delegate:nil];
    request.response = [[TTURLImageResponse alloc] init];
    [request send];
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"NotiticationCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    EventBase* event = [_notifications objectAtIndex:indexPath.row];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        UILabel* timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 60, 25)];
        timeLabel.backgroundColor = [UIColor clearColor];
        cell.accessoryView = timeLabel;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.imageView.userInteractionEnabled = YES;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(avatarTapped:)];
        tap.delegate = self;
        [cell.imageView addGestureRecognizer:tap];
        cell.imageView.image = [UIImage imageNamed:@"anno"];
    }
    
    UILabel* timeLabel = (UILabel* )cell.accessoryView;
    timeLabel.text = [DateUtil userFriendlyStringFromDate:event.time];
    
    if ([event isKindOfClass:[SimpleUserEvent class]]) {
        SimpleUserEvent* se = (FollowerEvent*)event;
        if (!se.user) {
            se.user = [self loadUserFromCache:se.userID];
        }
        
        if (se.user) {
            [self configureCell:cell withUser:se.user];
            cell.detailTextLabel.text = se.eventDescription;
        } else {
            [self configureLoadingCell:cell];
        }
    } else if ([event isKindOfClass:[JoinMealEvent class]]) {
        JoinMealEvent* je = (JoinMealEvent*)event;
        if (!je.participant) {
            je.participant = [self loadUserFromCache:je.participantID];
        }
        if (!je.meal) {
            je.meal = [self loadMealFromCache:je.mealID];
        }
        
        if (je.participant && je.meal) {
            [self configureCell:cell withUser:je.participant];
            cell.detailTextLabel.text = [NSString stringWithFormat:@"参加了饭局：%@", je.meal.topic];
        } else {
            [self configureLoadingCell:cell];
        }
    }
    return cell;
}

-(void)configureCell:(UITableViewCell*)cell withUser:(UserProfile*)user{
    cell.textLabel.text = user.name;
    NSData* data =  [[TTURLCache sharedCache] dataForURL:[user smallAvatarFullUrl]];
    UIImage* image = [UIImage imageWithData:data];
    if (image) {
        cell.imageView.image = image;
    }
}

-(void)configureLoadingCell:(UITableViewCell*)cell{
    cell.textLabel.text = @"正在加载……";
    cell.detailTextLabel.text = @"";
    cell.imageView.image = [UIImage imageNamed:@"anno"];
}

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
    if ([event isKindOfClass:[SimpleUserEvent class]]) {
        SimpleUserEvent* se = event;
        [self pushUserDetails:se.user];
    } else if([event isKindOfClass:[JoinMealEvent class]]){
        JoinMealEvent* je = (JoinMealEvent*)event;
        if (je.meal) {
            MealDetailViewController *mealDetail = [[MealDetailViewController alloc] init];
            mealDetail.mealInfo = je.meal;
            [self.navigationController pushViewController:mealDetail animated:YES];
        }
    }
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
            [self pushUserDetails:se.user];
        } else if([event isKindOfClass:[JoinMealEvent class]]){
            JoinMealEvent* je = (JoinMealEvent*)event;
            [self pushUserDetails:je.participant];
        }
    }
}

-(void)pushUserDetails:(UserProfile*)user{
    if (user) {
        NewUserDetailsViewController* detailViewController = [[NewUserDetailsViewController alloc] initWithStyle:UITableViewStylePlain];
        detailViewController.user = user;
        [self.navigationController pushViewController:detailViewController animated:YES];
    }
}
@end
