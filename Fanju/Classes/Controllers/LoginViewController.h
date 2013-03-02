//
//  LoginViewController.h
//  EasyOrder
//
//  Created by 徐 浣泽 on 10/8/12.
//
//

#import <UIKit/UIKit.h>
#import "Authentication.h"

@interface LoginViewController : UIViewController<AuthenticationDelegate>
-(IBAction)loginWithEmail:(id)sender;
-(IBAction)loginWithWeibo:(id)sender;
-(IBAction)loginWithQQ:(id)sender;

@end
