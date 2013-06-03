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
#import "DateUtil.h"
#import "MealDetailViewController.h"
#import "MealEventCell.h"
#import "UploadPhotoEventCell.h"
#import "SimpleUserEventCell.h"
#import "WidgetFactory.h"
#import "SVProgressHUD.h"
#import "NotificationService.h"
#import "RestKit.h"
#import "UserService.h"
#import "Notification.h"
#import "PhotoNotification.h"
#import "MealNotification.h"
#import "Meal.h"
#import "MealService.h"
#import "URLService.h"
#import "Photo.h"
#import "UserDetailsViewController.h"
#import "LoadMoreTableItem.h"
#import "LoadMoreTableItemCell.h"

#define FETCH_LIMIT 20

@interface NotificationViewController (){
    NSMutableArray* _notifications;
    NSManagedObjectContext* _contex;
    NSFetchRequest* _fetchRequest;
    NSInteger _fetchOffset;
    LoadMoreTableItem* _loadMoreItem;
    NSInteger _notificationTotalCount;
}

@end

@implementation NotificationViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        _notifications = [NSMutableArray array];
        RKManagedObjectStore* store = [RKObjectManager sharedManager].managedObjectStore;
        _contex = store.mainQueueManagedObjectContext;
        self.navigationItem.titleView = [[WidgetFactory sharedFactory] titleViewWithTitle:@"通知"];
        self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg"]];
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self requestNotifications];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] postNotificationName:UnreadNotificationCount
                                                        object:[NSNumber numberWithInteger:0]
                                                      userInfo:nil];
    [[NotificationService service] markAllNotificationsRead];
}

-(void) requestNotifications{
    _fetchRequest = [[NSFetchRequest alloc] init];
    _fetchRequest.entity = [NSEntityDescription entityForName:@"Notification" inManagedObjectContext:_contex];
    _fetchRequest.includesSubentities = YES;
    _fetchRequest.predicate = [NSPredicate predicateWithFormat:@"owner == %@", [UserService service].loggedInUser];
    NSSortDescriptor *sortByTime = [[NSSortDescriptor alloc] initWithKey:@"time" ascending:NO];//时间降序，最新的在前
    _fetchRequest.sortDescriptors = @[sortByTime];
    NSError* error;
    _notificationTotalCount = [_contex countForFetchRequest:_fetchRequest error:&error];
    if(_notificationTotalCount == NSNotFound) {
        DDLogError(@"failed to count notification count: %@", error);
    }
    _fetchRequest.fetchLimit = FETCH_LIMIT;
    NSArray* objects = [_contex executeFetchRequest:_fetchRequest error:&error];

    for (Notification* notification in objects) {
        [self createAndInsertNotification:notification append:YES];
    }
    _fetchOffset += objects.count;
    [self setOrNullifyLoadMore];
    [self.tableView reloadData];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(notificationDidSave:)
                                                 name:NotificationDidSaveNotification
                                               object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(messageDidDelete:)
//                                                 name:EOMessageDidDeleteNotification
//                                               object:nil]; TODO deletion
//    [[XMPPHandler sharedInstance] updateUnreadCount]; //manually update the unread count so that unread count on the side bar looks same with what is showing here TODO update unread count
}

-(void)setOrNullifyLoadMore{
    if (_notificationTotalCount > _fetchOffset) {
        _loadMoreItem = [[LoadMoreTableItem alloc] init];
    } else {
        _loadMoreItem = nil;
    }
}
-(void)createAndInsertNotification:(Notification*)notification append:(BOOL)append{
    if (append) {
        [_notifications addObject:notification];
    } else {
        [_notifications insertObject:notification atIndex:0];
    }
    [self.tableView reloadData];
}


-(void)notificationDidSave:(NSNotification*)notif{
    Notification* notification = notif.object;
    [self createAndInsertNotification:notification append:NO];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _notifications.count + (_loadMoreItem != nil);
}

-(void)insertNotifications:(NSArray*)notifications{
    for (Notification *notification in notifications) {
        [self createAndInsertNotification:notification append:NO];//TODO insert a bunch of data
    }
    [self.tableView reloadData];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row == _notifications.count) {
        return 50;
    }
    Notification* notification = [_notifications objectAtIndex:indexPath.row];
    if ([notification isKindOfClass:[PhotoNotification class]] || [notification isKindOfClass:[MealNotification class]]) {
        return 75;
    }
    return 55;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = nil;
    if (indexPath.row == _notifications.count) {
        return [[LoadMoreTableItemCell alloc] init];
    }
    
    
    Notification* notification = [_notifications objectAtIndex:indexPath.row];
    if ([notification isKindOfClass:[MealNotification class]]) {
        NSString* CellIdentifier = @"MealEventCell";
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (!cell) {
            UIViewController* temp = [[UIViewController alloc] initWithNibName:@"MealEventCell" bundle:nil];
            cell = (UITableViewCell*)temp.view;
        }
        MealEventCell* mealEventCell = (MealEventCell*)cell;
        MealNotification* mn = (MealNotification*)notification;
        mealEventCell.topic.text = [NSString stringWithFormat:@" %@ ", mn.meal.topic]; //spaces to create margins
        [mealEventCell.topic sizeToFit];
        [mealEventCell.mealImage setPathToNetworkImage:[URLService absoluteURL:mn.meal.photoURL] forDisplaySize:mealEventCell.mealImage.frame.size contentMode:UIViewContentModeScaleAspectFill];

    } else if([notification isKindOfClass:[PhotoNotification class]]){
        NSString* CellIdentifier = @"UploadPhotoEventCell";
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (!cell) {
            UIViewController* temp = [[UIViewController alloc] initWithNibName:CellIdentifier bundle:nil];
            cell = (UITableViewCell*)temp.view;
        }
        UploadPhotoEventCell* photoEventCell = (UploadPhotoEventCell*)cell;
        PhotoNotification* pn = (PhotoNotification*)notification;
        [photoEventCell.photo setPathToNetworkImage:[URLService  absoluteURL:pn.photo.thumbnailURL] forDisplaySize:photoEventCell.photo.frame.size ];
        photoEventCell.clipsToBounds = YES;
        float degrees = 30; //the value in degrees
        photoEventCell.photo.transform = CGAffineTransformMakeRotation(degrees * M_PI/180.0);
    } else if([notification isKindOfClass:[Notification class]]) {
        NSString* CellIdentifier = @"SimpleUserEventCell";
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (!cell) {
            UIViewController* temp = [[UIViewController alloc] initWithNibName:CellIdentifier bundle:nil];
            cell = (UITableViewCell*)temp.view;
        }
    }
    
    if ([notification isKindOfClass:[Notification class]]) {
        SimpleUserEventCell* eventCell = (SimpleUserEventCell*)cell;
        [self configureSimpleUserEventCell:eventCell forEvent:notification];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

-(void)configureSimpleUserEventCell:(SimpleUserEventCell*)userEventCell forEvent:(Notification*)notification{
    CGRect frame = userEventCell.avatar.frame;
    [userEventCell.avatar setPathToNetworkImage:[UserService avatarURLForUser:notification.user] forDisplaySize:frame.size contentMode:UIViewContentModeScaleAspectFill];
    userEventCell.avatar.layer.cornerRadius = 5;
    userEventCell.avatar.layer.masksToBounds = YES;
    userEventCell.name.text = notification.user.name;
    userEventCell.event.text = notification.eventDescription;
    userEventCell.time.text = [DateUtil userFriendlyStringFromDate:notification.time];
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
    if (indexPath.row == _notifications.count) {
        if (_loadMoreItem.loading) {
            return;
        }
        _loadMoreItem.loading = YES;
        [self.tableView reloadData];
        [self loadEarlierNotifications];
        return;
    }
    id notif = [_notifications objectAtIndex:indexPath.row];
    if([notif isKindOfClass:[MealNotification class]]){
        MealDetailViewController *mealDetail = [[MealDetailViewController alloc] init];
        MealNotification* mn = notif;
        mealDetail.meal = mn.meal;
        [self.navigationController pushViewController:mealDetail animated:YES];
    } else if ([notif isKindOfClass:[Notification class]]) {
        Notification* notification = notif;
        UserDetailsViewController* details = [[UserDetailsViewController alloc] init];
        details.user = notification.user;
        [self.navigationController pushViewController:details animated:YES];
    } 
}


-(void)loadEarlierNotifications{
    _fetchRequest.fetchOffset = _fetchOffset;
    NSError* error;
    _fetchRequest.fetchLimit = FETCH_LIMIT;
    
    NSArray* objects = [_contex executeFetchRequest:_fetchRequest error:&error];
    for (Notification* notification in objects) {
        [self createAndInsertNotification:notification append:YES];
    }
    _fetchOffset += objects.count;
    [self setOrNullifyLoadMore];
}

//
//-(void)reloadLastRow{
//    UserListDataSource *ds = self.dataSource;
//    NSArray *lastRow = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:(ds.items.count - 1) inSection:0]];
//    [self.tableView reloadRowsAtIndexPaths:lastRow withRowAnimation:UITableViewRowAnimationAutomatic];
//}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    return [touch.view isKindOfClass:[UIImageView class]];
}

-(void)avatarTapped:(UITapGestureRecognizer *)tap {
//    if (UIGestureRecognizerStateEnded == tap.state) {
//        CGPoint p = [tap locationInView:tap.view];
//        NSIndexPath* indexPath = [self.tableView indexPathForRowAtPoint:p];
//        id event = [_notifications objectAtIndex:indexPath.row];
//        if ([event isKindOfClass:[SimpleUserEvent class]]) {
//            SimpleUserEvent* se = event;
//            [self pushUserDetails:se.userID];
//        } else if([event isKindOfClass:[JoinMealEvent class]]){
//            JoinMealEvent* je = (JoinMealEvent*)event;
//            [self pushUserDetails:je.participantID];
//        }
//    }
}

@end
