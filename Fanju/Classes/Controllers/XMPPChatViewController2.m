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
#import "NewUserDetailsViewController.h"
#import "NSDictionary+ParseHelper.h"

#define kChatBarHeight1                      40
#define kChatBarHeight4                      94
#define TEXT_VIEW_X                          7   // 40  (with CameraButton)
#define TEXT_VIEW_Y                          2
#define TEXT_VIEW_WIDTH                      249 // 216 (with CameraButton)
#define TEXT_VIEW_HEIGHT_MIN                 90
#define MessageFontSize                      16

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
    NSString* _contactJIDStr;
    UIBubbleTableView *_bubbleTable;
    NSMutableArray *_bubbleData;
    CGFloat _keyboardHeight;
    UserProfile* _profile;
}

@end

@implementation XMPPChatViewController2

-(id)initWithUserChatTo:(NSString*)contactJIDStr{
    if (self = [self init]) {
        _contactJIDStr = contactJIDStr;
        _bubbleData = [NSMutableArray array];
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
    self.view.backgroundColor = [UIColor whiteColor];
    _bubbleTable = [[UIBubbleTableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    
    [self.view addSubview:_bubbleTable];
    _bubbleTable.bubbleDataSource = self;
    _bubbleTable.showAvatars = YES;
    _bubbleTable.avatarDelegate = self;
    [_bubbleTable reloadData];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    [self loadUserProfile];
    [self requestMessages];
    [self createMessageInputBar];
    UIGestureRecognizer *reg = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped:)];
    reg.delegate = self;
    [self.view addGestureRecognizer:reg];
    [[NSNotificationCenter defaultCenter] postNotificationName:EOCurrentContact
                                                        object:_contactJIDStr
                                                      userInfo:nil];
}

-(void)loadUserProfile{
    NSString* url = [NSString stringWithFormat:@"http://%@/api/v1/user/?format=json&user__username=%@", EOHOST, [self username]];
    [[NetworkHandler getHandler] requestFromURL:url
                                         method:GET
                                    cachePolicy:TTURLRequestCachePolicyNone
                                        success:^(id obj) {
                                            NSArray *users = [obj objectForKeyInObjects];
                                            if (users.count == 1) {
                                                _profile = [UserProfile profileWithData:[users objectAtIndex:0]];
                                            } else {
                                                NSLog(@"获取数据失败");
                                            }
                                        } failure:^{
                                            NSLog(@"获取数据失败");
                                        }];
}

-(NSString*)username{
    return [[_contactJIDStr componentsSeparatedByString:@"@"] objectAtIndex:0];
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
    _sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _sendButton.frame = CGRectMake(_messageInputBar.frame.size.width-65, 8, 59, 26);
    _sendButton.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin /* multiline input */ | UIViewAutoresizingFlexibleLeftMargin /* landscape */);
    UIEdgeInsets sendButtonEdgeInsets = UIEdgeInsetsMake(0, 13, 0, 13); // 27 x 27
    UIImage *sendButtonBackgroundImage = [[UIImage imageNamed:@"SendButton"] resizableImageWithCapInsets:sendButtonEdgeInsets];
    [_sendButton setBackgroundImage:sendButtonBackgroundImage forState:UIControlStateNormal];
    [_sendButton setBackgroundImage:sendButtonBackgroundImage forState:UIControlStateDisabled];
    [_sendButton setBackgroundImage:[[UIImage imageNamed:@"SendButtonHighlighted"] resizableImageWithCapInsets:sendButtonEdgeInsets] forState:UIControlStateHighlighted];
    _sendButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    _sendButton.titleLabel.shadowOffset = CGSizeMake(0.0, -1.0);
    [_sendButton setTitle:NSLocalizedString(@"发送", nil) forState:UIControlStateNormal];
    [_sendButton setTitleShadowColor:[UIColor colorWithRed:0.325f green:0.463f blue:0.675f alpha:1] forState:UIControlStateNormal];
    [_sendButton addTarget:self action:@selector(sendMessage) forControlEvents:UIControlEventTouchUpInside];
    [_messageInputBar addSubview:_sendButton];
    [_sendButton setEnabled:NO];
    _sendButton.titleLabel.alpha = 0.5f;
    
    [self.view addSubview:_messageInputBar];
}


-(void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    _bubbleTable.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height-kChatBarHeight1);
    _messageInputBar.frame = CGRectMake(0, self.view.frame.size.height-kChatBarHeight1, self.view.frame.size.width, kChatBarHeight1);
    UIKeyboardNotificationsObserve();
    [self scrollToBottomAnimated:NO];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillAppear:animated];
    UIKeyboardNotificationsUnobserve(); // as soon as possible
    [[NSNotificationCenter defaultCenter] postNotificationName:EOCurrentContact
                                                        object:nil
                                                      userInfo:nil];
}

-(void)viewDidUnload{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void) requestMessages{
    NSManagedObjectContext* context = [XMPPHandler sharedInstance].messageManagedObjectContext;
    NSFetchRequest *req = [[NSFetchRequest alloc] init];
    req.entity = [NSEntityDescription entityForName:@"EOMessage" inManagedObjectContext:context];
    
    UserProfile* me = [Authentication sharedInstance].currentUser;
    req.predicate = [NSPredicate predicateWithFormat:@"(type == 'chat') AND \
                     ( (receiver BEGINSWITH %@ AND sender BEGINSWITH %@) \
                        OR (receiver BEGINSWITH %@ AND sender BEGINSWITH %@) )", _contactJIDStr, me.jabberID, me.jabberID, _contactJIDStr];
    NSError* error;
    NSArray* objects = [context executeFetchRequest:req error:&error];
    for (EOMessage *message in objects) {
        [_bubbleData addObject:[self bubbleFromMessage:message]];
    }
    [_bubbleTable reloadData];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(messageDidSave:)
                                                 name:EOMessageDidSaveNotification
                                               object:nil];
}

-(NSBubbleData*)bubbleFromMessage:(EOMessage*)message{
    NSBubbleType bubbleType = [message.sender isEqualToString:_contactJIDStr] ? BubbleTypeSomeoneElse : BubbleTypeMine;   
    NSBubbleData *bubble = [NSBubbleData dataWithText:message.message date:message.time type:bubbleType];
    XMPPJID* contactJID = [XMPPJID jidWithString:message.sender];
    XMPPHandler* xmppHandler =[XMPPHandler sharedInstance];
    XMPPUserCoreDataStorageObject *user = nil;
    if (bubbleType  == BubbleTypeMine) {
         user = [xmppHandler.xmppRosterStorage myUserForXMPPStream:xmppHandler.xmppStream managedObjectContext:xmppHandler.rosterManagedObjectContext];
    } else {
         user = [xmppHandler.xmppRosterStorage userForJID:contactJID
                                               xmppStream:xmppHandler.xmppStream
                                     managedObjectContext:xmppHandler.rosterManagedObjectContext];
    }
    if (user.photo) {
        bubble.avatar = user.photo;
    } else {
        NSData *photoData = [xmppHandler.xmppvCardAvatarModule photoDataForJID:user.jid];
        if (photoData){
            bubble.avatar =  [UIImage imageWithData:photoData];
        } else {
            [xmppHandler.xmppvCardTempModule fetchvCardTempForJID:contactJID useCache:NO];
        }
    }
    //TODO maybe we could cache the user somewhere, so no need to query all the time
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
    [[XMPPHandler sharedInstance] saveMessage:[Authentication sharedInstance].currentUser.jabberID receiver:_contactJIDStr message:message time:[NSDate date] hasRead:NO];
    //message will be sent after it's saved, check messageDidSave:
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
    //    NSLog(@"textViewContentHeight: %f", textViewContentHeight);
    
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
    EOMessage* messageMO = notif.object;
    UserProfile* me = [Authentication sharedInstance].currentUser;
    if (![messageMO.sender isEqualToString:me.jabberID] && ![messageMO.sender isEqualToString:_contactJIDStr]) {
        return; //not for this conversation
    }

    if ([messageMO.sender isEqualToString:me.jabberID]) {
        [[XMPPHandler sharedInstance] sendMessage:messageMO];
    }
    _bubbleTable.typingBubble = NSBubbleTypingTypeNobody;
    NSBubbleData *bubble = [self bubbleFromMessage:messageMO];
    [_bubbleData addObject:bubble];
    [_bubbleTable reloadData];
    [self layoutUI];
    [self scrollToBottomAnimated:NO];

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
    NewUserDetailsViewController *newDeail = [[NewUserDetailsViewController alloc] initWithStyle:UITableViewStylePlain];
    if (_profile) {
        newDeail.user = _profile;
    } else {
        [newDeail setUsername:[self username]];
    }

    [self.navigationController pushViewController:newDeail animated:YES];
}
@end
