//
//  RecentContactsViewController.h
//  EasyOrder
//
//  Created by 徐 浣泽 on 11/4/12.
//
//

#import <Three20UI/Three20UI.h>
#import "UserProfile.h"

@interface RecentContactsViewController : TTTableViewController<UITableViewDelegate>
@property(nonatomic, strong) UserProfile *profile;
@end
