//
//  SendCommentViewController.m
//  Fanju
//
//  Created by Xu Huanze on 7/26/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import "SendCommentViewController.h"
#import "WidgetFactory.h"
#import "NetworkHandler.h"
#import "DictHelper.h"
#import "InfoUtil.h"
#import "UserService.h"
#import "User.h"
#import "SVProgressHUD.h"

@interface SendCommentViewController (){
    UITextView* _textView;
    NSManagedObjectContext* _mainQueueContext;
}

@end

@implementation SendCommentViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        RKManagedObjectStore* store = [RKObjectManager sharedManager].managedObjectStore;
        _mainQueueContext = store.mainQueueManagedObjectContext;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	_textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, 320, 220)];
    _textView.font = [UIFont systemFontOfSize:15];
    _textView.contentInset = UIEdgeInsetsMake(3, 3, 3, 3);
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg"]];
    [self.view addSubview:_textView];
    self.navigationItem.titleView = [[WidgetFactory sharedFactory] titleViewWithTitle:@"评论"];
    [_textView becomeFirstResponder];
    self.navigationItem.rightBarButtonItem = [[WidgetFactory sharedFactory] normalBarButtonItemWithTitle:@"发送" target:self action:@selector(comment:)];
    self.navigationItem.leftBarButtonItem = [[WidgetFactory sharedFactory] normalBarButtonItemWithTitle:@"取消" target:self action:@selector(dismissModalViewControllerAnimated:)];
}

-(void)comment:(id)sender{
    if (_textView.text.length == 0) {
        [InfoUtil showAlert:@"是不是还没有输入内容？"];
        return;
    }
    [SVProgressHUD showWithStatus:@"发送中" maskType:SVProgressHUDMaskTypeBlack];
    NSString* url = [NSString stringWithFormat:@"http://%@/api/v1/meal/%@/comments/", [HostService service].host, _meal.mID];
    NSMutableArray* params = [@[[DictHelper dictWithKey:@"comment" andValue:_textView.text]] mutableCopy];
    if (_parentComment) {
        [params addObject:[DictHelper dictWithKey:@"parent_id" andValue:[_parentComment.cID stringValue]]];
    }

    [[NetworkHandler getHandler] requestFromURL:url method:POST parameters:params cachePolicy:TTURLRequestCachePolicyNone success:^(id obj) {
        NSDictionary* result = obj;
        MealComment* comment = [NSEntityDescription insertNewObjectForEntityForName:@"MealComment" inManagedObjectContext:_mainQueueContext];
        comment.cID = result[@"id"];
        comment.status = [NSNumber numberWithInt:0];
        comment.timestamp = [NSDate date];
        comment.comment = _textView.text;
        comment.user = [UserService service].loggedInUser;
        comment.parent = _parentComment;
        comment.meal = _meal;
        NSError* error = nil;
        if (![_mainQueueContext saveToPersistentStore:&error]){
            DDLogError(@"failed to save comment: %@", error);
        }
        [_sendCommentDelegate didSendComment:comment];
        [SVProgressHUD dismiss];
        [self dismissModalViewControllerAnimated:YES];
    } failure:^{
        [SVProgressHUD dismiss];
        [self dismissModalViewControllerAnimated:YES];
        [InfoUtil showAlert:@"糟糕：评论失败，晚点再试试？"];
        [_sendCommentDelegate didFailSendComment];
        DDLogError(@"failed to comment on %@", url);

    }];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    NSString* title = @"发表评论";
    if (_parentComment) {
        title = [NSString stringWithFormat:@"回复 %@", _parentComment.user.name];
    }
    self.navigationItem.titleView = [[WidgetFactory sharedFactory] titleViewWithTitle:title];
}
@end
