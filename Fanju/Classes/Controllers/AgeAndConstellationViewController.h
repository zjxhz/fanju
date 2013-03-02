//
//  AgeAndConstellationViewController.h
//  EasyOrder
//
//  Created by 浣泽 徐 on 8/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UserProfile.h"

@protocol AgeAndConstellationDelegate <NSObject>
-(void)birthdayUpdate:(NSDate*)birthday;
@end

@interface AgeAndConstellationViewController : UITableViewController
@property(nonatomic, weak) id<AgeAndConstellationDelegate> delegate;
@property(nonatomic, strong) UserProfile* user;

-(id)initWithBirthday:(NSDate*)birthday;
-(id)initWithUser:(UserProfile*)user next:(UIViewController*)nextViewController;
@end
