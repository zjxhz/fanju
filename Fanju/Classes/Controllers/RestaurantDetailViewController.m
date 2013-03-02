//
//  RestaurantDetailViewController.m
//  EasyOrder
//
//  Created by igneus on 12/3/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "RestaurantDetailViewController.h"
#import "AppDelegate.h"
#import "Const.h"
#import "NetworkHandler.h"

@interface RestaurantDetailViewController () 

@property (nonatomic, strong) RestaurantInfo *info;

-(void)launchMap;

@end

@implementation RestaurantDetailViewController 

@synthesize info = _info;

-(id)initWithTitle:(NSString*)title {
    AppDelegate *delegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    RestaurantInfo* info = (RestaurantInfo*)delegate.sharedObject;
    
    if (self = [super initWithTitle:info.title]) {
        self.info = info;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    TTButton *btn = [TTButton buttonWithStyle:@"embossedButton:" title:NSLocalizedString(@"Map", nil)];
    [btn addTarget:self
            action:@selector(launchMap) 
  forControlEvents:UIControlEventTouchDown];
    btn.font = [UIFont systemFontOfSize:13];
    [btn sizeToFit];
    UIBarButtonItem *temporaryBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:btn];
    self.navigationItem.rightBarButtonItem = temporaryBarButtonItem;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    //get restaurant info
    NSString *requestStr = [NSString stringWithFormat:@"http://%@/restaurant/%d", EOHOST, self.info.rID];
    [[NetworkHandler getHandler] requestFromURL:requestStr
                     method:GET
                    success:^(id obj) {
                        if (obj && [obj isKindOfClass:[NSDictionary class]]) {
                            TTListDataSource *ds = [[TTListDataSource alloc] init];
                           
                            [ds.items addObject:[TTTableLongTextItem itemWithText:[NSString stringWithFormat:@"%@", obj]]];
                           
                            self.dataSource = ds;
                        } else {
                           
                        }
                    } failure:^{
                       
                    }];
}

-(void)launchMap {
    TTOpenURL(@"eo://launchmap/map");
}

@end
