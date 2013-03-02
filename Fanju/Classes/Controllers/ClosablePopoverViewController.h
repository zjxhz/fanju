//
//  ClosablePopoverViewController.h
//  EasyOrder
//
//  Created by 浣泽 徐 on 9/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ClosablePopoverViewController : UIViewController
@property(nonatomic, retain) UITableViewController *contentViewController;
- (id)initWithContentViewController:(UITableViewController *)viewController;
@end
