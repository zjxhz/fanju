//
//  EmailViewController.h
//  EasyOrder
//
//  Created by 浣泽 徐 on 9/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UserProfile.h"
#import "NameAndGenderViewController.h"

@interface EmailViewController : UITableViewController
@property(nonatomic, readonly) NameAndGenderViewController* nameAndGender;
@property(nonatomic, strong) UserProfile* user;
@end
