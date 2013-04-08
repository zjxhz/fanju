//
//  RecentContactsViewController.m
//  EasyOrder
//
//  Created by 徐 浣泽 on 11/4/12.
//
//

#import "RecentContactsViewController.h"
#import "RecentContactsDataSource.h"
#import "RecentContact.h"
#import "AppDelegate.h"
#import "XMPPHandler.h"
#import "XMPPChatViewController2.h"
@interface RecentContactsViewController (){
}

@end

@implementation RecentContactsViewController

- (void) loadView{
    [super loadView];
    self.title = @"对话";
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"编辑" style:UIBarButtonItemStyleBordered target:self action:@selector(editTable:)];
    [self requestMessages];
}

-(void) requestMessages{
    
    RecentContactsDataSource *ds = [[RecentContactsDataSource alloc] init];
    [ds.items addObjectsFromArray:[XMPPHandler sharedInstance].recentContacts];
    self.dataSource = ds;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(messageDidSave:)
                                                 name:EOMessageDidSaveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(messageDidDelete:)
                                                 name:EOMessageDidDeleteNotification
                                               object:nil];
    [[XMPPHandler sharedInstance] updateUnreadCount]; //manually update the unread count so that unread count on the side bar looks same with what is showing here
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown;
}

- (id<UITableViewDelegate>)createDelegate {
    return self;
}

#pragma mark UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 56.0;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    id<TTTableViewDataSource> dataSource = (id<TTTableViewDataSource>)tableView.dataSource;
    id object = [dataSource tableView:tableView objectForRowAtIndexPath:indexPath];
    if ([object isKindOfClass:[RecentContact class]]) {
        RecentContact *item = object;
        XMPPChatViewController2 *chat =[[XMPPChatViewController2 alloc] initWithUserChatTo:item.contact];
        item.unread = 0; //open the chat dialog mark all messages as read
        [[XMPPHandler sharedInstance] markMessagesReadFrom:item.contact];
        [[XMPPHandler sharedInstance] updateUnreadCount];
        [[XMPPHandler sharedInstance] retrieveMessagesWith:item.contact after:[item.time timeIntervalSince1970] retrievingFromList:NO];
        NSError *error = nil;
        [[XMPPHandler sharedInstance].messageManagedObjectContext save:&error];
        [self refresh];
        [self.navigationController pushViewController:chat animated:YES];
    }
}


-(void)messageDidSave:(NSNotification*)notif {
    [self reloadData];
}

-(void)messageDidDelete:(NSNotification*)notif {
    [self reloadData];
}

-(void)reloadData{
    RecentContactsDataSource *ds = self.dataSource;
    [ds.items removeAllObjects];
    [ds.items addObjectsFromArray:[XMPPHandler sharedInstance].recentContacts];
    [self refresh];
}


-(void)editTable:(id)sender{
    if (self.tableView.editing) {
        self.tableView.editing = NO;
        self.navigationItem.rightBarButtonItem.title = @"编辑";
    } else {
        self.tableView.editing = YES;
        self.navigationItem.rightBarButtonItem.title = @"完成";
    }
}
@end
