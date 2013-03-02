//
//  OrderDetailViewController.m
//  EasyOrder
//
//  Created by igneus on 1/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OrderDetailViewController.h"
#import <Three20/Three20.h>
#import "NetworkHandler.h"
#import "Const.h"
#import "NSDictionary+ParseHelper.h"

@interface OrderDetailViewController ()
@property (nonatomic) int oid;

- (void)getOrderDetail;
@end

@implementation OrderDetailViewController
@synthesize oid = _oid;


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self getOrderDetail];
}

-(id)initWithTitle:(NSString*)title orderid:(int)oid {
    if (self = [super initWithTitle:title]) {
        self.oid = oid;
    }
    
    return self;
}

- (void)getOrderDetail {
    [[NetworkHandler getHandler] requestFromURL:[NSString stringWithFormat:@"%@://%@/order/%d", HTTPS, EOHOST, self.oid]
                     method:GET
                    success:^(id obj) {
                        if (obj && [obj isKindOfClass:[NSDictionary class]]) {
                            int numOfPersons = [[obj objectForKeyInFields:@"num_persons"] intValue];
                            int table = [[obj objectForKeyInFields:@"table"] intValue];
                            double totalPrice = [[obj objectForKeyInFields:@"total_price"] doubleValue];
                            NSString *dateTime = [obj objectForKeyInFields:@"created_time"];
                            NSDateFormatter *dt = [[NSDateFormatter alloc] init];   
                            [dt setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
                            NSDate *d = [dt dateFromString:dateTime];
                            NSLog(@"%@, %@",d, dateTime);
                           
                            int status = [[obj objectForKeyInFields:@"status"] intValue];
                            NSArray *dishes = [obj objectForKeyInFields:@"dishes"];
                           
                            TTListDataSource *ds = [[TTListDataSource alloc] init];
                            [ds.items addObject:[TTTableMessageItem itemWithTitle:[NSString stringWithFormat:@"%@ %.2f",    NSLocalizedString(@"TotalPrice", nil),totalPrice]
                                                                          caption:[NSString stringWithFormat:@"%@ %d     %@ %d", NSLocalizedString(@"NumberOfPPL", nil), numOfPersons,  NSLocalizedString(@"Table", nil), table]
                                                                             text:[NSString stringWithFormat:@"status : %d", status]
                                                                        timestamp:d
                                                                         imageURL:nil 
                                                                              URL:nil]];
                           
                            for (NSDictionary *dict in dishes) {
                                NSString *name = [[dict objectForKeyInFields:@"dish"] objectForKeyInFields:@"name"];
                                int number = [[dict objectForKeyInFields:@"quantity"] intValue];
                                double price = [[[dict objectForKeyInFields:@"dish"] objectForKeyInFields:@"price"] doubleValue];
                               
                                [ds.items addObject:[TTTableSubtitleItem itemWithText:name
                                                                             subtitle:[NSString stringWithFormat:@"%.2f * %d", price, number]]];
                            }
                           
                            self.dataSource = ds;
                        } else {
                           
                        }
                    } failure:^{
                       
                    }];
}

@end
