//
//  XMPPChatViewController2.m
//  EasyOrder
//
//  Created by 徐 浣泽 on 12/14/12.
//
//

#import "XMPPChatViewController2.h"
#import "ACPlaceholderTextView.h"
#import "Authentication.h"
#import "UIBubbleTableView.h"
#import "XMPPHandler.h"
#import "SVProgressHUD.h"
#import "UIView+CocoaPlant.h"
#import "NSDictionary+ParseHelper.h"
#import "ODRefreshControl.h"
#import "SVProgressHUD.h"
#import "RestKit.h"
#import "UserService.h"
#import "UserMessage.h"
#import "MessageService.h"
#import "Conversation.h"
#import "UserDetailsViewController.h"
#import "AvatarFactory.h"
#import "UserTagsCell.h"
#import "WidgetFactory.h"

#define kChatBarHeight1                      40
#define kChatBarHeight4                      94
#define TEXT_VIEW_X                          7   // 40  (with CameraButton)
#define TEXT_VIEW_Y                          2
#define TEXT_VIEW_WIDTH                      249 // 216 (with CameraButton)
#define TEXT_VIEW_HEIGHT_MIN                 90
#define MessageFontSize                      16
#define FETCH_LIMIT 20
#define UIKeyboardNotificationsObserve() \
NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter]; \
[notificationCenter addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil]; \
[notificationCenter addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil]

#define UIKeyboardNotificationsUnobserve() \
[[NSNotificationCenter defaultCenter] removeObserver:self];

@interface XMPPChatViewController2 (){
    ACPlaceholderTextView *_textView;
    UIButton *_sendButton;
    CGFloat _previousTextViewContentHeight;
    UIImageView *_messageInputBar;
    Conversation* _conversation;
    UIBubbleTableView *_bubbleTable;
    NSMutableArray *_bubbleData;
    CGFloat _keyboardHeight;
    ODRefreshControl* _refreshControl;
    NSFetchRequest *_fetchRequest;
//    NSInteger _fetchOffset;
    NSManagedObjectContext* _context;
    UIView* _guideView;
    NSDate* _oldestMessageDate;
}

@end

@implementation XMPPChatViewController2

-(id)initWithConversation:(Conversation*)conversation{
    if (self = [self init]) {
        _conversation = conversation;
        _bubbleData = [NSMutableArray array];
        RKManagedObjectStore* store = [RKObjectManager sharedManager].managedObjectStore;
        _context = store.mainQueueManagedObjectContext;
    }
    return self;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void) loadView{
    [super loadView];
    self.title = @"聊天";
    self.view.backgroundColor = RGBCOLOR(0xF0, 0xF0, 0xF0);
    _bubbleTable = [[UIBubbleTableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    [self.view addSubview:_bubbleTable];
    _bubbleTable.bubbleDataSource = self;
    _bubbleTable.showAvatars = YES;
    _bubbleTable.avatarDelegate = self;
    [_bubbleTable reloadData];
    _refreshControl = [[ODRefreshControl alloc] initInScrollView:_bubbleTable];
    [_refreshControl addTarget:self action:@selector(loadEarlierMessages:) forControlEvents:UIControlEventValueChanged];
    self.navigationItem.rightBarButtonItem = [[WidgetFactory sharedFactory] normalBarButtonItemWithTitle:@"TA的资料" target:self action:@selector(showUserDetails:)];
}

-(void)showUserDetails:(id)sender{
    UserDetailsViewController *details = [[UserDetailsViewController alloc] init];
    details.user = _conversation.with;
    [self.navigationController pushViewController:details animated:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self requestMessages];
    [self createMessageInputBar];
    UIGestureRecognizer *reg = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped:)];
    reg.delegate = self;
    [self.view addGestureRecognizer:reg];
    [[NSNotificationCenter defaultCenter] postNotificationName:CurrentConversation
                                                        object:_conversation.with
                                                      userInfo:nil];
}


-(void) createMessageInputBar{
    self.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height-kChatBarHeight1);
    // Create messageInputBar to contain _textView, messageInputBarBackgroundImageView, & _sendButton.
    _messageInputBar = [[UIImageView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height-kChatBarHeight1, self.view.frame.size.width, kChatBarHeight1)];
    _messageInputBar.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin);
    _messageInputBar.opaque = YES;
    _messageInputBar.userInteractionEnabled = YES; // makes subviews tappable
    _messageInputBar.image = [[UIImage imageNamed:@"MessageInputBarBackground"] resizableImageWithCapInsets:UIEdgeInsetsMake(19, 3, 19, 3)]; // 8 x 40
    
    // Create _textView to compose messages.
    // TODO: Shrink cursor height by 1 px on top & 1 px on bottom.
    _textView = [[ACPlaceholderTextView alloc] initWithFrame:CGRectMake(TEXT_VIEW_X, TEXT_VIEW_Y, TEXT_VIEW_WIDTH, TEXT_VIEW_HEIGHT_MIN)];
    _textView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _textView.delegate = self;
    _textView.backgroundColor = [UIColor colorWithWhite:245/255.0f alpha:1];
    _textView.scrollIndicatorInsets = UIEdgeInsetsMake(13, 0, 8, 6);
    _textView.scrollsToTop = NO;
    _textView.font = [UIFont systemFontOfSize:MessageFontSize];
    _textView.placeholder = NSLocalizedString(@" Message", nil);
    [_messageInputBar addSubview:_textView];
    _previousTextViewContentHeight = MessageFontSize+20;
    
    // Create messageInputBarBackgroundImageView as subview of messageInputBar.
    UIImageView *messageInputBarBackgroundImageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"MessageInputFieldBackground"] resizableImageWithCapInsets:UIEdgeInsetsMake(20, 12, 18, 18)]]; // 32 x 40
    messageInputBarBackgroundImageView.frame = CGRectMake(TEXT_VIEW_X-2, 0, TEXT_VIEW_WIDTH+2, kChatBarHeight1);
    messageInputBarBackgroundImageView.autoresizingMask = self.view.autoresizingMask;
    [_messageInputBar addSubview:messageInputBarBackgroundImageView];
    
    // Create sendButton.
    UIImage *sendButtonBackgroundImage = [UIImage imageNamed:@"SendButton"];
    _sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _sendButton.frame = CGRectMake(_messageInputBar.frame.size.width - 60, (_messageInputBar.frame.size.height - sendButtonBackgroundImage.size.height) / 2, sendButtonBackgroundImage.size.width, sendButtonBackgroundImage.size.height);
    [_sendButton setBackgroundImage:sendButtonBackgroundImage forState:UIControlStateNormal];
    [_sendButton addTarget:self action:@selector(sendMessage) forControlEvents:UIControlEventTouchUpInside];
    [_messageInputBar addSubview:_sendButton];
    [_sendButton setEnabled:NO];
    _sendButton.titleLabel.alpha = 0.5f;
    
    [self.view addSubview:_messageInputBar];
}


-(void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if (_bubbleData.count == 0 && _guideView.superview == nil/*not added*/) {
        [self addGuideView];
    }
    _bubbleTable.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height-kChatBarHeight1);
    _messageInputBar.frame = CGRectMake(0, self.view.frame.size.height-kChatBarHeight1, self.view.frame.size.width, kChatBarHeight1);
    UIKeyboardNotificationsObserve();
    [self scrollToBottomAnimated:NO];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    if ([_textView isFirstResponder]) {
        [_textView resignFirstResponder];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillAppear:animated];
    UIKeyboardNotificationsUnobserve(); // as soon as possible
    [[NSNotificationCenter defaultCenter] postNotificationName:CurrentConversation
                                                        object:nil
                                                      userInfo:nil];
}

-(void)viewDidUnload{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void) requestMessages{
    _fetchRequest = [[NSFetchRequest alloc] init];
    _fetchRequest.entity = [NSEntityDescription entityForName:@"UserMessage" inManagedObjectContext:_context];
    _fetchRequest.predicate = [NSPredicate predicateWithFormat:@"conversation == %@", _conversation];
    _fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"time" ascending:NO]];
    _fetchRequest.fetchLimit = FETCH_LIMIT;
    NSError* error;
    NSArray* objects = [_context executeFetchRequest:_fetchRequest error:&error];
    if (error) {
        DDLogError(@"failed to fetch user messages for conversation %@ with error: %@", _conversation.objectID, error);
    }
//    _fetchOffset = objects.count;
    [self updateOldestTime:objects];
    [self insertMessageBubbles:objects];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(messageDidSave:)
                                                 name:MessageDidSaveNotification
                                               object:nil];
    
}

-(void)loadEarlierMessages:(id)sender{
    //delayed so it looks like refreshing
    [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(doLoadEarlierMessages) userInfo:nil repeats:NO];
}

-(void)doLoadEarlierMessages{
    //    _fetchRequest.fetchOffset = _fetchOffset;
    //    _fetchRequest.fetchLimit = FETCH_LIMIT;
    
    NSError* error;
    if (_oldestMessageDate) {
        _fetchRequest.predicate = [NSPredicate predicateWithFormat:@"conversation == %@ AND time < %@", _conversation, _oldestMessageDate];
    }

    NSArray* objects = [_context executeFetchRequest:_fetchRequest error:&error];
    if (error) {
        DDLogError(@"failed to load messages earlier than %@", _oldestMessageDate);
    }
    [self updateOldestTime:objects];
    [self insertMessageBubbles:objects];
//    _fetchOffset += objects.count;
    [_refreshControl endRefreshing];
}

-(void)updateOldestTime:(NSArray*)messages{
    if (messages.count > 0) {
        UserMessage* lastMessage = [messages lastObject];
        _oldestMessageDate  = lastMessage.time;
        DDLogInfo(@"set oldest message to %@", _oldestMessageDate);
    } else {
        DDLogInfo(@"message requested but not found");
    }
}

-(void)addGuideView{
    _guideView = [[UIView alloc] initWithFrame:self.view.frame];
    NINetworkImageView* avatarView = [AvatarFactory avatarForUser:_conversation.with withFrame:CGRectMake(98, 57, 121, 121)];
    [_guideView addSubview:avatarView];
    
    BOOL hasTag = _conversation.with.tags.count > 0;
    CGFloat nextY = 200;
    if (hasTag) {
        UILabel* tagLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 200, 320, 20)];
        tagLabel.backgroundColor = [UIColor clearColor];
        NSMutableSet *myTagSet = [[UserService service].loggedInUser.tags mutableCopy];;
        NSMutableSet *otherTagSet = [_conversation.with.tags mutableCopy];
        [myTagSet intersectSet:otherTagSet];
        if (myTagSet.count > 0) {
            tagLabel.text = [NSString stringWithFormat:@"你和%@有%d个共同兴趣：", _conversation.with.name, myTagSet.count];
        } else {
            tagLabel.text = [NSString stringWithFormat:@"%@喜欢：", _conversation.with.name];
        }
        
        tagLabel.font = [UIFont boldSystemFontOfSize:18];
        tagLabel.textColor = RGBCOLOR(0x2B, 0x2B, 0x2B);
        tagLabel.textAlignment = UITextAlignmentCenter;
        [_guideView addSubview:tagLabel];
        
        UserTagsCell* cell = [[UserTagsCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"CELL"];
        cell.width = 220;
        cell.tags = [_conversation.with.tags allObjects];
        cell.frame = CGRectMake(50, 228, cell.width, cell.cellHeight);
        [_guideView addSubview:cell];
        nextY = cell.frame.origin.y + cell.frame.size.height + 12;
    }

    UILabel* startChatLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, nextY, 280, 50)];
    startChatLabel.numberOfLines = 0;
    startChatLabel.lineBreakMode = UILineBreakModeWordWrap;
    startChatLabel.backgroundColor = [UIColor clearColor];
    startChatLabel.text = hasTag ? @"何不从此聊起呢？" : [NSString stringWithFormat:@"%@还没有填写兴趣\n问问TA喜欢什么吧", _conversation.with.name];
    startChatLabel.font = [UIFont boldSystemFontOfSize:15];
    startChatLabel.textColor = RGBCOLOR(0x66, 0x66, 0x66);
    startChatLabel.textAlignment = UITextAlignmentCenter;
    [_guideView addSubview:startChatLabel];
    
    [self.view addSubview:_guideView];
}

-(void)insertMessageBubbles:(NSArray*)messages{
    for (UserMessage *message in messages) {
        [_bubbleData insertObject:[self bubbleFromMessage:message] atIndex:0];
    }
    [_bubbleTable reloadData];
}

-(NSBubbleData*)bubbleFromMessage:(UserMessage*)message{
    NSBubbleType bubbleType = [message.incoming boolValue] ? BubbleTypeSomeoneElse : BubbleTypeMine;
    NSBubbleData *bubble = [NSBubbleData dataWithText:message.message date:message.time type:bubbleType];
    bubble.avatar = _avatarSomeoneElse;
    bubble.avatarURL = [URLService absoluteURL:_conversation.with.avatar];
    return bubble;
}

- (void)sendMessage {
    if (!_textView.text.length) {
        [SVProgressHUD dismissWithError:@"还没输入内容呢"];
        return;
    }
    // Autocomplete text before sending. @hack
    [_textView resignFirstResponder];
    [_textView becomeFirstResponder];
    NSString* message = _textView.text;
    _textView.text = nil;
    [self textViewDidChange:_textView];
    [self sendMessage:message To:_conversation.with];
}

-(void)sendMessage:(NSString*)message To:(User*)to{
    DDLogVerbose(@"sending message: %@", message);
    NSString* messageStr = message;
    NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
    [body setStringValue:messageStr];
    NSXMLElement *messageElement = [NSXMLElement elementWithName:@"message"];
    UserProfile* me = [Authentication sharedInstance].currentUser;
    [messageElement addAttributeWithName:@"from" stringValue:me.jabberID];
    [messageElement addAttributeWithName:@"to" stringValue:[UserService jidForUser:_conversation.with]];
    [messageElement addAttributeWithName:@"type" stringValue:@"chat"];
    [messageElement addChild:body];
    [[XMPPHandler sharedInstance].xmppStream sendElement:messageElement];
}

-(void)layoutUI{
    if (_keyboardHeight == 0){
        _messageInputBar.frame = CGRectMake(0, self.view.frame.size.height - kChatBarHeight1, _messageInputBar.frame.size.width, _messageInputBar.frame.size.height);
        self.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
        return;
    }
    
    CGFloat visibleHeight = self.view.frame.size.height - _keyboardHeight - kChatBarHeight1;
    if (_keyboardHeight + _bubbleTable.contentSize.height + kChatBarHeight1 < self.view.frame.size.height){
        _messageInputBar.frame = CGRectMake(0, visibleHeight, _messageInputBar.frame.size.width, _messageInputBar.frame.size.height);
    } else if (   self.view.frame.size.height < kChatBarHeight1 + _bubbleTable.contentSize.height ){
        _messageInputBar.frame = CGRectMake(0, self.view.frame.size.height - kChatBarHeight1, _messageInputBar.frame.size.width, _messageInputBar.frame.size.height);
        self.view.frame = CGRectMake(0,  -_keyboardHeight, self.view.frame.size.width, self.view.frame.size.height);
    } else  {
        _messageInputBar.frame = CGRectMake(0, _bubbleTable.contentSize.height, _messageInputBar.frame.size.width, _messageInputBar.frame.size.height);
        self.view.frame = CGRectMake(0,  visibleHeight- _bubbleTable.contentSize.height, self.view.frame.size.width, self.view.frame.size.height);
    }
}
#pragma mark - Keyboard Notifications
- (void)keyboardWillShow:(NSNotification *)notification {
    NSTimeInterval animationDuration;
    UIViewAnimationCurve animationCurve;
    CGRect frameEnd;
    NSDictionary *userInfo = [notification userInfo];
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&frameEnd];
    _keyboardHeight = frameEnd.size.height;
    [UIView animateWithDuration:animationDuration delay:0.0 options:(UIViewAnimationOptionsFromCurve(animationCurve) | UIViewAnimationOptionBeginFromCurrentState) animations:^{
        [self animateTextView] ;
    } completion:nil];
    if (_bubbleData.count == 0) {
        [UIView animateWithDuration:animationDuration animations:^{
            CGRect frame = _guideView.frame;
            frame.origin.y = -_keyboardHeight;
            _guideView.frame = frame;
        } completion:^(BOOL finished) {}];
    }
}

- (void)keyboardWillHide:(NSNotification *)notification {
    NSTimeInterval animationDuration;
    UIViewAnimationCurve animationCurve;
    CGRect frameEnd;
    NSDictionary *userInfo = [notification userInfo];
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&frameEnd];
    _keyboardHeight = 0;
    [UIView animateWithDuration:animationDuration delay:0.0 options:(UIViewAnimationOptionsFromCurve(animationCurve) | UIViewAnimationOptionBeginFromCurrentState) animations:^{
        [self animateTextView] ;
    } completion:nil];
    if (_bubbleData.count == 0) {
        [UIView animateWithDuration:animationDuration animations:^{
            CGRect frame = _guideView.frame;
            frame.origin.y = 0;
            _guideView.frame = frame;
        } completion:^(BOOL finished) {}];
    }
}


#pragma mark UITextViewDelegate
-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
    if ([text isEqualToString:@"\n"]) {
        [self sendMessage];
        return NO;
    }
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
    // Change height of _tableView & messageInputBar to match textView's content height.
    CGFloat textViewContentHeight = textView.contentSize.height;
    CGFloat changeInHeight = textViewContentHeight - _previousTextViewContentHeight;
    //    DDLogVerbose(@"textViewContentHeight: %f", textViewContentHeight);
    
    if (textViewContentHeight+changeInHeight > kChatBarHeight4+2) {
        changeInHeight = kChatBarHeight4+2-_previousTextViewContentHeight;
    }
    
    if (changeInHeight) {
        [UIView animateWithDuration:0.2 animations:^{
            _bubbleTable.contentInset = UIEdgeInsetsMake(0, 0, _bubbleTable.contentInset.bottom+changeInHeight, 0);
            [self scrollToBottomAnimated:NO];
            UIView *messageInputBar = _textView.superview;
            messageInputBar.frame = CGRectMake(0, messageInputBar.frame.origin.y-changeInHeight, messageInputBar.frame.size.width, messageInputBar.frame.size.height+changeInHeight);
        } completion:^(BOOL finished) {
            [_textView updateShouldDrawPlaceholder];
        }];
        _previousTextViewContentHeight = MIN(textViewContentHeight, kChatBarHeight4+2);
    }
    
    // Enable/disable sendButton if textView.text has/lacks length.
    if ([textView.text length]) {
        _sendButton.enabled = YES;
        _sendButton.titleLabel.alpha = 1;
    } else {
        _sendButton.enabled = NO;
        _sendButton.titleLabel.alpha = 0.5f; // Sam S. says 0.4f
    }
}


-(void) animateTextView{
    const float movementDuration = 0.3f;
    [UIView beginAnimations:@"anim" context:nil];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:movementDuration];
    [self layoutUI];
    [UIView commitAnimations];
}


- (void)scrollToBottomAnimated:(BOOL)animated {
    NSInteger numberOfSections = [_bubbleTable numberOfSections];
    if (!numberOfSections) {
        return;
    }
    NSInteger numberOfRows = [_bubbleTable numberOfRowsInSection:numberOfSections - 1];
    if (numberOfRows) {
        [_bubbleTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:numberOfRows - 1 inSection:numberOfSections - 1] atScrollPosition:UITableViewScrollPositionBottom animated:animated];
    }
}


-(void)messageDidSave:(NSNotification*)notif {
    UserMessage* messageMO = notif.object;
    if (![messageMO.conversation.with isEqual:_conversation.with]) {
        return; //not for this conversation
    }
    if (_bubbleData.count == 0) {
//        [UIView animateWithDuration:0 animations:^{
            CGRect frame = _guideView.frame;
            frame.origin.y = 0;
            _guideView.frame = frame;
//        } completion:^(BOOL finished) {}];
    }
//    _fetchOffset++;
    [_guideView removeFromSuperview];
    _bubbleTable.typingBubble = NSBubbleTypingTypeNobody;
    NSBubbleData *bubble = [self bubbleFromMessage:messageMO];
    [_bubbleData addObject:bubble];
    [_bubbleTable reloadData];
    [self layoutUI];
    [self scrollToBottomAnimated:YES];
}

#pragma mark - UIBubbleTableViewDataSource implementation
- (NSInteger)rowsForBubbleTable:(UIBubbleTableView *)tableView
{
    return [_bubbleData count];
}

- (NSBubbleData *)bubbleTableView:(UIBubbleTableView *)tableView dataForRow:(NSInteger)row
{
    return [_bubbleData objectAtIndex:row];
}

-(void)viewTapped:(UITapGestureRecognizer*)sender{
    if ([_textView isFirstResponder]) {
        [_textView resignFirstResponder];
    }
}

#pragma mark UIGestureRecognizerDelegate <NSObject>
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    if ([touch.view isKindOfClass:[UIButton class]] || [touch.view isKindOfClass:[UITextField class]]) {
        return NO;
    }
    return YES;
}

#pragma mark UIBubbleTableViewCellAvatarDelegate
-(void)avatarTapped:(UIImageView*)avatar{
//    UserDetailsViewController *details = [[UserDetailsViewController alloc] init];
//    details.user = _conversation.with;
//    [self.navigationController pushViewController:details animated:YES];
}


@end
