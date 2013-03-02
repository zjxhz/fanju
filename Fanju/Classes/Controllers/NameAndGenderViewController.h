//
//  NameAndGenderViewController.h
//  EasyOrder
//
//  Created by 浣泽 徐 on 8/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UserProfile.h"

@interface NameAndGenderViewController : UITableViewController <UIGestureRecognizerDelegate>
@property(nonatomic, strong) UserProfile* user;

@end
