//
//  MealListViewController.h
//  EasyOrder
//
//  Created by igneus on 3/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Three20/Three20.h>
#import "PullRefreshTableViewController.h"
#import "Authentication.h"
#import "ImageDownloader.h"
#import "ODRefreshControl.h"

@interface MealListViewController : TTTableViewController <UITableViewDelegate, AuthenticationDelegate, UIScrollViewDelegate>{
    UIView *_thisWeek;
    UIView *_afterThisWeek;
    NSMutableDictionary* imageDownloadsInProgress;
    ODRefreshControl* _refreshControl;
}
//-(IBAction)loginWithEmail:(id)sender;
-(IBAction)loginWithWeibo:(id)sender;
//-(IBAction)loginWithQQ:(id)sender;
//-(IBAction)register:(id)sender;
@end
