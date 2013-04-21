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
    NSInteger _numberOfPersons;
    PriceCell* _priceCell;
    NumberOfParticipantsCell* _numberCell;
    TotalPriceCell* _totalPriceCell;
    MobileNumberCell* _mobileCell;
    OrderInfo* _order;
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
    UITapGestureRecognizer* tap  = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped:)];
    tap.delegate = self;
    [self.view addGestureRecognizer:tap];

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



//-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
//    if (section == 1) {
//        return @"联系方式";
//    }
//    return nil;
//}


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
    UILabel* line1 = [self footerLabel:@"用于饭局临时变更的信息通知或用户未按时参加饭局时的提醒确认"];
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
            _priceCell.priceLabel.text = [NSString stringWithFormat:@"%.2f元/人", _mealInfo.price];
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
            _totalPriceCell.totalPriceLabel.text = [NSString stringWithFormat:@"%.2f元", _numberOfPersons * _mealInfo.price];
        }
    } else {
        _mobileCell = [self getOrCreateCell:@"MobileNumberCell"];
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
    if (_numberOfPersons < _mealInfo.maxPersons - _mealInfo.actualPersons) {
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
        frame.origin.y = -90;
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
    [_confirmButton removeTarget:self action:@selector(confirmButtonClicked:) forControlEvents:UIControlEventTouchDown];
    NSString *mealID = [NSString stringWithFormat:@"%d", self.mealInfo.mID];
    NSString *numberOfPerson = [NSString stringWithFormat:@"%d", _numberOfPersons];
    NSArray *params = @[[DictHelper dictWithKey:@"meal_id" andValue:mealID],
                        [DictHelper dictWithKey:@"num_persons" andValue:numberOfPerson]];
    [SVProgressHUD showWithStatus:@"正在支付……" maskType:SVProgressHUDMaskTypeBlack];
    [[NetworkHandler getHandler] requestFromURL:[NSString stringWithFormat:@"http://%@/api/v1/user/%d/order/", EOHOST, [Authentication sharedInstance].currentUser.uID]
                                         method:POST
                                     parameters:params
                                    cachePolicy:TTURLRequestCachePolicyNone
                                        success:^(id obj) {
                                            NSDictionary* dic = obj;
                                            OrderInfo* order = [OrderInfo orderInfoWithData:dic];
                                            NSString* signedString = [dic objectForKey:@"app_req_str"];
                                            [self payFor:order withSignedString:signedString];
                                            [_confirmButton setEnabled:YES];
                                        } failure:^{
                                            [SVProgressHUD dismissWithError:@"加入饭局失败"];
                                            [_confirmButton setEnabled:YES];
                                        }];
}


-(void)payFor:(OrderInfo*)orderInfo withSignedString:(NSString*)orderString{
    _order = orderInfo;
    AlixPay * alixpay = [AlixPay shared];
    int ret = [alixpay pay:orderString applicationScheme:APP_SCHEME];
    
    if (ret == kSPErrorAlipayClientNotInstalled) {
        UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"提示"
                                                             message:@"您还没有安装支付宝快捷支付，请先安装。"
                                                            delegate:self
                                                   cancelButtonTitle:@"确定"
                                                   otherButtonTitles:nil];
        [alertView setTag:123];
        [alertView show];
    }
}


-(void)alixPayResult:(NSNotification*)notif{
    NSDictionary* result = notif.object;
    if (result && [result[@"status"] isEqual:@"OK"]) {
        [SVProgressHUD dismiss];
        OrderDetailsViewController* detail = [[OrderDetailsViewController alloc] init];
        _order.code = result[@"code"];
        detail.order = _order;
        detail.navigationItem.hidesBackButton = YES;
        detail.navigationItem.rightBarButtonItem = [[WidgetFactory sharedFactory] normalBarButtonItemWithTitle:@"完成" target:[NewSidebarViewController sideBar] action:@selector(showMealList)];
        [self.navigationController pushViewController:detail animated:YES];
    } else {
        [SVProgressHUD dismissWithError:result[@"message"]];
    }
}


- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    if ([touch.view isKindOfClass:[UIButton class]] || [touch.view isKindOfClass:[UITableViewCell class]]) {
        return NO;
    }
    return YES;
}


@end
