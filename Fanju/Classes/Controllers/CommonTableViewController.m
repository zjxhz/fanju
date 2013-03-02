//
//  CommonTableViewController.m
//  EasyOrder
//
//  Created by igneus on 12/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "CommonTableViewController.h"
#import "AppDelegate.h"

@implementation CommonTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    TTButton *btn = [TTButton buttonWithStyle:@"embossedBackButton:" title:NSLocalizedString(@"Back", nil)];
    [btn addTarget:self.navigationController 
            action:@selector(popViewControllerAnimated:) 
  forControlEvents:UIControlEventTouchDown];
    btn.font = [UIFont systemFontOfSize:13];
    [btn sizeToFit];
    
    UIBarButtonItem *temporaryBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:btn];
    
    self.navigationItem.leftBarButtonItem = temporaryBarButtonItem;
    self.navigationItem.hidesBackButton = YES;
}

-(id)initWithTitle:(NSString*)title {
    if (self = [super init]) {
        self.title = NSLocalizedString(title, nil);
        self.tableViewStyle = UITableViewStyleGrouped;  
        self.tableView.rowHeight = 90;
        self.variableHeightRows = YES;  
        AppDelegate *delegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
        self.tableView.backgroundColor = [UIColor colorWithPatternImage:delegate.bgImage]; 
    }
    
    return self;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
