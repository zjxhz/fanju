//
//  JoinMealViewController.m
//  Fanju
//
//  Created by Xu Huanze on 4/13/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import "JoinMealViewController.h"
#import "AppDelegate.h"
#import "NumberOfParticipantsCell.h"
#import "PriceCell.h"
#import "TotalPriceCell.h"
#import "MobileNumberCell.h"
#import "DictHelper.h"
#import "NetworkHandler.h"
#import "Authentication.h"
#import "SVProgressHUD.h"
#import "OrderInfo.h"
#import "AlixPay.h"
#import "OrderDetailsViewController.h"
#import "WidgetFactory.h"
#import "NewSidebarViewController.h"

#define UIKeyboardNotificationsObserve() \
NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter]; \
[notificationCenter addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil]; \
[notificationCenter addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil]

#define UIKeyboardNotificationsUnobserve() \
[[NSNotificationCenter defaultCenter] removeObserver:self];

@interface JoinMealViewController (){
    PriceCell* _priceCell;
    NumberOfParticipantsCell* _numberCell;
    TotalPriceCell* _totalPriceCell;
    MobileNumberCell* _mobileCell;
    Order* _order;
    NSString* _mobile;
    UIToolbar* _numberToolbar;
}

@end

@implementation JoinMealViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _numberOfPersons = 1;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    AppDelegate *delegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    self.view.backgroundColor = [UIColor colorWithPatternImage:delegate.bgImage];
    self.navigationItem.titleView  = [[WidgetFactory sharedFactory] titleViewWithTitle:@"参加活动"];
    UITapGestureRecognizer* tap  = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped:)];
    tap.delegate = self;
    [self.view addGestureRecognizer:tap];
    _mobile = [[UserService service].loggedInUser.mobile copy];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(alixPayResult:) name:ALIPAY_PAY_RESULT object:nil];
    UIKeyboardNotificationsObserve();
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ALIPAY_PAY_RESULT object:nil];
    UIKeyboardNotificationsUnobserve();
}


#pragma mark UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 0 && indexPath.row == 1) {
        return 60;
    }
    
    return 45;
}


-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return section == 0 ? 20 : 25;
}

-(UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    if (section == 0) {
        return nil;
    }
    UIView* view = [[UIView alloc] initWithFrame:CGRectMake(0, 10, 320, 30)];
    UILabel* line = [self headerLabel:@"联系方式"];
    line.frame = CGRectMake(10, 0, 300, 15);
    [view addSubview:line];
    return view;
}

-(UILabel*)headerLabel:(NSString*)text{
    UILabel* label = [[UILabel alloc] init];
    label.text = text;
    label.textColor = RGBCOLOR(0, 0, 0);
    label.font = [UIFont systemFontOfSize:14];
    label.backgroundColor = [UIColor clearColor];
    return label;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return section == 0 ? 0 : 30;
}

-(UIView*)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    if (section == 0) {
        return nil;
    }
    UIView* view = [[UIView alloc] initWithFrame:CGRectMake(0, 10, 320, 30)];
    UILabel* line0 = [self footerLabel:@"手机号码是非公开信息"];
    line0.frame = CGRectMake(10, 4, 300, 15);
    UILabel* line1 = [self footerLabel:@"用于活动临时变更的信息通知或用户未按时参加活动时的提醒确认"];
    line1.frame = CGRectMake(10, 19, 300, 15);
    [view addSubview:line0];
    [view addSubview:line1];
    return view;
}

-(UILabel*)footerLabel:(NSString*)text{
    UILabel* label = [[UILabel alloc] init];
    label.text = text;
    label.textColor = RGBCOLOR(180, 180, 180);
    label.font = [UIFont systemFontOfSize:10];
    label.backgroundColor = [UIColor clearColor];
    return label;
}

#pragma mark UITableViewDataSource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return section == 0 ? 3 : 1;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 2;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if ([_mobileCell.mobileTextField isFirstResponder]) {
        [_mobileCell.mobileTextField resignFirstResponder];
    }
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell* cell = nil;
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            _priceCell = [self getOrCreateCell:@"PriceCell"];
            cell = _priceCell;
            _priceCell.priceLabel.text = [NSString stringWithFormat:@"%.2f元/人", [_meal.price floatValue]];
        } else if(indexPath.row == 1) {
            if (!_numberCell) {
                UIViewController* temp = [[UIViewController alloc] initWithNibName:@"NumberOfParticipantsCell" bundle:nil];
                _numberCell = (NumberOfParticipantsCell* )temp.view;
                UIImage* minus = [UIImage imageNamed:@"minus"];
                UIImage* add = [UIImage imageNamed:@"add"];
                
                CGFloat segWidth = minus.size.width + add.size.width;
                AKSegmentedControl *segControll = [[AKSegmentedControl alloc] initWithFrame:CGRectMake(193, 8, segWidth, minus.size.height)];
                segControll.segmentedControlMode = AKSegmentedControlModeButton;
                UIButton* minusButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, minus.size.width, minus.size.height)];
                [minusButton setBackgroundImage:minus forState:UIControlStateNormal];
                [minusButton addTarget:self action:@selector(minus:) forControlEvents:UIControlEventTouchUpInside];
                UIButton* addButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, minus.size.width, minus.size.height)];
                [addButton setBackgroundImage:add forState:UIControlStateNormal];
                [addButton addTarget:self action:@selector(add:) forControlEvents:UIControlEventTouchUpInside];
                [segControll setButtonsArray:@[minusButton, addButton]];
                [_numberCell.contentView addSubview:segControll];
            }            
            cell = _numberCell;
            _numberCell.numberLabel.text = [NSString stringWithFormat:@"%d人", _numberOfPersons];
        } else if (indexPath.row == 2 ){
            _totalPriceCell = [self getOrCreateCell:@"TotalPriceCell"];
            cell = _totalPriceCell;
            _totalPriceCell.totalPriceLabel.text = [NSString stringWithFormat:@"%.2f元", _numberOfPersons * [_meal.price floatValue]];
        }
    } else {
        _mobileCell = [self getOrCreateCell:@"MobileNumberCell"];
        _mobileCell.mobileTextField.returnKeyType = UIReturnKeyDone;
        if (!_numberToolbar) {
            _numberToolbar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, 320, 50)];
            _numberToolbar.barStyle = UIBarStyleBlackTranslucent;
            _numberToolbar.items = @[ [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                                   [[UIBarButtonItem alloc]initWithTitle:@"确定" style:UIBarButtonItemStyleDone target:_mobileCell.mobileTextField action:@selector(resignFirstResponder)]];
            [_numberToolbar sizeToFit];
            _mobileCell.mobileTextField.inputAccessoryView = _numberToolbar;
        }
         

        _mobileCell.mobileTextField.delegate = self;
        _mobileCell.mobileTextField.text = _mobile;
        cell = _mobileCell;
    }
    return cell;
}

-(id)getOrCreateCell:(NSString*)cellIdentifier{
    UITableViewCell* cell = [_tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        UIViewController* temp = [[UIViewController alloc] initWithNibName:cellIdentifier bundle:nil];
        cell = (UITableViewCell*)temp.view;
    }
    return cell;
}
-(void)minus:(id)sender{
    if(_numberOfPersons > 1){
        _numberOfPersons--;
        [_tableView reloadData];
    }
}

-(void)add:(id)sender{
    if (_numberOfPersons < [_meal.maxPersons integerValue] -  [_meal.actualPersons integerValue]) {
        _numberOfPersons++;
        [_tableView reloadData];
    }

}

-(void)viewTapped:(id)sender{
    if ([_mobileCell.mobileTextField isFirstResponder]) {
        [_mobileCell.mobileTextField resignFirstResponder];
    }
}


#pragma mark - Keyboard Notifications
- (void)keyboardWillShow:(NSNotification *)notification {
    NSTimeInterval animationDuration;
    NSDictionary *userInfo = [notification userInfo];
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    [UIView animateWithDuration:animationDuration animations:^{
        CGRect frame =  _tableView.frame;
        frame.origin.y = -120;
        _tableView.frame = frame;
    } completion:nil];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    NSTimeInterval animationDuration;
    NSDictionary *userInfo = [notification userInfo];
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    [UIView animateWithDuration:animationDuration animations:^{
        CGRect frame =  _tableView.frame;
        frame.origin.y = 0;
        _tableView.frame = frame;
    } completion:nil];
}

-(IBAction)joinMeal:(id)sender{
    [_confirmButton setEnabled:NO];
    [self updateMobile];
    NSString *mealID = [NSString stringWithFormat:@"%@", self.meal.mID];
    NSString *numberOfPerson = [NSString stringWithFormat:@"%d", _numberOfPersons];
    NSArray *params = @[[DictHelper dictWithKey:@"meal_id" andValue:mealID],
                        [DictHelper dictWithKey:@"num_persons" andValue:numberOfPerson]];
    [SVProgressHUD showWithStatus:@"正在支付…" maskType:SVProgressHUDMaskTypeBlack];
    [[NetworkHandler getHandler] requestFromURL:[NSString stringWithFormat:@"http://%@/api/v1/user/%d/order/", EOHOST, [Authentication sharedInstance].currentUser.uID]
                                         method:POST
                                     parameters:params
                                    cachePolicy:TTURLRequestCachePolicyNone
                                        success:^(id obj) {
                                            NSDictionary* dic = obj;
                                             //note: as order has attribute "status" too if success status will set to the status of the order
                                            if ([dic[@"status"] isEqual:@"NOK"]) {
                                                [SVProgressHUD showErrorWithStatus:dic[@"info"]];
                                                [_confirmButton setEnabled:YES];
                                            } else {
//                                                NSString* orderID = 
//                                                OrderInfo* order = [OrderInfo orderInfoWithData:dic];
                                                NSString* signedString = [dic objectForKey:@"app_req_str"];
                                                [self pay:signedString];
                                                [_confirmButton setEnabled:NO];
                                            }
                                        } failure:^{
                                            [SVProgressHUD showErrorWithStatus:@"加入失败，请稍后重试"];
                                            [_confirmButton setEnabled:YES];
                                        }];
}


-(void)pay:(NSString*)orderString{
    AlixPay * alixpay = [AlixPay shared];
    int ret = [alixpay pay:orderString applicationScheme:APP_SCHEME];
    
    if (ret == kSPErrorAlipayClientNotInstalled) {
        UIWebView* webView = [[UIWebView alloc] init];
        UIViewController* vc = [[UIViewController alloc] init];
        vc.view = webView;
        NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/meal/%@/", EOHOST, _meal.mID]];
        NSString* params = [NSString stringWithFormat:@"meal_id=%@&num_persons=%d", _meal.mID, _numberOfPersons];
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
        [request setHTTPMethod:@"POST"];
        [request setHTTPBody:[params dataUsingEncoding:NSUTF8StringEncoding]];
        [webView loadRequest:request];
        webView.delegate = self;
        vc.navigationItem.rightBarButtonItem = [[WidgetFactory sharedFactory]normalBarButtonItemWithTitle:@"取消" target:self action:@selector(cancel:)];
        UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:vc];
        [self.navigationController presentModalViewController:nc animated:YES];
        [SVProgressHUD dismiss];
    }
}

-(void)updateMobile{
    User* user = [UserService service].loggedInUser;
    if (_mobile && ![_mobile isEqual:user.mobile]) {
        DDLogInfo(@"updating mobile to %@", _mobile);
        NSMutableDictionary *dict = [@{@"mobile":_mobile} mutableCopy];
        [[NetworkHandler getHandler] sendJSonRequest:[NSString stringWithFormat:@"%@://%@/api/v1/user/%@/", HTTPS, EOHOST, user.uID]
                                              method:PATCH
                                          jsonObject:dict
                                             success:^(id obj) {
                                                 DDLogInfo(@"mobile info updated");
                                                 user.mobile = _mobile;
                                                 NSManagedObjectContext *context = [RKObjectManager sharedManager].managedObjectStore.mainQueueManagedObjectContext;
                                                 NSError* error;
                                                 if(![context saveToPersistentStore:&error]){
                                                     DDLogError(@"failed to save mobile");
                                                 }                                                 
                                             } failure:^{
                                                 DDLogError(@"faile to update mobile to: %@", _mobile);
                                             }];

    }
}

-(void)cancel:(id)sender{
    [self cancelWithError:@"已取消"];
}

-(void)cancelWithError:(NSString*)message{
    [_confirmButton setEnabled:YES];
    [self dismissModalViewControllerAnimated:YES];
    if (message) {
        [SVProgressHUD showErrorWithStatus:message];
    } else {
        [SVProgressHUD dismiss];
    }
}

-(void)alixPayResult:(NSNotification*)notif{
    NSDictionary* result = notif.object;
    if (result && [result[@"status"] isEqual:@"OK"]) {
        NSString* orderID = result[@"order_id"];
        [self fetchAndShowOrder:orderID];
    } else {
        [SVProgressHUD dismiss];
        UIAlertView* a = [[UIAlertView alloc] initWithTitle:@"支付失败" message:result[@"message"] delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
        [a show];
        [_confirmButton setEnabled:YES];
    }
}

-(void)fetchAndShowOrder:(NSString*)orderID{
    RKObjectManager* manager = [RKObjectManager sharedManager];
    NSString* path = [NSString stringWithFormat:@"order/%@/", orderID];
    [manager getObject:nil path:path parameters:nil success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        [SVProgressHUD dismiss];
        _order = mappingResult.firstObject;
        OrderDetailsViewController* detail = [[OrderDetailsViewController alloc] init];
        detail.order = _order;
        detail.navigationItem.hidesBackButton = YES;
        detail.navigationItem.rightBarButtonItem = [[WidgetFactory sharedFactory] normalBarButtonItemWithTitle:@"完成" target:self action:@selector(showAndReloadMealList)];
        [self.navigationController pushViewController:detail animated:YES];
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        UIAlertView* a = [[UIAlertView alloc] initWithTitle:@"支付成功，但是…" message:@"…读取订单状态失败。请稍后去我的活动查看，或联系客服。" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
        [a show];
        [SVProgressHUD dismiss];
        DDLogError(@"failed to load order: %@", error);
    }];
}

-(void)showAndReloadMealList{
    [[NewSidebarViewController sideBar] showMealList:YES];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    if ([touch.view isKindOfClass:[UIButton class]] || [touch.view isKindOfClass:[UITableViewCell class]]) {
        return NO;
    }
    return YES;
}


#pragma mark UIWebviewDelegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{
    NSString* urlStr = request.URL.absoluteString;
    DDLogVerbose(@"start loading %@", urlStr);
    NSString* successURL = [NSString stringWithFormat:@"http://%@/meal/%@/order/", EOHOST, _meal.mID];
    NSString* failedURL = [NSString stringWithFormat:@"http://%@/error/", EOHOST];
    if ([urlStr hasPrefix:successURL]) {
        NSArray* components = [urlStr componentsSeparatedByString:@"/"];
        NSString* orderID = [components objectAtIndex:(components.count - 2)];
        [self dismissModalViewControllerAnimated:YES];
        [self fetchAndShowOrder:orderID];
        return NO;
    } else if([urlStr hasPrefix:failedURL]){
        [self cancelWithError:@"抱歉，付款遇到了问题，请联系客服。"];
        return NO;
    }
    return YES;
}

#pragma mark UITextFieldDelegate
- (void)textFieldDidEndEditing:(UITextField *)textField{
    _mobile = _mobileCell.mobileTextField.text;
}
@end
