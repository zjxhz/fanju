//
//  ClosablePopoverViewController.m
//  EasyOrder
//
//  Created by 浣泽 徐 on 9/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ClosablePopoverViewController.h"

@interface ClosablePopoverViewController ()

@end

@implementation ClosablePopoverViewController
@synthesize contentViewController = _contentViewController;

- (id)init {
	if ((self = [super init])) {
	}
	return self;
}

- (id)initWithContentViewController:(UITableViewController *)viewController {
	if ((self = [self init])) {
		self.contentViewController = viewController;
	}
	return self;
}

-(void)loadView{
    [super loadView];
    //standalone
    
    _contentViewController.tableView.frame = CGRectMake(20, 65, 280, 400);
    self.view.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
    
    UIImage* image = [UIImage imageNamed:@"menu_close"];
    UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(250, 0, image.size.width, image.size.height);
    [button setImage:image forState:UIControlStateNormal];
    button.contentMode = UIViewContentModeScaleToFill;
    [button addTarget:self action:@selector(close:) forControlEvents:UIControlEventTouchDown];

    [self.view addSubview:_contentViewController.tableView];
    [self.view addSubview:button];
}

-(void)close:(id)sender{
    [self dismissModalViewControllerAnimated:NO];
}


@end
