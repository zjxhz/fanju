//
//  RestaurantSearchViewController.m
//  EasyOrder
//
//  Created by igneus on 12/3/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "RestaurantSearchViewController.h"
#import "MockDataSource.h"
#import "Const.h"
#import "SBJson.h"
#import "SVProgressHUD.h"
#import "NSDictionary+ParseHelper.h"

@interface RestaurantSearchViewController () <UISearchBarDelegate>
@property (nonatomic, strong) NSArray *restaurants;
@property (nonatomic, strong) NSArray *sections;
@property (nonatomic, strong) NSMutableArray *items;
@end

@implementation RestaurantSearchViewController

@synthesize restaurants = _restaurants;
@synthesize sections = _sections;
@synthesize items = _items;

- (void)viewDidLoad {

    [super viewDidLoad];
    
    NSString *requestStr = [NSString stringWithFormat:@"http://%@/restaurant_tag/", EOHOST];
    TTURLRequest *request = [TTURLRequest requestWithURL:requestStr 
                                                delegate:self];
    
    request.cachePolicy = TTURLRequestCachePolicyLocal;
    request.response = [[TTURLDataResponse alloc] init];
    request.httpMethod = @"GET";
    
    [request send];
    
    requestStr = [NSString stringWithFormat:@"http://%@/business_district/", EOHOST];
    request = [TTURLRequest requestWithURL:requestStr 
                                                delegate:self];
    
    request.cachePolicy = TTURLRequestCachePolicyLocal;
    request.response = [[TTURLDataResponse alloc] init];
    request.httpMethod = @"GET";
    
    [request send];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    //search bar
    TTTableViewController* searchController = [[TTTableViewController alloc] init];
    searchController.dataSource = [[MockSearchDataSource alloc] initWithDuration:1.5];
    self.searchViewController = searchController;
    self.tableView.tableHeaderView = _searchController.searchBar;
    _searchController.searchBar.delegate = self;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    
    NSString *requestStr = [NSString stringWithFormat:@"http://%@/search_restaurant_list/?key=%@", EOHOST, [searchBar.text stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSLog(@"%@", requestStr);
    TTURLRequest *request = [TTURLRequest requestWithURL:requestStr 
                                                delegate:self];
    
    request.cachePolicy = TTURLRequestCachePolicyNone;
    request.response = [[TTURLDataResponse alloc] init];
    request.httpMethod = @"GET";
    
    [request send];
    
    [_searchController setActive:NO];
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeGradient networkIndicator:YES];
}

#pragma mark TTURLRequestDelegate
- (void)requestDidFinishLoad:(TTURLRequest*)request {
    NSData *data = [(TTURLDataResponse*)request.response data];
    
    SBJsonParser *parser = [SBJsonParser new];
    id obj = [parser objectWithData:data];
    
    if ([request.urlPath rangeOfString:@"restaurant_tag"].location != NSNotFound) {
        if (obj && [obj isKindOfClass:[NSArray class]]) {
            if (!self.sections) {
                self.sections = [NSMutableArray arrayWithObjects:@"热门商区", @"频道", nil];
            }
            
            if (!self.items) {
                self.items = [NSMutableArray array];
                [self.items addObject:[NSMutableArray array]];
                [self.items addObject:[NSMutableArray array]];
            }

            for (NSDictionary *dict in obj) {
                NSString *name = [dict objectForKeyInFields:@"name"];
                [[self.items objectAtIndex:1] addObject:[TTTableTextItem itemWithText:name]];
            }
                        
            self.dataSource = [TTSectionedDataSource dataSourceWithItems:self.items sections:self.sections];
        }
    } else if ([request.urlPath rangeOfString:@"business_district"].location != NSNotFound) {
        if (!self.sections) {
            self.sections = [NSMutableArray arrayWithObjects:@"热门商区", @"频道", nil];
        }
        
        if (!self.items) {
            self.items = [NSMutableArray array];
            [self.items addObject:[NSMutableArray array]];
            [self.items addObject:[NSMutableArray array]];
        }
        
        for (NSDictionary *dict in obj) {
            NSString *name = [dict objectForKeyInFields:@"name"];
            [[self.items objectAtIndex:0] addObject:[TTTableTextItem itemWithText:name]];
        }
        
        self.dataSource = [TTSectionedDataSource dataSourceWithItems:self.items sections:self.sections];
    } else {
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
        
        [SVProgressHUD dismiss];   
    }
}

- (void)request:(TTURLRequest*)request didFailLoadWithError:(NSError*)error {
    [SVProgressHUD dismissWithError:@"Network Error" afterDelay:1];
    NSLog(@"%@", error);
}

@end
