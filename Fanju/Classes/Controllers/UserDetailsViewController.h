//
//  UserDetailsViewController.h
//  Fanju
//
//  Created by Xu Huanze on 5/15/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User.h"
#import "CellTextEditorViewController.h"
#import "NewTagViewController.h"
#import "ImageUploader.h"
#import "PhotoThumbnailCell.h"
#import "UserMoreDetailViewController.h"
#import "SetMottoViewController.h"

@interface UserDetailsViewController : UIViewController<CellTextEditorDelegate,PhotoThumbnailCellDelegate,UINavigationControllerDelegate, UserDetailSaveDelegate,  CellTextEditorDelegate, UIActionSheetDelegate, UIGestureRecognizerDelegate, TagViewControllerDelegate, ImageUploaderDelegate, SetMottoDelegate, UIAlertViewDelegate, UITableViewDataSource, UITableViewDelegate>
@property(nonatomic, strong) User* user;
-(void)reload:(id)sender;

@end
