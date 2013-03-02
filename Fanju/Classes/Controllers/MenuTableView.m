//
//  MenuTableViewController.m
//  EasyOrder
//
//  Created by igneus on 12/17/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MenuTableView.h"
#import "MenuViewController.h"
#import <Three20/Three20.h>
#import "DishImageCell.h"
#import "MyCustomStylesheet.h"
#import "AppDelegate.h"
#import "MenuUpdater.h"
#import "Restaurant+Query.h"
#import "Category.h"

@interface MenuTableView() <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *categories;
@end

@implementation MenuTableView
@synthesize tableView = _tableView;
@synthesize categories = _categories;
@synthesize array = _array;
@synthesize displayMode = _displayMode;
@synthesize tablePanAction = _tablePanAction, dishSelectAction = _dishSelectAction;

- (void)setDisplayMode:(CellDisplayMode)displayMode {
    if (displayMode != _displayMode) {
        _displayMode = displayMode;
        [self.tableView reloadData];
    }
}

#pragma mark - View lifecycle

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(menuUpdated:) 
                                                     name:MenuDidUpdateNotification
                                                   object:nil];
        
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self 
                                                                                     action:@selector(handleRightViewPanGesture:)];
        [self addGestureRecognizer:panGesture];
    }
    
    return self;
}

- (void)menuUpdated:(NSNotification*)notif {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MenuDidUpdateNotification object:nil];
    
    //setup datasource
    AppDelegate *appDelegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    
    //get categories which has no subcategories
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    request.entity = [NSEntityDescription entityForName:@"Category" inManagedObjectContext:context];
    request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"categoryID" ascending:YES]];
    //NSPredicate *p1 = [NSPredicate predicateWithFormat:@"subCategories.@count = %d", 0];
    NSPredicate *p1 = [NSPredicate predicateWithFormat:@"parent = nil"];
    
    Restaurant *restaurant = [Restaurant restaurantWithID:25
                                   inManagedObjectContext:[appDelegate managedObjectContext]];
    NSPredicate *p2 = [NSPredicate predicateWithFormat:@"%@ IN belongsToRestaurants", restaurant];
    request.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:p1, p2, nil]];
    request.fetchBatchSize = 20;
    
    NSArray *tmpCategories = [context executeFetchRequest:request error:nil];
    self.categories = [NSMutableArray array];
    for (Category *category in tmpCategories) {
        if ([category.subCategories count] > 0) {
            [self.categories addObjectsFromArray:[category.subCategories allObjects]];
        } else {
            [self.categories addObject:category];
        }
    }
    
    self.array = [NSMutableArray array];
    for (Category *category in self.categories) {
        request.entity = [NSEntityDescription entityForName:@"Dish" inManagedObjectContext:context];
        request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"dishID" ascending:YES]];
        request.predicate = [NSPredicate predicateWithFormat:@"%@ IN belongsToCategories", category];
        request.fetchBatchSize = 20;

        [self.array addObject:[context executeFetchRequest:request error:nil]];
    }

    [self setBackgroundColor:MENU_MAIN_COLOR];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)
                                                  style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    //self.tableView.userInteractionEnabled = NO;
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self.tableView setBackgroundColor:[UIColor clearColor]];
    [self addSubview:self.tableView];
}

- (void)toggleMenuTable {
    CGRect destination = self.frame;
    
    if (destination.origin.x > 0) {
        destination.origin.x = 0;
    } else {
        destination.origin.x += LEFT_SIDEBAR_WIDTH;
    }
    
    [UIView animateWithDuration:0.25 animations:^{
        self.frame = destination;        
    } completion:^(BOOL finished) {
        self.tableView.userInteractionEnabled = !(destination.origin.x > 0);
    }];
    
}

- (void)categorySelected:(Category*)category {
    int section = [self.categories indexOfObject:category];
    if ([[self.array objectAtIndex:section] count] > 0) {
        [self toggleMenuTable];
        self.tablePanAction();
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:section] 
                              atScrollPosition:UITableViewScrollPositionTop
                                      animated:YES];
    }
}

- (void)handleRightViewPanGesture:(UIPanGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateChanged) {      
        CGPoint translate = [recognizer translationInView:self];
        
        CGRect newFrame = recognizer.view.frame;
        newFrame.origin.x += translate.x;
        if (newFrame.origin.x > 0 && newFrame.origin.x < LEFT_SIDEBAR_WIDTH) {
            recognizer.view.frame = newFrame;
        }
        
        [recognizer setTranslation:CGPointZero inView:self];
        
    } else if (recognizer.state == UIGestureRecognizerStateEnded) {
        CGRect destination = CGRectMake(0, self.frame.origin.y, self.frame.size.width, self.frame.size.height);
        
        CGPoint velocity = [recognizer velocityInView:self];
        
        if(velocity.x > 0)
        {
            destination.origin.x = LEFT_SIDEBAR_WIDTH;
        }
        
        [UIView animateWithDuration:0.25 animations:^{
            recognizer.view.frame = destination;        
        } completion:^(BOOL finished) {
            self.tableView.userInteractionEnabled = !(destination.origin.x > 0);
            self.tablePanAction();
        }];
    } else if (recognizer.state == UIGestureRecognizerStateBegan) {
        self.tableView.userInteractionEnabled = NO;
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.categories count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self.array objectAtIndex:section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"DishImageCell";
    
    DishImageCell *cell = (DishImageCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[DishImageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }

    if (indexPath.row % 2 == 0) {
        [cell.contentView setBackgroundColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:0.3]];
    } else {
        [cell.contentView setBackgroundColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:0.5]];
    }
    
    cell.displayMode = self.displayMode;
    cell.dish = [[self.array objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    int section = indexPath.section;
    int index = 0;
    if (section == 0) {
        index = indexPath.row;
    } else {
        for (int i = 0; i < section; i++) {
            index += [[self.array objectAtIndex:section] count];
        }
        
        index += indexPath.row;
    }

    [cell setImageTappedAction:[^{
        self.dishSelectAction(index);
    } copy]];
    
    return cell;
}

#pragma mark - Table view delegate
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {

    TTStyle *style = [TTShapeStyle styleWithShape:[TTRoundedRightArrowShape shapeWithRadius:5] next:
                      [TTSolidFillStyle styleWithColor:MENU_CELL_COLOR1 next:
        [TTTextStyle styleWithColor:[UIColor whiteColor] next:nil]]];
    
    NSString *title = ((Category*)[self.categories objectAtIndex:section]).name;
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 64, 36)];
    
    TTLabel *label = [[TTLabel alloc] initWithText:title];
    CGRect frame = CGRectMake(2, 6, 64, 30);
    [label setBackgroundColor:[UIColor clearColor]];
    [label setFrame:frame];
    [label setFont:[UIFont boldSystemFontOfSize:15]];
    label.style = style;
    [view addSubview:label];
    
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 36;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.displayMode == CellDisplayImageMode) {
        return 120;
    } else {
        return 60;
    }
    
}

@end
