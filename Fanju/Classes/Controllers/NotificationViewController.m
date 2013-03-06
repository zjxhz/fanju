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
    if ([EventBase eventType:message] == [FollowerEvent class]) {
        NSDictionary* data = [message.payload objectFromJSONString];
        FollowerEvent* fe = [[FollowerEvent alloc] init];
        if (append) {
            [_notifications addObject:fe];
        } else {
            [_notifications insertObject:fe atIndex:0];
        }
        fe.time = message.time;
        NSString* followerID = [data valueForKey:@"follower"];
        fe.followerID = followerID;
        UserProfile* follower = [self loadUserFromCache:followerID];

        if (follower) {
            fe.follower = follower;
            [self loadUserAvatar:follower];
            [self.tableView reloadData];
        } else {//user info not found in cache, touch the network and save it to cache for later use
            [[NetworkHandler getHandler] requestFromURL:[self userURL:followerID] method:GET cachePolicy:TTURLRequestCachePolicyDefault success:^(id obj){
                [self.tableView reloadData];
            } failure:^{
                NSLog(@"failed to load users in notifications");
            }];
        }
    }
}

-(UserProfile*)loadUserFromCache:(NSString*)userID{
    NSString* url = [NSString stringWithFormat:@"http://%@/api/v1/simple_user/%@/?format=json", EOHOST, userID];
    NSData* cachedData = [[TTURLCache sharedCache] dataForURL:url];
    NSDictionary* userData = [cachedData objectFromJSONData];
    if (userData) {
        return [UserProfile profileWithData:userData];
    }
    return nil;
}

-(NSString*)userURL:(NSString*)userID{
   return [NSString stringWithFormat:@"http://%@/api/v1/simple_user/%@/?format=json", EOHOST, userID];
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
    }
    
    UILabel* timeLabel = (UILabel* )cell.accessoryView;
    timeLabel.text = [DateUtil userFriendlyStringFromDate:event.time];
    
    if ([event isKindOfClass:[FollowerEvent class]]) {
        FollowerEvent* fe = (FollowerEvent*)event;
        if (fe.follower) {
            cell.textLabel.text = fe.follower.name;
            cell.detailTextLabel.text = @"关注了你";
            NSData* data =  [[TTURLCache sharedCache] dataForURL:[fe.follower smallAvatarFullUrl]];
            UIImage* image = [UIImage imageWithData:data];
            if (image) {
                cell.imageView.image = image;
            }
        } else {
            cell.textLabel.text = @"加在中……";
            cell.detailTextLabel.text = @"";
            cell.imageView.image = [UIImage imageNamed:@"anno"];
        }
    }
    return cell;
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
    EventBase* event = [_notifications objectAtIndex:indexPath.row];
    if ([event isKindOfClass:[FollowerEvent class]]) {
        FollowerEvent* fe = (FollowerEvent*)event;
        UserProfile* user = fe.follower;
        if (user) {
            NewUserDetailsViewController* detailViewController = [[NewUserDetailsViewController alloc] initWithStyle:UITableViewStylePlain];
            detailViewController.user = user;
            [self.navigationController pushViewController:detailViewController animated:YES];
        }
    }

}

@end
