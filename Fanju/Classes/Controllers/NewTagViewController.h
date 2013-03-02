//
//  NewTagViewController.h
//  EasyOrder
//
//  Created by 徐 浣泽 on 1/23/13.
//
//

#import <UIKit/UIKit.h>
#import "UserProfile.h"
#import "Three20/Three20.h"
#import "TagAutocompleteTableView.h"

@protocol TagViewControllerDelegate
@optional
-(void)tagsSaved:(NSArray*)newTags forUser:(UserProfile*)user;
@end

@interface NewTagViewController : TTTableViewController<UITableViewDelegate, UIGestureRecognizerDelegate, UISearchBarDelegate, TagAutocompleteDelegate>
@property(nonatomic, strong) UserProfile* user;
@property id<TagViewControllerDelegate> delegate;

@end
