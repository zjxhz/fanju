//
//  ActivationViewController.h
//  iMobileTracker
//
//  Created by Liu Xiaozhi on 8/19/11.
//  Copyright 2011 Vobile Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ELCTextfieldCell.h"
#import "Authentication.h"

@interface ActivationViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, ELCTextFieldDelegate,  AuthenticationDelegate> 

@end
