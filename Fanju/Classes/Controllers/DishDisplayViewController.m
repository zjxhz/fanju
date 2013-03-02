//
//  DishDisplayViewController.m
//  EasyOrder
//
//  Created by igneus on 1/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DishDisplayViewController.h"
#import "Dish.h"
#import "OrderManager.h"

#define IMG_HEIGHT 416

@interface DishDisplayViewController ()
@property (nonatomic, strong) TTScrollView *scrollView;
@property (nonatomic, strong) NSArray *array;
@property (nonatomic) int index;

@property (nonatomic, strong) UILabel *dishName;
@property (nonatomic, strong) UILabel *price;
@property (nonatomic, strong) TTButton *plus;
@property (nonatomic, strong) TTButton *minus;
@property (nonatomic, strong) UILabel *amount;

- (void)addDish;
- (void)minusDish;
- (void)refreshDishStatus;

@end

@implementation DishDisplayViewController
@synthesize scrollView = _scrollView;
@synthesize array = _array;
@synthesize index = _index;
@synthesize dishName = _dishName, price = _price;
@synthesize plus = _plus, minus = _minus, amount = _amount;

- (id)initWithDishes:(NSArray*)dishes atIndex:(int)index {
    if (self = [super init]) {
        self.index = index;
        NSMutableArray *tmpArr = [NSMutableArray array];
        for (NSArray *tmp in dishes) {
            [tmpArr addObjectsFromArray:tmp];
        }
        self.array = [tmpArr copy];
    }
    
    return self;
}

- (void)loadView {
    CGRect appFrame = [UIScreen mainScreen].applicationFrame;
    CGRect frame = CGRectMake(0, 0, appFrame.size.width, appFrame.size.height - 44);
    self.view = [[UIView alloc] initWithFrame:frame];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    self.scrollView = [[TTScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, IMG_HEIGHT)];
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.scrollView.dataSource = self;
    self.scrollView.delegate = self;
    self.scrollView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.scrollView];
    [self.scrollView setCenterPageIndex:self.index];
    
    
    self.dishName = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 40)];
    [self.dishName setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.5]];
    [self.dishName setTextColor:[UIColor whiteColor]];
    [self.dishName setFont:[UIFont systemFontOfSize:20]];
    [self.view addSubview:self.dishName];
    
    CGFloat layoutX = 10;
    CGFloat layoutY = IMG_HEIGHT + 5;
    
    TTButton *back = [TTButton buttonWithStyle:@"embossedButton:" title:NSLocalizedString(@"Back", nil)];
    [back setFrame:CGRectMake(layoutX, layoutY, 50, 30)];
    [back addTarget:self 
                  action:@selector(dismissModalViewControllerAnimated:) 
        forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:back];
    layoutX = layoutX + back.frame.size.width + 5;
    
    self.price = [[UILabel alloc] initWithFrame:CGRectMake(layoutX, layoutY, 100, 32)];
    [self.price setBackgroundColor:[UIColor clearColor]];
    [self.price setTextColor:[UIColor blackColor]];
    [self.price setFont:[UIFont systemFontOfSize:14]];
    [self.view addSubview:self.price];
    layoutX += self.price.frame.size.width + 15;
    
    self.plus = [TTButton buttonWithStyle:@"embossedButton:" title:@"+1"];
    [self.plus setFrame:CGRectMake(layoutX, layoutY, 50, 30)];
    [self.plus addTarget:self action:@selector(addDish) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:self.plus];
    layoutX = layoutX + self.plus.frame.size.width + 10;
    
    self.amount = [[UILabel alloc] initWithFrame:CGRectMake(layoutX, layoutY, 15, 30)];
    [self.amount setBackgroundColor:[UIColor clearColor]];
    [self.amount setTextColor:[UIColor blackColor]];
    [self.amount setFont:[UIFont boldSystemFontOfSize:17]];
    [self.amount setTextAlignment:UITextAlignmentCenter];
    [self.view addSubview:self.amount];
    layoutX = layoutX + self.amount.frame.size.width + 10;
    
    self.minus = [TTButton buttonWithStyle:@"embossedButton:" title:@"-1"];
    [self.minus setFrame:CGRectMake(layoutX, layoutY, 50, 30)];
    [self.minus addTarget:self action:@selector(minusDish) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:self.minus];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)addDish {
    Dish *dish = [self.array objectAtIndex:self.scrollView.centerPageIndex];
    [[OrderManager sharedManager] addOrder:dish];
    [self refreshDishStatus];
}

- (void)minusDish {
    Dish *dish = [self.array objectAtIndex:self.scrollView.centerPageIndex];
    [[OrderManager sharedManager] removeOrder:dish];
    [self refreshDishStatus];
}

- (void)refreshDishStatus {
    Dish *dish = [self.array objectAtIndex:self.scrollView.centerPageIndex];
    int numOfOrders = [[OrderManager sharedManager] numOfOrderItemWithDishID:dish.dishID];
    [self.amount setText:[NSString stringWithFormat:@"%d", numOfOrders]];
    
    if (numOfOrders > 0) {
        [self.minus setEnabled:YES];
    } else {
        [self.minus setEnabled:NO];
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// TTScrollViewDataSource

- (NSInteger)numberOfPagesInScrollView:(TTScrollView*)scrollView {
    return [self.array count];
}

- (UIView*)scrollView:(TTScrollView*)scrollView pageAtIndex:(NSInteger)pageIndex {

    TTImageView *img = [[TTImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, IMG_HEIGHT)];
    
    Dish *dish = [self.array objectAtIndex:pageIndex];
    [img setUrlPath:dish.pic];
    
    return img;
}

- (CGSize)scrollView:(TTScrollView*)scrollView sizeOfPageAtIndex:(NSInteger)pageIndex {
    return CGSizeMake(320, IMG_HEIGHT);
}

#pragma mark -
#pragma mark TTScrollViewDelegate

- (void)scrollView:(TTScrollView*)scrollView didMoveToPageAtIndex:(NSInteger)pageIndex {
    Dish *dish = [self.array objectAtIndex:pageIndex];
    [self.dishName setText:dish.name];
    [self.price setText:[NSString stringWithFormat:@"价格: %.2lf/份", [dish.price doubleValue]]];
    
    int numOfOrders = [[OrderManager sharedManager] numOfOrderItemWithDishID:dish.dishID];
    [self.amount setText:[NSString stringWithFormat:@"%d", numOfOrders]];
    
    if (numOfOrders > 0) {
        [self.minus setEnabled:YES];
    } else {
        [self.minus setEnabled:NO];
    }
}


@end
