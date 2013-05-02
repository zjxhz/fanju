//
//  MenuViewController.m
//  Fanju
//
//  Created by Xu Huanze on 5/1/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import "MenuViewController.h"
#import "CategoryItem.h"
#import "DishItem.h"

@interface MenuViewController (){
    NSArray* _groupedDishes;
}

@end

@implementation MenuViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.backgroundColor = [UIColor clearColor];
//    _tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg"]];
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.tableHeaderView.clipsToBounds = NO;
    [_tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)setMealMenu:(MealMenu *)mealMenu{
    _mealMenu = mealMenu;
    _groupedDishes = [_mealMenu groupedDishes];
}

-(IBAction)removeMyself:(id)sender{
    [self.view removeFromSuperview];
}

#pragma mark UITableViewDataSource

#pragma mark - Table view data source
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    CategoryItem *category = [_mealMenu.categories objectAtIndex:section];
    return category.name;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _mealMenu.categories.count ? _mealMenu.categories.count : 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray* dishesInOneGroup = [_groupedDishes objectAtIndex:section];
    return dishesInOneGroup.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
//    if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.textColor = RGBCOLOR(0x34, 0x32, 0x32);
    cell.detailTextLabel.textColor = RGBCOLOR(0x34, 0x32, 0x32);
//    }
    NSArray* dishesInOneGroup = [_groupedDishes objectAtIndex:indexPath.section];
    DishItem* dish = [dishesInOneGroup objectAtIndex:indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"    %@",dish.name]; //quick and dirty fix to move the text a bit right
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%d元/份x%d  ", dish.price, dish.num];//quick and dirty fix to move the text a bit left
    
    if (indexPath.row != [self tableView:_tableView numberOfRowsInSection:indexPath.section] - 1) {
        UIImageView* sepView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 44, 300, 1)];
        UIImage* sep = [UIImage imageNamed:@"sep_menu"];
        sepView.image = sep;
        [cell.contentView addSubview:sepView];
    }

    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    CategoryItem *category = [_mealMenu.categories objectAtIndex:section];
    return [category isDummy] ? 0 : 22;
}


-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 45;
}

-(UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    CategoryItem *category = [_mealMenu.categories objectAtIndex:section];
    if([category isDummy]){
        return nil;
    }
    UIImage* category_bg = [UIImage imageNamed:@"menu_category_bg"];
    UIImage* dot_sep = [UIImage imageNamed:@"menu_dot_sep"];
    CGFloat height = category_bg.size.height;

    
    UIView* contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 310, height)];
    UIImageView* categoryView = [[UIImageView alloc] initWithFrame:CGRectMake(8, 0, category_bg.size.width, category_bg.size.height)];
    categoryView.image = category_bg;
    [contentView addSubview:categoryView];
    CGFloat x = categoryView.frame.origin.x + categoryView.frame.size.width;
    UIImageView* dotView = [[UIImageView alloc] initWithFrame:CGRectMake(x, 9, dot_sep.size.width, dot_sep.size.height)];
    dotView.image = dot_sep;
    [contentView addSubview:dotView];
    
    UILabel* categoryLabel = [[UILabel alloc] initWithFrame:categoryView.frame];
    categoryLabel.backgroundColor = [UIColor clearColor];
    categoryLabel.font = [UIFont systemFontOfSize:16];
    categoryLabel.textColor = [UIColor whiteColor];
    categoryLabel.text = [self tableView:tableView titleForHeaderInSection:section];
    categoryLabel.textAlignment = UITextAlignmentCenter;
    [contentView addSubview:categoryLabel];
    return contentView;
}
@end
