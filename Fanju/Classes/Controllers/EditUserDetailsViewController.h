//
//  EditUserDetailsViewController.h
//  Fanju
//
//  Created by Xu Huanze on 5/22/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EditUserDetailsViewController : UITableViewController<UITextFieldDelegate, UITextViewDelegate, UIGestureRecognizerDelegate>
@property(nonatomic, strong) User* user;;
@end
