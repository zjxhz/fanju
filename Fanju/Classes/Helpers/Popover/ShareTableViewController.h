//
//  ShareTableViewController.h
//  EasyOrder
//
//  Created by 浣泽 徐 on 6/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol ShareToDelegate<NSObject>
@optional
-(void) shareToSinaWeibo;
-(void) shareToWeixinContact;
-(void) shareToWeixinTimeline;
@end


@interface ShareTableViewController : UITableViewController

@property(nonatomic, weak) id<ShareToDelegate> delegate;

@end
