//
//  ConversationViewController.m
//  Fanju
//
//  Created by Xu Huanze on 5/6/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import "ConversationViewController.h"
#import "User.h"
#import "Conversation.h"
#import "ConversationCell.h"
#import "RestKit.h"
#import "DateUtil.h"
#import "UserService.h"
#import "MessageService.h"
#import "Const.h"
#import "XMPPChatViewController2.h"
#import "XMPPHandler.h"
#import "WidgetFactory.h"
#import "UserDetailsViewController.h"

@interface ConversationViewController (){
    NSMutableArray* _conversations;
    NSManagedObjectContext* _contex;
    NSFetchRequest* _fetchRequest;
}

@end

@implementation ConversationViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        _conversations = [NSMutableArray array];
        RKManagedObjectStore* store = [RKObjectManager sharedManager].managedObjectStore;
        _contex = store.mainQueueManagedObjectContext;
        _fetchRequest = [[NSFetchRequest alloc] init];
        _fetchRequest.entity = [NSEntityDescription entityForName:@"Conversation" inManagedObjectContext:_contex];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg"]];
//    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.navigationItem.rightBarButtonItem = [[WidgetFactory sharedFactory] normalBarButtonItemWithTitle:@"编辑" target:self action:@selector(editTable:)];
    [self requestMessages];
}

-(void) requestMessages{
    [self reloadData];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(messageDidSave:)
                                                 name:MessageDidSaveNotification
                                               object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(messageDidDelete:)
//                                                 name:MessageDidDeleteNotification
//                                               object:nil];
    [[MessageService service] updateUnreadCount];
//    [[XMPPHandler sharedInstance] updateUnreadCount]; //manually update the unread count so that unread count on the side bar looks same with what is showing here
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _conversations.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 52;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Conversation* conversation = _conversations[indexPath.row];
    static NSString *CellIdentifier = @"ConversationCell";
    UITableViewCell *cell = nil;//[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        UIViewController* temp = [[UIViewController alloc] initWithNibName:CellIdentifier bundle:nil];
        cell = (UITableViewCell*)temp.view;
    }
    ConversationCell* converstationCell = (ConversationCell*)cell;
    User* with = conversation.with;
    converstationCell.nameLabel.text = with.name;
    converstationCell.messageLabel.text = conversation.message;
    converstationCell.timeLabel.text = [DateUtil userFriendlyStringFromDate:conversation.time];
    
    CGRect frame = converstationCell.avatarView.frame;
    NSString* avatarURL = [URLService absoluteURL:with.avatar];
    [converstationCell.avatarView setPathToNetworkImage:avatarURL forDisplaySize:frame.size contentMode:UIViewContentModeScaleAspectFill];
    converstationCell.avatarView.layer.cornerRadius = 3;
    converstationCell.avatarView.layer.masksToBounds = YES;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    NSInteger unreadCount = [conversation.unread integerValue];
    if (unreadCount > 0) {
        converstationCell.unreadLabel.text = [NSString stringWithFormat:@"%d", unreadCount];
        if (unreadCount > 99) {
            [converstationCell.unreadLabel sizeToFit];
        } else {
            converstationCell.unreadLabel.frame = CGRectMake(40, 36, 15, 12);
        }
        converstationCell.unreadLabel.hidden = NO;
    } else {
        converstationCell.unreadLabel.hidden = YES;
    }
    return cell;
}


-(void)messageDidSave:(NSNotification*)notif {
    [self reloadData];
}

-(void)messageDidDelete:(NSNotification*)notif {
    [self reloadData];
}

-(void)reloadData{
    [_conversations removeAllObjects];
    for (Conversation* c in [MessageService service].conversations) {
        if (c.messages.count > 0) {
            [_conversations addObject:c];
        }
    }
    [self.tableView reloadData];
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

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (![UserService hasAvatar:[UserService service].loggedInUser]) {
        UIAlertView* av = [[UIAlertView alloc] initWithTitle:@"提示" message:@"要查看和回复消息，请先设置头像" delegate:self cancelButtonTitle:@"以后再说" otherButtonTitles:@"设置", nil];
        [av show];
        return;
    }
    Conversation* conversation = _conversations[indexPath.row];
    XMPPChatViewController2 *chat =[[XMPPChatViewController2 alloc] initWithConversation:conversation];
    conversation.unread = [NSNumber numberWithInteger:0];
    [[MessageService service] markMessagesReadFrom:conversation.with];
    [[MessageService service] updateUnreadCount];
    NSError *error = nil;
    if(![_contex saveToPersistentStore:&error]){
        DDLogError(@"failed to save updated unread count for conversation: %@", conversation);
    }
    
    [self reloadData];
    [self.navigationController pushViewController:chat animated:YES];
}


- (void)tableView: (UITableView *)tableView commitEditingStyle: (UITableViewCellEditingStyle)editingStyle forRowAtIndexPath: (NSIndexPath *)indexPath {
    Conversation *c = _conversations[indexPath.row];
    [_conversations removeObjectAtIndex:indexPath.row];
    [[MessageService service] deleteConversation:c];
    [tableView reloadData];
}

#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 1) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UserDetailsViewController* vc = [[UserDetailsViewController alloc] init];
            vc.user = [UserService service].loggedInUser;
            [self.navigationController pushViewController:vc animated:YES];
        });
    }
}
@end


