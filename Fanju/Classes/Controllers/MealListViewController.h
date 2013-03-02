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

@interface MealListViewController : PullRefreshTableViewController <UITableViewDelegate, AuthenticationDelegate, ImageDownloaderDelegate, UIScrollViewDelegate>{
    UIView *_thisWeek;
    UIView *_afterThisWeek;
    NSMutableDictionary* imageDownloadsInProgress;
}
-(IBAction)loginWithEmail:(id)sender;
-(IBAction)loginWithWeibo:(id)sender;
-(IBAction)loginWithQQ:(id)sender;
-(IBAction)register:(id)sender;
-(void)reload;
@end
