//
//  ChatViewController.m
//  EasyOrder
//
//  Created by 徐 浣泽 on 11/6/12.
//
//

#import "ChatViewController.h"
#import "AppDelegate.h"
#import "Const.h"
#import "NetworkHandler.h"
#import "NSDictionary+ParseHelper.h"
#import "UserMessageDataSource.h"
#import "Authentication.h"
#import "UserMessageTableItem.h"
#import "SVProgressHUD.h"
#import "UserMessageCell.h"
#import "ACPlaceholderTextView.h"
#import "UIView+CocoaPlant.h"
#import "DictHelper.h"
#import "DateUtil.h"

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


@interface ChatViewController (){
    ACPlaceholderTextView *_textView;
    UIButton *_sendButton;
    CGFloat _previousTextViewContentHeight;
    UIImageView *_messageInputBar;
    NSTimer* _timer;
    UserMessageTableItem* _lastReceivedMessage;
    BOOL _polling;
}

@end

@implementation ChatViewController
-(id)initWithStyle:(UITableViewStyle)style userChatTo:(UserProfile*)userChatTo{
    if (self = [self initWithStyle:style]) {
        self.chatWithUser = userChatTo;
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    }
    return self;
}

- (void) loadView{
    [super loadView];
    self.title = @"聊天";
    AppDelegate *delegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    self.tableView.backgroundView = [[UIView alloc] initWithFrame:self.tableView.bounds];
    self.tableView.backgroundView.backgroundColor = [UIColor colorWithPatternImage:delegate.bgImage];
    self.variableHeightRows = YES;
    self.tableView.backgroundColor = [UIColor clearColor];
    UIView *emptyFooterToGetRidOfAdditionalSeparators = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 10)];
    emptyFooterToGetRidOfAdditionalSeparators.backgroundColor = [UIColor clearColor];
    [self.tableView setTableFooterView:emptyFooterToGetRidOfAdditionalSeparators];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self requestMessages];
    [self createMessageInputBar];
}

-(void) createMessageInputBar{
    self.tableView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height-kChatBarHeight1);
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
    messageInputBarBackgroundImageView.autoresizingMask = _tableView.autoresizingMask;
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
    [_sendButton setTitle:NSLocalizedString(@"Send", nil) forState:UIControlStateNormal];
    [_sendButton setTitleShadowColor:[UIColor colorWithRed:0.325f green:0.463f blue:0.675f alpha:1] forState:UIControlStateNormal];
    [_sendButton addTarget:self action:@selector(sendMessage) forControlEvents:UIControlEventTouchUpInside];
    [_messageInputBar addSubview:_sendButton];
    [_sendButton setEnabled:NO];
    
    [self.view addSubview:_messageInputBar];
}

-(void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.tableView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height-kChatBarHeight1);
    _messageInputBar.frame = CGRectMake(0, self.view.frame.size.height-kChatBarHeight1, self.view.frame.size.width, kChatBarHeight1);
    UIKeyboardNotificationsObserve();
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillAppear:animated];
    UIKeyboardNotificationsUnobserve(); // as soon as possible
    [_timer invalidate];
}

-(void) requestMessages{
    NSString *requestStr = [NSString stringWithFormat:@"http://%@/api/v1/user/%d/chat_history/?format=json&user_id=%d&limit=0", EOHOST, [Authentication sharedInstance].currentUser.uID, self.chatWithUser.uID];
    [[NetworkHandler getHandler] requestFromURL:requestStr
                                         method:GET
                                    cachePolicy:TTURLRequestCachePolicyNone
                                        success:^(id obj) {
                                            UserMessageDataSource *ds = [[UserMessageDataSource alloc] init];
                                            NSArray *messages = [obj objectForKeyInObjects];
                                            if (messages && [messages count] > 0) {
                                                for (NSDictionary *message in messages) {
                                                    UserMessageTableItem *item = [[UserMessageTableItem alloc] initWithData:message];
                                                    [ds.items addObject:item];

                                                    if (!_lastReceivedMessage || ([item.fromUser isEqual:self.chatWithUser] && [item.time timeIntervalSinceDate:_lastReceivedMessage.time] > 0)) {
                                                        _lastReceivedMessage = item;
                                                    }
                                                }
                                                _timer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(pullLatestMessage) userInfo:nil repeats:YES];
                                            } else {
                                                [ds.items addObject:[TTTableSubtitleItem itemWithText:@"暂时还没有消息" subtitle:@"寻找志同道合的朋友，向他/她发消息吧"]];
                                            }
                                            self.dataSource = ds;
                                        } failure:^{
                                            NSLog(@"failed to fetch messages");
                                            [SVProgressHUD dismissWithError:@"读取消息失败"];
                                        }];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (id<UITableViewDelegate>)createDelegate {
    return self;
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

    NSArray *params = @[[DictHelper dictWithKey:@"type" andValue:@"0"], [DictHelper dictWithKey:@"message"  andValue:message]];
    [[NetworkHandler getHandler] requestFromURL:[NSString stringWithFormat:@"%@://%@/api/v1/user/%d/messages/", HTTPS, EOHOST, self.chatWithUser.uID]
                                         method:POST
                                     parameters:params
                                    cachePolicy:TTURLRequestCachePolicyNone
                                        success:^(id obj) {
                                            if ([[obj objectForKey:@"status"] isEqualToString:@"OK"]) {
                                                [SVProgressHUD dismissWithSuccess:@"发送成功"];
                                                UserMessageDataSource *ds = (UserMessageDataSource *)self.dataSource;
                                                UserMessageTableItem* messageItem = [UserMessageTableItem itemFromUser:[Authentication sharedInstance].currentUser toUser:self.chatWithUser withMessage:message at:[NSDate date]];
                                                [ds.items addObject:messageItem];
                                                [self.tableView reloadData];
                                                [self scrollToBottomAnimated:NO];
                                                [self.delegate newMessageAppear:messageItem];
                                            } else {
                                                [SVProgressHUD dismissWithError:@"发送失败"];
                                            }
                                        } failure:^{
                                            [SVProgressHUD dismissWithError:@"发送失败"];
                                        }];
    
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
    
    [UIView animateWithDuration:animationDuration delay:0.0 options:(UIViewAnimationOptionsFromCurve(animationCurve) | UIViewAnimationOptionBeginFromCurrentState) animations:^{
        CGFloat viewHeight = [self.view convertRect:frameEnd fromView:nil].origin.y;
        [self animateTextView:_textView up:YES movementDistance:self.view.frame.size.height - viewHeight] ;
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
    
    [UIView animateWithDuration:animationDuration delay:0.0 options:(UIViewAnimationOptionsFromCurve(animationCurve) | UIViewAnimationOptionBeginFromCurrentState) animations:^{
        [self animateTextView:_textView up:NO movementDistance:frameEnd.size.height] ;
    } completion:nil];
}

#pragma mark UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    UserMessageDataSource *ds = (UserMessageDataSource*)self.dataSource;
    if (ds.items.count > 0) {
        return [UserMessageCell tableView:self.tableView rowHeightForObject:[ds.items objectAtIndex:indexPath.row]];
    } else {
        return 20;
    }
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    [_textView resignFirstResponder];
}


#pragma mark UITextViewDelegate

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
            self.tableView.contentInset = self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, _tableView.contentInset.bottom+changeInHeight, 0);
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

//- (void)textViewDidBeginEditing:(UITextView *)textView{
//    [self animateTextView:textView up:YES];
//}
//- (void)textViewDidEndEditing:(UITextView *)textView{
//    [self animateTextView:textView up:NO];
//}
//
-(void) animateTextView:(UITextView*)textView up:(BOOL)up movementDistance:(CGFloat)movementDistance{
    const float movementDuration = 0.3f;
    
    int movement = up ? -movementDistance : movementDistance;
    [UIView beginAnimations:@"anim" context:nil];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:movementDuration];
    self.view.frame = CGRectOffset(self.view.frame, 0, movement);
    [UIView commitAnimations];
}

- (void)scrollToBottomAnimated:(BOOL)animated {
    NSInteger numberOfRows = [_tableView numberOfRowsInSection:0];
    if (numberOfRows) {
        [_tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:numberOfRows-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:animated];
    }
}


#pragma mark Timer
-(void)pullLatestMessage{
    if (_polling) {
        return;
    }
    _polling = YES;
    NSString *requestStr = [NSString stringWithFormat:@"http://%@/api/v1/user/%d/new_messages/?format=json&last_message_id=%d&limit=0", EOHOST, [Authentication sharedInstance].currentUser.uID, _lastReceivedMessage.mID];
    [[NetworkHandler getHandler] requestFromURL:requestStr
                                         method:GET
                                    cachePolicy:TTURLRequestCachePolicyNone
                                        success:^(id obj) {
                                            NSArray *messages = [obj objectForKeyInObjects];
                                            if (messages && [messages count] > 0) {
                                                UserMessageDataSource *ds = self.dataSource;
                                                for (NSDictionary *message in messages) {
                                                    UserMessageTableItem *item = [[UserMessageTableItem alloc] initWithData:message];
                                                    [ds.items addObject:item];
                                                    if (!_lastReceivedMessage ||  ([item.fromUser isEqual:self.chatWithUser] && [item.time timeIntervalSinceDate:_lastReceivedMessage.time] > 0)) {
                                                        _lastReceivedMessage = item;
                                                    }
                                                    [self.delegate newMessageAppear:item];
                                                }
                                                [self.tableView reloadData];
                                                [self scrollToBottomAnimated:NO];
                                                NSLog(@"pulled with %d new messages.", [messages count]);
                                            } else {
                                                NSLog(@"pulled without new messages.");
                                            }
                                            _polling = NO;
                                        } failure:^{
                                            NSLog(@"failed to fetch new messages");
                                            _polling = NO;
                                        }];

}
@end
