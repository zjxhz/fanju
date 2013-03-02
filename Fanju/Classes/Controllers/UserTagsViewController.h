//
//  MyTagsViewController.h
//  EasyOrder
//
//  Created by 徐 浣泽 on 1/25/13.
//
//

#import <Three20UI/Three20UI.h>
#import "UserProfile.h"
#import "NewTagViewController.h"

@interface UserTagsViewController : TTTableViewController<UITableViewDelegate, TagViewControllerDelegate>
@property(nonatomic, strong) UserProfile* user;
@property id<TagViewControllerDelegate> tagDelegate;
- (id)initWithUser:(UserProfile*)user;

@end
