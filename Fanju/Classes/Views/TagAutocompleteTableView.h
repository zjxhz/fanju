//
//  TagAutocompleteTableView.h
//  EasyOrder
//
//  Created by 徐 浣泽 on 1/24/13.
//
//

#import <UIKit/UIKit.h>
#import "UserTag.h"
@protocol TagAutocompleteDelegate
-(void)tagSelected:(UserTag*)tag;
@end

@interface TagAutocompleteTableView : UITableView<UITableViewDataSource, UITableViewDelegate>
@property(nonatomic, strong) NSMutableArray* tags;
-(BOOL)searchText:(NSString*)text;
@property(nonatomic, strong) id<TagAutocompleteDelegate> autocompleteDelegate;

@end
