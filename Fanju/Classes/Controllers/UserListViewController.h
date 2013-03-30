//
//  UserListViewController.h
//  EasyOrder
//
//  Created by igneus on 3/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CommonTableViewController.h"
#import "LoadMoreTableItem.h"
#import "CustomUserFilterViewController.h"
#import "PullRefreshTableViewController.h"
#import "LocationProvider.h"

@interface UserListViewController : PullRefreshTableViewController<UIActionSheetDelegate, CustomUserFilterViewControllerDelegate, UIScrollViewDelegate, UITableViewDelegate>{
    LoadMoreTableItem *_loadMore;
    NSString* _filter;
    CustomUserFilterViewController* _customUserFilterViewController;
}

@property(nonatomic, copy) NSString* baseURL;
@property(nonatomic) BOOL hideNumberOfSameTags;
@property(nonatomic) BOOL hideFilterButton;
@property(nonatomic) BOOL showAddTagButton;
@property(nonatomic, strong) UserTag* tag;

+(UserListViewController*)recommendedUserListViewController;
+(UserListViewController*)nearbyUserListViewController;
    
@end
