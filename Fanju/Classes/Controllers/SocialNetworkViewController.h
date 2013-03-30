//
//  SocialNetworkViewController.h
//  EasyOrder
//
//  Created by igneus on 3/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Three20/Three20.h>
#import "PullRefreshTableViewController.h"
#import "NewUserDetailsViewController.h"

@interface SocialNetworkViewController : PullRefreshTableViewController <NewUserDetailsViewControllerDelegate, UIAlertViewDelegate>

@end
