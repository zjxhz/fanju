//
//  OrderListViewController.m
//  EasyOrder
//
//  Created by igneus on 12/29/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "OrderListView.h"
#import <QuartzCore/QuartzCore.h>
#import <Three20/Three20.h>
#import "OrderManager.h"
#import "OrderItem.h"
#import "SBJson.h"
#import "SVProgressHUD.h"
#import "Const.h"

@interface OrderListView () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView *table;
@property (nonatomic, strong) TTButton *confirm;
@property (nonatomic, strong) TTButton *cancel;
@property (nonatomic, strong) UITextField *number;
@property (nonatomic, strong) UIButton *doneButton;
- (void)dismissOrderList;
- (void)placeOrder;
@end

@implementation OrderListView
@synthesize table = _table;
@synthesize confirm = _confirm, cancel = _cancel, number = _number, doneButton = _doneButton;

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        
        [self.layer setMasksToBounds:YES];
        [self.layer setCornerRadius:8.0f];
        
        [self setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"orderlistbg.jpg"]]];
        self.table = [[UITableView alloc] initWithFrame:CGRectMake(0, 44, self.frame.size.width, self.frame.size.height - 44)
                                                  style:UITableViewStylePlain];
        [self.table setBackgroundColor:[UIColor clearColor]];
        self.table.delegate = self;
        self.table.dataSource = self;
        [self addSubview:self.table];
        
        CGFloat layoutX = self.frame.size.width - 300;
        CGFloat layoutY = 3;
        
        UILabel *lb = [[UILabel alloc] initWithFrame:CGRectMake(layoutX, layoutY, 40, 30)];
        [lb setBackgroundColor:[UIColor clearColor]];
        [lb setText:NSLocalizedString(@"NumberOfPPL", nil)];
        [self addSubview:lb];
        
        layoutX += lb.frame.size.width + 10;
        
        self.number = [[UITextField alloc] initWithFrame:CGRectMake(layoutX, layoutY, 20, 30)];
        [self.number setText:@"2"];
        [self.number setKeyboardType:UIKeyboardTypeNumberPad];
        [self addSubview:self.number];
        
        layoutX += self.number.frame.size.width + 20;
        
        self.confirm = [TTButton buttonWithStyle:@"embossedButton:" title:NSLocalizedString(@"FinishOrder", nil)];
        [self.confirm setFrame:CGRectMake(layoutX, layoutY, 80, 30)];
        [self.confirm addTarget:self action:@selector(placeOrder) forControlEvents:UIControlEventTouchDown];
        [self addSubview:self.confirm];
        
        layoutX += self.confirm.frame.size.width + 10;
        
        self.cancel = [TTButton buttonWithStyle:@"embossedButton:" title:NSLocalizedString(@"Back", nil)];
        [self.cancel setFrame:CGRectMake(layoutX, layoutY, 80, 30)];
        [self.cancel addTarget:self action:@selector(dismissOrderList) forControlEvents:UIControlEventTouchDown];
        [self addSubview:self.cancel];
        
        // add observer for the respective notifications
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(addButtonToKeyboard)
                                                     name:UIKeyboardWillShowNotification
                                                   object:nil];
    }
    
    return self;
}

- (void)addButtonToKeyboard {
    // create custom button
    if (!self.doneButton) {
        self.doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.doneButton.frame = CGRectMake(0, 428, 106, 53);
        self.doneButton.adjustsImageWhenHighlighted = NO;
        
        [self.doneButton setImage:[UIImage imageNamed:@"DoneUp3.png"]
                    forState:UIControlStateNormal];
        [self.doneButton setImage:[UIImage imageNamed:@"DoneDown3.png"]
                    forState:UIControlStateHighlighted];
        
        [self.doneButton addTarget:self 
                       action:@selector(doneButton:)
             forControlEvents:UIControlEventTouchUpInside];
    }
    
    // locate keyboard view    
    UIView* keyboard;
    for(int i=0; i<[[[UIApplication sharedApplication] windows] count]; i++) {
        keyboard = [[[UIApplication sharedApplication] windows] objectAtIndex:i];
        // keyboard view found; add the custom button to it
        if([[keyboard description] hasPrefix:@"<UITextEffectsWindow"] == YES){
            [keyboard addSubview:self.doneButton];
            break;
        }
    }
}

- (void)doneButton:(id)sender {
    [self.doneButton removeFromSuperview];
    [self.number resignFirstResponder];
}

- (void)performedDismissOrderList:(DismissOrderListBlock)dismiss {
    dismissOrderList = dismiss;
}

- (void)dismissOrderList {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self.doneButton removeFromSuperview];
    [self.number resignFirstResponder];
    dismissOrderList();
}

- (void)placeOrder {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self.doneButton removeFromSuperview];
    [self.number resignFirstResponder];
    
    TTURLRequest *request = [TTURLRequest requestWithURL:[NSString stringWithFormat:@"%@://%@/make_order/", HTTPS, EOHOST] 
                                                delegate:self];
    
    request.cachePolicy = TTURLRequestCachePolicyNone;
    request.response = [[TTURLDataResponse alloc] init];
    request.httpMethod = @"POST";
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:self.number.text forKey:@"num_persons"];
    [dict setObject:[NSNumber numberWithInt:[OrderManager sharedManager].rID] forKey:@"restaurant_id"];
    [dict setObject:@"2" forKey:@"table_name"];
    NSMutableArray *arr = [NSMutableArray array];
    for (OrderItem *item in [OrderManager sharedManager].orders) {
        NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:item.dish.dishID, @"dish_id", [NSNumber numberWithInt:item.numOfOrders], @"quantity", nil];
        [arr addObject:dic];
    }
    [dict setObject:arr forKey:@"dishes"];
    
    SBJsonWriter *writer = [SBJsonWriter new];
    NSString *json = [writer stringWithObject:dict];
    NSLog(@"%@",json);
    request.httpBody = [json dataUsingEncoding:NSUTF8StringEncoding];
    [request send];
    
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeGradient networkIndicator:YES];
}

- (void)showView {
    [self.table reloadData];
}

#pragma mark UITableViewDataSource methods
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[OrderManager sharedManager].orders count];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *ReuseIdentifier = @"OrderListViewCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ReuseIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:ReuseIdentifier];
    }
    
    OrderItem *item = [[OrderManager sharedManager].orders objectAtIndex:indexPath.row];
    [cell.textLabel setText:item.dish.name];
    [cell.detailTextLabel setText:[NSString stringWithFormat:@"%d 份", item.numOfOrders]];
    
    return cell;
}

#pragma mark TTURLRequestDelegate
- (void)requestDidFinishLoad:(TTURLRequest*)request {
    NSData *data = [(TTURLDataResponse*)request.response data];
    
    SBJsonParser *parser = [SBJsonParser new];
    id obj = [parser objectWithData:data];
    if (obj && [obj isKindOfClass:[NSDictionary class]]) {
        if ([[obj objectForKey:@"status"] isEqualToString:@"OK"]) {
            [self dismissOrderList];
            [SVProgressHUD dismissWithSuccess:[obj objectForKey:@"info"] afterDelay:1];
        } else {
            [SVProgressHUD dismissWithError:[obj objectForKey:@"info"] afterDelay:1];
        }
    } else {
        [SVProgressHUD dismissWithError:@"Network Error" afterDelay:1];
    }
}

- (void)request:(TTURLRequest*)request didFailLoadWithError:(NSError*)error {
    [SVProgressHUD dismissWithError:@"Network Error" afterDelay:1];
    NSLog(@"%@", error);
}
@end
