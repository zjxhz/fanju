//
//  CustomUserFilterViewController.h
//  EasyOrder
//
//  Created by 浣泽 徐 on 8/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol CustomUserFilterViewControllerDelegate
@optional
-(void)filterSelected:(NSString*)filter;
@end


@interface CustomUserFilterViewController : UIViewController{
    IBOutlet UIButton* okbutton;
    IBOutlet UISegmentedControl* gender;
    IBOutlet UISegmentedControl* seen_within;
    NSString* filter;
}
@property(nonatomic, weak) id<CustomUserFilterViewControllerDelegate> delegate;
-(IBAction)confirm:(id)sender;
@end
