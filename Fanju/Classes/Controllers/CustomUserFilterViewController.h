//
//  CustomUserFilterViewController.h
//  EasyOrder
//
//  Created by 浣泽 徐 on 8/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AKSegmentedControl.h"

@protocol CustomUserFilterViewControllerDelegate
@optional
-(void)filterSelected:(NSDictionary*)filter;
@end


@interface CustomUserFilterViewController : UIViewController{
}
@property(nonatomic, weak) id<CustomUserFilterViewControllerDelegate> delegate;
-(IBAction)confirm:(id)sender;
@end
