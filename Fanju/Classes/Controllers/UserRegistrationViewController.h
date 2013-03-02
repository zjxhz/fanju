//
//  UserRegistrationViewController.h
//  EasyOrder
//
//  Created by 浣泽 徐 on 8/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UserProfile.h"
#import "Authentication.h"
#import "NameAndGenderViewController.h"

@interface UserRegistrationViewController : UITableViewController<AuthenticationDelegate>
@property(nonatomic, readonly) NameAndGenderViewController* nameAndGender;
@property(nonatomic, strong) UserProfile* user;

@end
