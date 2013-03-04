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
    [self requestMessages];
}

-(void) requestMessages{
    
//    RecentContactsDataSource *ds = [[RecentContactsDataSource alloc] init];
//    [ds.items addObjectsFromArray:[XMPPHandler sharedInstance].recentContacts];
//    self.dataSource = ds;
    NSFetchRequest *req = [[NSFetchRequest alloc] init];
    NSManagedObjectContext* context = [XMPPHandler sharedInstance].messageManagedObjectContext;
    req.entity = [NSEntityDescription entityForName:@"EOMessage" inManagedObjectContext:context];
//    req.predicate = [NSPredicate predicateWithFormat:@"type.length == 0"];
    
    NSError* error;
    NSArray* objects = [context executeFetchRequest:req error:&error];
    
    NSMutableString* ids = [[NSMutableString alloc] init];
    NSMutableSet* idSet = [NSMutableSet set];
    
    for (EOMessage* message in objects) {
        NSDictionary* data = [message.payload objectFromJSONString];
        [idSet addObject:[data valueForKey:@"follower"]];
    }
    for (NSString* uid in idSet) {
        [ids appendFormat:@"%@,", uid];
    }
    
    if (ids.length > 0) {
        [ids deleteCharactersInRange:NSMakeRange([ids length]-1, 1)];
    }
    NSString* url = [NSString stringWithFormat:@"http://%@/api/v1/simple_user/?format=json&ids=%@", EOHOST, ids];
    [[NetworkHandler getHandler] requestFromURL:url method:GET cachePolicy:TTURLRequestCachePolicyDefault success:^(id obj) {
        NSArray *users = [obj objectForKeyInObjects];
        for (NSDictionary *dict in users) {
            UserProfile *profile = [UserProfile profileWithData:dict];
            [_notifications addObject:profile];
            TTURLRequest* request = [TTURLRequest requestWithURL:[profile smallAvatarFullUrl] delegate:nil];
            request.response = [[TTURLImageResponse alloc] init];
            [request send];
        }
        [self.tableView reloadData];
    } failure:^{
        NSLog(@"failed to load users in notifications");
    }];

    
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

-(void)notificationDidSave:(NSNotification*)notif{
    EOMessage* message = notif.object;
    NSDictionary* data = [message.payload objectFromJSONString];
    NSString* uid = [data valueForKey:@"follower"];
    BOOL userExist = NO;
    for (UserProfile* user in _notifications) {
        if (user.uID == [uid integerValue]) {
            [_notifications insertObject:user atIndex:0];
            userExist = YES;
            [self.tableView reloadData];
            return;
        }
    }
    if (!userExist) {
        NSString* url = [NSString stringWithFormat:@"http://%@/api/v1/simple_user/%@/?format=json", EOHOST, uid];
        [[NetworkHandler getHandler] requestFromURL:url method:GET cachePolicy:TTURLRequestCachePolicyDefault success:^(id obj) {
            UserProfile *profile = [UserProfile profileWithData:obj];
            [_notifications insertObject:profile atIndex:0];
            TTURLRequest* request = [TTURLRequest requestWithURL:[profile smallAvatarFullUrl] delegate:nil];
            request.response = [[TTURLImageResponse alloc] init];
            [request send];
            [self.tableView reloadData];
        } failure:^{
            NSLog(@"failed to load users in notifications");
        }];

    }
    
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
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.imageView.image = [UIImage imageNamed:@"anno"];
    }
    
    UserProfile* profile = [_notifications objectAtIndex:indexPath.row];
    cell.textLabel.text = profile.name;
    cell.detailTextLabel.text = @"关注了你";
    NSData* data =  [[TTURLCache sharedCache] dataForURL:[profile smallAvatarFullUrl]];
    UIImage* image = [UIImage imageWithData:data];
    if (image) {
        cell.imageView.image = image;
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
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

@end
