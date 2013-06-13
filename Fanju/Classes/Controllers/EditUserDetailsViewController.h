//
//  EditUserDetailsViewController.h
//  Fanju
//
//  Created by Xu Huanze on 5/22/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DatePickerWithToolbarView.h"
#import "UserTagsViewController.h"
#import "ImageUploader.h"
#import "SetMottoViewController.h"

@interface EditUserDetailsViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UITextViewDelegate, UIGestureRecognizerDelegate, DatePickerViewDelegate, TagViewControllerDelegate, ImageUploaderDelegate, UIPickerViewDataSource, UIPickerViewDelegate, SetMottoDelegate, UIAlertViewDelegate>
@property(nonatomic, strong) User* user;;
@end
