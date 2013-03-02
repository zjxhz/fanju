//
//  ViewController.m
//  EasyOrder
//
//  Created by igneus on 11/30/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "LauncherViewController.h"
#import "MockDataSource.h"
#import "SCAppUtils.h"
#import "AppDelegate.h"

@implementation LauncherViewController

///////////////////////////////////////////////////////////////////////////////////////////////////
// NSObject

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {        
        self.title = NSLocalizedString(@"NavBarTitle", nil);
    }
    return self;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// UIViewController

- (void)loadView {
    [super loadView];
    
    //nav bar
    [SCAppUtils customizeNavigationController:self.navigationController];
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeInfoLight];
    UIBarButtonItem *temporaryBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:btn];
    self.navigationItem.rightBarButtonItem = temporaryBarButtonItem;
    
    //search bar
    TTTableViewController* searchController = [[TTTableViewController alloc] init];
    searchController.dataSource = [[MockSearchDataSource alloc] initWithDuration:1.5];
    self.searchViewController = searchController;
    [self.view addSubview:_searchController.searchBar];
    
    //launcher
    _launcherView = [[TTLauncherView alloc] initWithFrame:CGRectMake(0, 44, self.view.bounds.size.width, self.view.bounds.size.height - 44)];
    AppDelegate *delegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    _launcherView.backgroundColor = [UIColor colorWithPatternImage:delegate.bgImage];
    _launcherView.delegate = self;
    _launcherView.editable = NO;
    _launcherView.columnCount = 3;
    _launcherView.pages = [NSArray arrayWithObjects:
                           [NSArray arrayWithObjects:
                            [[TTLauncherItem alloc] initWithTitle:NSLocalizedString(@"StartOrder", nil)
                                                            image:@"bundle://order.png"
                                                               URL:@"eo://order/StartOrder" canDelete:YES],
                            [[TTLauncherItem alloc] initWithTitle:NSLocalizedString(@"Search", nil)
                                                             image:@"bundle://search.png"
                                                               URL:@"eo://search/Search" canDelete:YES],
                            [[TTLauncherItem alloc] initWithTitle:NSLocalizedString(@"Near", nil)
                                                             image:@"bundle://near.png"
                                                               URL:@"eo://list/Near" canDelete:YES],
                            [[TTLauncherItem alloc] initWithTitle:NSLocalizedString(@"Favorites", nil)
                                                             image:@"bundle://heart.png"
                                                               URL:nil canDelete:YES],
                            [[TTLauncherItem alloc] initWithTitle:NSLocalizedString(@"Recent", nil)
                                                             image:@"bundle://recent.png"
                                                               URL:nil canDelete:YES],
                            [[TTLauncherItem alloc] initWithTitle:NSLocalizedString(@"MyOrders", nil)
                                                             image:@"bundle://cart.png"
                                                               URL:@"eo://myorders/MyOrders" canDelete:YES],
                            [[TTLauncherItem alloc] initWithTitle:NSLocalizedString(@"Account", nil)
                                                             image:@"bundle://account.png"
                                                               URL:@"eo://login" canDelete:YES],
                            nil],
                           nil
                           ];
    
    _launcherView.pager.hidesForSinglePage = YES;
    [self.view addSubview:_launcherView];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// TTLauncherViewDelegate

- (void)launcherView:(TTLauncherView*)launcher didSelectItem:(TTLauncherItem*)item {
    TTOpenURL(item.URL);
}

- (void)launcherViewDidBeginEditing:(TTLauncherView*)launcher {
    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc]
                                                 initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                 target:_launcherView action:@selector(endEditing)] animated:YES];
}

- (void)launcherViewDidEndEditing:(TTLauncherView*)launcher {
    [self.navigationItem setRightBarButtonItem:nil animated:YES];
}



@end
