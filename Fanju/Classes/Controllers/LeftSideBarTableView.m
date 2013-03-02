//
//  LeftSideBarTableView.m
//  EasyOrder
//
//  Created by igneus on 12/15/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "LeftSideBarTableView.h"
#import "SBJson.h"
#import "AppDelegate.h"
#import "UIImage+Resize.h"
#import "MenuUpdater.h"
#import "Restaurant+Query.h"

#define MY_FAVORITE NSLocalizedString(@"MyFavorites", nil)
#define RECENT_ORDERS NSLocalizedString(@"RecentOrders", nil)

@interface LeftSideBarTableView () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic) int expandedRow;
@property (nonatomic, strong) NSMutableArray *array;

- (void)menuUpdated:(NSNotification*)notif;

@end

@implementation LeftSideBarTableView

@synthesize expandedRow = _expandedRow;
@synthesize array = _array;
@synthesize categorySelectAction = _categorySelectAction;

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame style:UITableViewStylePlain])) {
        [self setBackgroundColor:[UIColor clearColor]];
        [self setSeparatorColor:[UIColor grayColor]];
        self.delegate = self;
        self.dataSource = self;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(menuUpdated:) 
                                                     name:MenuDidUpdateNotification
                                                   object:nil];
    }
    
    return self;
}

- (void)menuUpdated:(NSNotification*)notif {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MenuDidUpdateNotification object:nil];
    
    AppDelegate *delegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    NSManagedObjectContext *context = [delegate managedObjectContext];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    request.entity = [NSEntityDescription entityForName:@"Category" inManagedObjectContext:context];
    request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"categoryID" ascending:YES]];
    NSPredicate *p1 = [NSPredicate predicateWithFormat:@"parent = nil"];
    
    Restaurant *restaurant = [Restaurant restaurantWithID:25
                                   inManagedObjectContext:[delegate managedObjectContext]];
    NSPredicate *p2 = [NSPredicate predicateWithFormat:@"%@ IN belongsToRestaurants", restaurant];
    request.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:p1, p2, nil]];
    request.fetchBatchSize = 20;
    
    self.array = [[context executeFetchRequest:request error:nil] mutableCopy]; 
    [self.array addObject:MY_FAVORITE];
    [self.array addObject:RECENT_ORDERS];

    self.expandedRow = -1;
    
    [self reloadData];
}

- (void)clearTableSelection {
    NSIndexPath *selected = [self indexPathForSelectedRow];
    [self deselectRowAtIndexPath:selected animated:NO];
}

- (UIButton *)makeExpandButton:(BOOL)isExpanded
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    if (isExpanded) {
        [button setImage:[UIImage imageNamed:@"collapse.png"] forState:UIControlStateNormal];
    } else {
        [button setImage:[UIImage imageNamed:@"expand.png"] forState:UIControlStateNormal];
    }
    [button setFrame:CGRectMake(0, 0, 43, 43)];
    [button setImageEdgeInsets:UIEdgeInsetsMake(12, 12, 12, 12)];
    [button setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.3]];
    [button addTarget:self
               action:@selector(accessoryButtonTapped:withEvent:)
     forControlEvents:UIControlEventTouchUpInside];
    
    return button;
}

- (void)accessoryButtonTapped:(UIControl *)button withEvent:(UIEvent *)event {
    NSIndexPath * indexPath = [self indexPathForRowAtPoint:[[[event touchesForView:button] anyObject] 
                                                                      locationInView:self]];
    if (indexPath == nil)
        return;
    
    [self.delegate tableView:self didSelectRowAtIndexPath:indexPath];
    //[self.tableView.delegate tableView:self.tableView accessoryButtonTappedForRowWithIndexPath:indexPath];
}

#pragma mark UITableViewDataSource methods
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.array count];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *ReuseIdentifier = @"LeftSideMenuTableViewCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ReuseIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ReuseIdentifier];
    }
	
    id rowObj = [self.array objectAtIndex:indexPath.row];
    
    if ([rowObj isKindOfClass:[Category class]]) {
        Category *category = (Category*)rowObj;
        if ([category.subCategories count] > 0) {
            cell.accessoryView = [self makeExpandButton:(indexPath.row == self.expandedRow)];
            [cell.contentView setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.3]];
            cell.selectionStyle = UITableViewCellSelectionStyleNone; 
        } else {
            cell.accessoryView = nil;
            [cell.contentView setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.5]];
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
            
            UIView *selectedBg = [[UIView alloc] initWithFrame:cell.frame];
            [selectedBg setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.5]];
            UIImageView *img = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"categoryselected.png"]];
            [selectedBg addSubview:img];
            [cell setSelectedBackgroundView:selectedBg];
        }
        
        cell.textLabel.text = ((Category*)rowObj).name;
        cell.imageView.image = nil;
    } else if ([rowObj isKindOfClass:[NSString class]]) {
        if ([rowObj isEqualToString:MY_FAVORITE]) {
            [cell.imageView setImage:[[UIImage imageNamed:@"favorite.png"] imageScaledToSize:CGSizeMake(20, 20)]];
        } else {
            [cell.imageView setImage:[[UIImage imageNamed:@"recentdish.png"] imageScaledToSize:CGSizeMake(20, 20)]];
        }
        
        UIView *selectedBg = [[UIView alloc] initWithFrame:cell.frame];
        [selectedBg setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.5]];
        UIImageView *img = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"categoryselected.png"]];
        [selectedBg addSubview:img];
        [cell setSelectedBackgroundView:selectedBg];
        
        cell.textLabel.text = rowObj;   
    }   
	
	return cell;
}

#pragma mark UITableViewDelegate methods
- (int)collapseRowsInSection:(int)section {    
    //collapse expanded category
    Category *expandedCategory = [self.array objectAtIndex:self.expandedRow];
    int expandedRows = [expandedCategory.subCategories count];
    
    [self.array removeObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(self.expandedRow + 1, expandedRows)]];
    [self beginUpdates];
    NSMutableArray *indexPaths = [NSMutableArray array];
    for (int i = 0; i < expandedRows; i++) {
        NSIndexPath *path = [NSIndexPath indexPathForRow:self.expandedRow + i + 1 inSection:section];
        [indexPaths addObject:path];
    }
    [self deleteRowsAtIndexPaths:indexPaths 
                          withRowAnimation:UITableViewRowAnimationBottom];
    
    //repaint collapsed row indicator
    int collapsed = self.expandedRow;
    self.expandedRow = -1;
    [self endUpdates];
    
    [self reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:collapsed
                                                                                       inSection:section]] 
                          withRowAnimation:UITableViewRowAnimationNone];
    
    return expandedRows;

}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    int row = indexPath.row;
	id rowObj = [self.array objectAtIndex:row];
    
    if ([rowObj isKindOfClass:[Category class]]) {
        Category *category = (Category*)rowObj;
        
        int subCount = [category.subCategories count];
        if (subCount > 0) {
            if (self.expandedRow != row) {
                if (self.expandedRow >= 0) {
                    //save the original expanded row index, because collapseRowsInSection will change it
                    int originalExpandedRow = self.expandedRow;
                    int rowsCollapsed = [self collapseRowsInSection:indexPath.section];
                    
                    if (row > originalExpandedRow) {
                        row -= rowsCollapsed;
                    }
                }
                
                //expand subcategories
                self.expandedRow = row;
                [self.array insertObjects:[category.subCategories allObjects] atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(row + 1, subCount)]];
                [tableView beginUpdates];            
                NSMutableArray *indexPaths = [NSMutableArray array];
                for (int i = 0; i < subCount; i++) {
                    NSIndexPath *path = [NSIndexPath indexPathForRow:row + i + 1 inSection:indexPath.section];
                    [indexPaths addObject:path];
                };
                [tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationBottom];
                [tableView endUpdates];
                
                [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:row inSection:indexPath.section]] 
                                 withRowAnimation:UITableViewRowAnimationNone];
            }
            
            category = [[category.subCategories allObjects] objectAtIndex:0];
            [tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:row + 1
                                                               inSection:indexPath.section] 
                                   animated:NO
                             scrollPosition:UITableViewScrollPositionNone];
        }
        
        self.categorySelectAction(category);
    }
}

@end