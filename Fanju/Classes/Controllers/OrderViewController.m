//
//  OrderViewController.m
//  EasyOrder
//
//  Created by igneus on 12/2/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "OrderViewController.h"
#import "MenuViewController.h"
#import <Three20/Three20.h>
#import "Const.h"
#import "NetworkHandler.h"
#import "LocationProvider.h"
#import "NSDictionary+ParseHelper.h"

@interface OrderViewController ()
@property (nonatomic, strong) NSArray *restaurants;
@end

@implementation OrderViewController
@synthesize restaurants = _restaurants;

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (!self.restaurants) {
        double longtitude = 120.163314;
        double latitude = 30.273025;
        if ([LocationProvider sharedProvider].lastLocation) {
            longtitude = [[LocationProvider sharedProvider].lastLocation coordinate].longitude;
            latitude = [[LocationProvider sharedProvider].lastLocation coordinate].latitude;
        }
        
        NSString *requestStr = [NSString stringWithFormat:@"%@://%@/get_restaurant_list_by_geo/?longitude=%g&latitude=%g&range=500", HTTPS, EOHOST, longtitude, latitude];
        
        NetworkHandler *handler = [[NetworkHandler alloc] init];
        [handler requestFromURL:requestStr
                         method:GET
                        success:^(id obj) {
                            if (obj && [obj isKindOfClass:[NSArray class]]) {
                                self.restaurants = (NSArray*)obj;
                                TTListDataSource *ds = [[TTListDataSource alloc] init];
                               
                                for (NSDictionary *dict in self.restaurants) {
                                    NSString *addr =  [dict objectForKeyInFields:@"address"];
                                    NSString *name = [dict objectForKeyInFields:@"name"];
                                    NSString *tel = [dict objectForKeyInFields:@"tel"];
                                    int rID = [[dict objectForKey:@"pk"] intValue];
                                   
                                    [ds.items addObject:[TTTableMessageItem itemWithTitle:name
                                                                                  caption:tel
                                                                                     text:addr
                                                                                timestamp:nil
                                                                                      URL:[NSString stringWithFormat:@"eo://menu/%d", rID]]];
                                }
                               
                                self.dataSource = ds;
                            } else {
                               
                            }
                        } failure:^{
                           
                        }];
    }
}

@end
