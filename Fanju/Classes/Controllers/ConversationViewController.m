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
#import "SimpleUserEventCell.h"
#import "RestKit.h"
#import "DateUtil.h"
#import "UserService.h"
#import "MessageService.h"
#import "Const.h"
#import "XMPPChatViewController2.h"
#import "XMPPHandler.h"
#import "WidgetFactory.h"

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
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
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
    return 55;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Conversation* conversation = _conversations[indexPath.row];
    static NSString *CellIdentifier = @"SimpleUserEventCell";
    UITableViewCell *cell = nil;//[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
//    if (!cell) {
        UIViewController* temp = [[UIViewController alloc] initWithNibName:CellIdentifier bundle:nil];
        cell = (UITableViewCell*)temp.view;
//    }
    SimpleUserEventCell* eventCell = (SimpleUserEventCell*)cell;
    User* with = conversation.with;
    eventCell.name.text = with.name;
    eventCell.event.text = conversation.message;
    eventCell.time.text = [DateUtil userFriendlyStringFromDate:conversation.time];
    CGRect frame = eventCell.avatar.frame;
    NSString* avatarURL = [NSString stringWithFormat:@"http://%@%@", EOHOST, with.avatar];
    [eventCell.avatar setPathToNetworkImage:avatarURL forDisplaySize:frame.size contentMode:UIViewContentModeScaleAspectFill];
    eventCell.avatar.layer.cornerRadius = 5;
    eventCell.avatar.layer.masksToBounds = YES;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    UIImage* xiaoxi = [UIImage imageNamed:@"xiaoxi"];
    if ([conversation.unread integerValue] > 0) {
        UIButton* unreadButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [unreadButton setBackgroundImage:xiaoxi forState:UIControlStateNormal];
        unreadButton.frame = CGRectMake(250, 8, xiaoxi.size.width, xiaoxi.size.height);
        [unreadButton setTitle:[NSString stringWithFormat:@"%d", [conversation.unread integerValue] ] forState:UIControlStateNormal];
        unreadButton.titleLabel.textColor = [UIColor whiteColor];
        unreadButton.titleLabel.font = [UIFont systemFontOfSize:12];
        unreadButton.layer.shadowColor = [UIColor blackColor].CGColor;
        unreadButton.layer.shadowOpacity = 0.5;
        unreadButton.layer.shadowOffset = CGSizeMake(0, 1);
        unreadButton.userInteractionEnabled = NO;
        [cell.contentView addSubview:unreadButton];
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
    SimpleUserEventCell* eventCell = (SimpleUserEventCell*)[self tableView:self.tableView cellForRowAtIndexPath:indexPath];
    chat.avatarSomeoneElse = eventCell.avatar.image;
    [self.navigationController pushViewController:chat animated:YES];
}


- (void)tableView: (UITableView *)tableView commitEditingStyle: (UITableViewCellEditingStyle)editingStyle forRowAtIndexPath: (NSIndexPath *)indexPath {
    Conversation *c = _conversations[indexPath.row];
    [_conversations removeObjectAtIndex:indexPath.row];
    [[MessageService service] deleteConversation:c];
    [tableView reloadData];
}
@end
