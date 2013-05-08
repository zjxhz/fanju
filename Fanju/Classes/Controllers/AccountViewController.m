//
//  AccountViewController.m
//  EasyOrder
//
//  Created by 浣泽 徐 on 7/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AccountViewController.h"
#import "DDLog.h"
@interface AccountViewController ()

@end

@implementation AccountViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])  {
        self.tableViewStyle = UITableViewStyleGrouped;
        self.autoresizesForKeyboard = YES;
        self.variableHeightRows = YES;
        self.title = @"账户信息";	
        self.tabBarItem = [[UITabBarItem alloc] initWithTitle:self.title image:[UIImage imageNamed:@"account.png"] tag:0]; 
        
        self.dataSource = [TTSectionedDataSource dataSourceWithObjects:
        @"城市信息",
        [TTTableSettingsItem itemWithText:@"杭州" caption:@"切换城市"],
        @"账户",
        [TTTableSettingsItem itemWithText:@"已登录" caption:@"账户管理"],
                           nil];        
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

-(void) viewWillAppear:(BOOL)animated{
    DDLogVerbose(@"delegate class name: %@", NSStringFromClass([self.tableView.delegate class]));
    DDLogVerbose(@"number of sections: %d,rows in section 0: %d", [self.dataSource numberOfSectionsInTableView:self.tableView], [self.dataSource tableView:self.tableView numberOfRowsInSection:0]);
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
