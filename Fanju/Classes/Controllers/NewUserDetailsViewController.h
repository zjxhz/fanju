//
//  NewUserDetailsViewController.h
//  EasyOrder
//
//  Created by 浣泽 徐 on 8/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Three20/Three20.h>
#import "UserProfile.h"
#import "PhotoThumbnailCell.h"
#import "UserMoreDetailViewController.h"
#import "CellTextEditorViewController.h"
#import "PullRefreshTableViewController2.h"
#import "NewTagViewController.h"

typedef enum {
    ChangeAvatar, AddPhoto
}
PhotoUploadingOperation;

@protocol NewUserDetailsViewControllerDelegate <NSObject>

@optional
-(void)userFollowed:(UserProfile*)user;
-(void)userUnfollowed:(UserProfile*)user;

@end

@interface NewUserDetailsViewController : PullRefreshTableViewController2<UITableViewDelegate, UITableViewDataSource, PhotoThumbnailCellDelegate,UINavigationControllerDelegate, UIImagePickerControllerDelegate, UserDetailSaveDelegate,  CellTextEditorDelegate, TTPostControllerDelegate, UIActionSheetDelegate, UIGestureRecognizerDelegate, TagViewControllerDelegate>
@property(nonatomic, strong) UserProfile* user;
@property(nonatomic, weak) id<NewUserDetailsViewControllerDelegate> delegate;
@property(nonatomic, strong) NSString* userID;
-(void)setUsername:(NSString*)username;


@end
