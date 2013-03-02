//
//  MyOrdersViewController.m
//  EasyOrder
//
//  Created by igneus on 1/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MyOrdersViewController.h"
#import "AppDelegate.h"
#import <Three20/Three20.h>
#import "Const.h"
#import "NSDictionary+ParseHelper.h"
#import "NetworkHandler.h"
#import "Authentication.h"

@interface MyOrdersViewController ()
@property (nonatomic) BOOL loginAttempt;
@property (nonatomic, strong) NSArray *orders;
- (void)getMyOrders;

@end

@implementation MyOrdersViewController
@synthesize loginAttempt = _loginAttempt;
@synthesize orders = _orders;

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (![[Authentication sharedInstance] isLoggedIn]) {
        if (self.loginAttempt) {
            self.loginAttempt = NO;
            [self dismissModalViewControllerAnimated:NO];
            return;
        } else {
            self.loginAttempt = YES;
            AppDelegate *delegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
            [delegate showLogin];
            return;
        }
    }
    
    if (!self.orders) {
        [self getMyOrders];
    }
}

- (void)getMyOrders {
    [[NetworkHandler getHandler] requestFromURL:[NSString stringWithFormat:@"%@://%@/order/", HTTPS, EOHOST]
                     method:GET
                    success:^(id obj) {
                        if (obj && [obj isKindOfClass:[NSArray class]]) {
                            self.orders = (NSArray*)obj;
                            TTListDataSource *ds = [[TTListDataSource alloc] init];
                           
                            for (NSDictionary *dict in self.orders) {
                                NSString *createdTime = [dict objectForKeyInFields:@"created_time"];
                                NSString *restaurant = [[dict objectForKeyInFields:@"restaurant"] objectForKeyInFields:@"name"];
                                int oid = [[dict objectForKey:@"pk"] intValue];
                               
                                [ds.items addObject:[TTTableCaptionItem itemWithText:restaurant caption:createdTime URL:[NSString stringWithFormat:@"eo://orderdetail/Order/%d", oid]]];
                            }
                           
                            self.dataSource = ds;
                        } else {
                           
                        }
                    } failure:^{
                       
                    }];
}

@end
