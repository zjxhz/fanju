//
//  UserMoreDetailViewController.h
//  EasyOrder
//
//  Created by 浣泽 徐 on 7/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UserProfile.h"
#import "CellTextEditorViewController.h"
#import "AgeAndConstellationViewController.h"
#import "UserImageView.h"
#import "IndustryAndOccupationViewController.h"
#import "NewTagViewController.h"

@protocol UserDetailSaveDelegate <NSObject>

@optional
-(void)userProfileUpdated:(User*)user;

@end

@interface UserMoreDetailViewController : UITableViewController<CellTextEditorDelegate,AgeAndConstellationDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, TagViewControllerDelegate, IndustryAndOccupationViewControllerDelegate>
@property(nonatomic, strong) User* user;
@property(nonatomic, weak) id<UserDetailSaveDelegate> delegate;

- (id)initWithStyle:(UITableViewStyle)style;

@end
