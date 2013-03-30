//
//  CreateOrderView.m
//  EasyOrder
//
//  Created by 浣泽 徐 on 6/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CreateOrderViewController.h"
#import "AppDelegate.h"
#import "NetworkHandler.h"
#import "Const.h"
#import "NSDictionary+ParseHelper.h"
#import "SVProgressHUD.h"
#import "InfoUtil.h"
#import "Authentication.h"
#import "OrderDetailsViewController.h"

#define TABLE_VIEW_WIDTH 260
#define LABEL_HEIGHT 30
#define BUTTON_WIDTH 40
#define AMOUNT_WIDTH 40
#define V_GAP 8
#define H_GAP 5
#define CONFIRM_BUTTON_WIDTH 230
#define PLUG_X (TABLE_VIEW_WIDTH - BUTTON_WIDTH*2 - AMOUNT_WIDTH - H_GAP*3)
#define TAB_BAR_HEIGHT 44

@interface TTTableControlCell (ALL_CONTROL_ALIGN_RIGHT)
+ (BOOL)shouldConsiderControlIntrinsicSize:(UIView*)view;
@end

@implementation TTTableControlCell (ALL_CONTROL_ALIGN_RIGHT)

+ (BOOL)shouldConsiderControlIntrinsicSize:(UIView*)view {
    return [view isKindOfClass:[UISwitch class]] || [view isKindOfClass:[UIStepper class]];
}
@end

@implementation CreateOrderViewController

@synthesize mealInfo = _mealInfo;
@synthesize tabBar = _tabBar;
@synthesize delegate = _delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        self.tableViewStyle = UITableViewStyleGrouped;
        self.autoresizesForKeyboard = YES;
        self.variableHeightRows = YES;
        
        _numberOfPersons = 1;
        
        _priceItem = [TTTableCaptionItem itemWithText:[NSString stringWithFormat:@"%.0f 元/人", _mealInfo.price] caption:@"价格"];
        
        _stepper = [[UIStepper alloc] init];
        [_stepper sizeToFit];
        _stepper.value = 1;
        _stepper.minimumValue = 1;
        _stepper.stepValue = 1;
        [_stepper addTarget:self action:@selector(stepperClicked:) forControlEvents:UIControlEventValueChanged];
        _numberOfPersonsItem = [TTTableControlItem itemWithCaption:@"1人" control:_stepper];
        
        _totalPriceItem = [TTTableCaptionItem itemWithText:[NSString stringWithFormat:@"%.0f 元", _mealInfo.price] caption:@"总价"];
        self.dataSource = [TTListDataSource dataSourceWithObjects:
                           _priceItem,
                           _numberOfPersonsItem,
                           _totalPriceItem,
                           nil];
        self.tableView.delegate = self;
        [self setTitle:@"加入饭局"];
        AppDelegate *delegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
        self.tableView.backgroundColor = [UIColor colorWithPatternImage:delegate.bgImage]; 
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        
    }
    return self;
}



-(void) confirmButtonClicked:(id)sender{
    [_confirmButton setEnabled:NO];
    [_confirmButton removeTarget:self action:@selector(confirmButtonClicked:) forControlEvents:UIControlEventTouchDown];
    NSString *mealID = [NSString stringWithFormat:@"%d", self.mealInfo.mID];
    NSString *num_persons = [NSString stringWithFormat:@"%d", _numberOfPersons];
    NSString *total_price = [NSString stringWithFormat:@"%.0f", _numberOfPersons * self.mealInfo.price];
        NSArray *params = [NSArray arrayWithObjects:
                           [NSDictionary dictionaryWithObjectsAndKeys:mealID, @"value", @"meal_id", @"key", nil], 
                           [NSDictionary dictionaryWithObjectsAndKeys:num_persons, @"value", @"num_persons", @"key", nil],
                           [NSDictionary dictionaryWithObjectsAndKeys:total_price, @"value", @"total_price", @"key", nil],
                           nil];
    [[NetworkHandler getHandler] requestFromURL:[NSString stringWithFormat:@"http://%@/api/v1/user/%d/order/", EOHOST, [Authentication sharedInstance].currentUser.uID]
                                         method:POST
                                     parameters:params
                                    cachePolicy:TTURLRequestCachePolicyNone
                                        success:^(id obj) {
                                            if ([[obj objectForKey:@"status"] isEqualToString:@"OK"]) {
//                                                OrderDetailsViewController *details = [[OrderDetailsViewController alloc] initWithNibName:@"OrderDetailsViewController" bundle:nil];
//                                                details.meal = self.mealInfo;
//                                                [self.navigationController pushViewController:details
//                                                                                     animated:YES];
//                                                [_delegate orderCeatedWithUser:[Authentication sharedInstance].currentUser numberOfPersons:_numberOfPersons];
                                                
                                            } else {
                                                [InfoUtil showError:obj];
                                            }
                                        } failure:^{
                                            [InfoUtil showErrorWithString:@"加入失败，可能是网络问题"];
                                        }]; 
}

-(void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    _stepper.maximumValue = _mealInfo.maxPersons - _mealInfo.actualPersons;
    _priceItem.text =  [NSString stringWithFormat:@"%.0f 元/人", _mealInfo.price] ;
    _totalPriceItem.text = [NSString stringWithFormat:@"%.0f 元", _mealInfo.price * _numberOfPersons];
    
    _tabBar = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - TAB_BAR_HEIGHT, self.view.frame.size.width, TAB_BAR_HEIGHT)];
    _tabBar.backgroundColor = RGBACOLOR(0, 0, 0, 0.5);
    
    _confirmButton = [[UIButton alloc] initWithFrame:CGRectMake((_tabBar.frame.size.width - CONFIRM_BUTTON_WIDTH)/2, 0, CONFIRM_BUTTON_WIDTH, TAB_BAR_HEIGHT)];
    _confirmButton.layer.borderColor = [UIColor grayColor].CGColor;
    _confirmButton.layer.borderWidth = 1;
    _confirmButton.titleLabel.textAlignment  = UITextAlignmentCenter;
    _confirmButton.titleLabel.textColor = [UIColor whiteColor];
    _confirmButton.titleLabel.font = [UIFont boldSystemFontOfSize:25];
    _confirmButton.backgroundColor = RGBCOLOR(0, 0x99, 0);
    [_confirmButton setTitle:@"确定" forState:UIControlStateNormal];
    [_confirmButton addTarget:self action:@selector(confirmButtonClicked:) forControlEvents:UIControlEventTouchDown];
    [_tabBar addSubview:_confirmButton];   
    [self.view addSubview:_tabBar];
}

-(void) stepperClicked:(id)sender{
    _numberOfPersons = _stepper.value;
    _numberOfPersonsItem.caption = [NSString stringWithFormat:@"%d人",_numberOfPersons];
    _totalPriceItem.text = [NSString stringWithFormat:@"%.0f 元", _mealInfo.price * _numberOfPersons];
    [self.tableView reloadData];
}

#pragma mark UITableViewDelegate
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    cell.textLabel.textAlignment = UITextAlignmentLeft;
    cell.detailTextLabel.textAlignment = UITextAlignmentRight;
    cell.textLabel.font = TTSTYLEVAR(tableTitleFont); //same font for all
    cell.textLabel.textColor = TTSTYLEVAR(linkTextColor);
}
                
//- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
//    return 20;
//}

//- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
//    UILabel *header = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 260, 20)];
//    header.backgroundColor = [UIColor blueColor];
//    [header setText:@"订单详情"];
//    header.textAlignment = UITextAlignmentCenter;
//    return header;
//}

#pragma mark UIPickerViewDelegate
- (void)pickerView:(UIPickerView *)pickerView didSelectRow: (NSInteger)row inComponent:(NSInteger)component {
    // Handle the selection
}

// tell the picker how many rows are available for a given component
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {    
    return _mealInfo.maxPersons - _mealInfo.participants.count - 1;//TODO use actualPersons instead
}

// tell the picker how many components it will have
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

// tell the picker the title for a given component
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [NSString stringWithFormat:@"%d 人", row + 1];
}

// tell the picker the width of each row for a given component
- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
    int sectionWidth = 60;    
    return sectionWidth;
}

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    [self.navigationController popViewControllerAnimated:YES];
}
@end
