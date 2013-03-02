//
//  LeftSideBarView.m
//  EasyOrder
//
//  Created by igneus on 12/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "LeftSideBarView.h"
#import "MenuViewController.h"
#import "OrderManager.h"
#import "LeftSideBarTableView.h"

#define TOOLBAR_HEIGHT 44
#define TOOLBAR_BTN_WIDTH 32
#define TOOLBAR_BTN_HEIGHT 32
#define TOOLBAR_BTN_IMG_EDGE_INSETS UIEdgeInsetsMake(5, 5, 5, 5)
#define TOOLBAR_BTN_GAP 10

@interface LeftSideBarView ()
@property (nonatomic, strong) LeftSideBarTableView *categoryTable;
@property (nonatomic, strong) UILabel *orderBadge;
@property (nonatomic, strong) TTView *badgeView;
@property (nonatomic, strong) UIButton *category;

- (void)setupToolbar;
- (void)toggleCategory;
- (void)displayOrderList;
- (void)dismissViewController;
@end

@implementation LeftSideBarView
@synthesize categoryTable = _categoryTable;
@synthesize orderBadge = _orderBadge, badgeView = _badgeView;
@synthesize category = _category;
@synthesize dismissedAction = _dismissedAction, categorySelectAction = _categorySelectAction, categoryToggleAction = _categoryToggleAction, displayOrderAction = _displayOrderAction, displayChangeAction = _displayChangeAction;

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"settingbg.jpg"]]];
        
        [self setupToolbar];

        self.categoryTable = [[LeftSideBarTableView alloc] initWithFrame:CGRectMake(0, TOOLBAR_HEIGHT, LEFT_SIDEBAR_WIDTH, frame.size.height - TOOLBAR_HEIGHT)];
        [self.categoryTable setCategorySelectAction:[^(Category *category){
            self.categorySelectAction(category);
        } copy]];
        [self addSubview:self.categoryTable];
    }
    
    return self;
}

- (void)dealloc {
    [[OrderManager sharedManager] removeObserver:self
                                      forKeyPath:@"orders"];
}

-(void)setupToolbar {
    CGFloat buttonX = 5;
    //toolbar
    TTStyle* style = [TTFourBorderStyle styleWithTop:[UIColor clearColor] right:[UIColor clearColor] 
                                              bottom:[UIColor blackColor] left:[UIColor clearColor] width:1 next:nil];
    TTView *toolbar = [[TTView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, TOOLBAR_HEIGHT)];
    [toolbar setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"settingbg.jpg"]]];
    toolbar.style = style;
    
    //toggle category btn
    self.category = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.category setImage:[UIImage imageNamed:@"showcategory.png"] forState:UIControlStateNormal];
    [self.category setImage:[UIImage imageNamed:@"hidecategory.png"] forState:UIControlStateSelected];
    [self.category addTarget:self 
             action:@selector(toggleCategory) 
   forControlEvents:UIControlEventTouchDown];
    [self.category setFrame:CGRectMake(buttonX, (toolbar.frame.size.height - TOOLBAR_BTN_HEIGHT) / 2, TOOLBAR_BTN_WIDTH, TOOLBAR_BTN_HEIGHT)];
    [self.category setImageEdgeInsets:TOOLBAR_BTN_IMG_EDGE_INSETS];
    [toolbar addSubview:self.category];
    
    buttonX = buttonX + self.category.frame.size.width + TOOLBAR_BTN_GAP;
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(buttonX, 4, 64, 36)];
    [label.layer setMasksToBounds:YES];
    [label.layer setCornerRadius:8.0f];
    [label setText:@"外婆家"];
    [label setTextColor:[UIColor whiteColor]];
    [label setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.5]];
    [label setFont:[UIFont systemFontOfSize:13]];
    [label setMinimumFontSize:10];
    [label setTextAlignment:UITextAlignmentCenter];
    [toolbar addSubview:label];
    
    buttonX = buttonX + label.frame.size.width + TOOLBAR_BTN_GAP;
//    
//    //favorite btn
//    self.favorite = [UIButton buttonWithType:UIButtonTypeCustom];
//    [self.favorite setImage:[UIImage imageNamed:@"favorite.png"] forState:UIControlStateNormal];
//    [self.favorite setImage:[UIImage imageNamed:@"favoriteselected.png"] forState:UIControlStateSelected];
//    [self.favorite addTarget:self 
//            action:@selector(toggleFavorite) 
//  forControlEvents:UIControlEventTouchDown];
//    [self.favorite setFrame:CGRectMake(buttonX, (toolbar.frame.size.height - TOOLBAR_BTN_HEIGHT) / 2, TOOLBAR_BTN_WIDTH, TOOLBAR_BTN_HEIGHT)];
//    [self.favorite setImageEdgeInsets:UIEdgeInsetsMake(5, 5, 1, 5)];
//    [toolbar addSubview:self.favorite];
//    
//    buttonX = buttonX + self.favorite.frame.size.width + TOOLBAR_BTN_GAP;
//    
//    //recent btn
//    self.recent = [UIButton buttonWithType:UIButtonTypeCustom];
//    [self.recent setImage:[UIImage imageNamed:@"recentdishselected.png"] forState:UIControlStateNormal];
//    [self.recent setImage:[UIImage imageNamed:@"recentdish.png"] forState:UIControlStateSelected];
//    [self.recent addTarget:self.delegate 
//            action:@selector(toggleRecent) 
//  forControlEvents:UIControlEventTouchDown];
//    [self.recent setFrame:CGRectMake(buttonX, (toolbar.frame.size.height - TOOLBAR_BTN_HEIGHT) / 2, TOOLBAR_BTN_WIDTH, TOOLBAR_BTN_HEIGHT)];
//    [self.recent setImageEdgeInsets:UIEdgeInsetsMake(5, 5, 1, 5)];
//    [toolbar addSubview:self.recent];
//    
//    buttonX = buttonX + self.recent.frame.size.width + TOOLBAR_BTN_GAP;
    
    //switcher
    TTTabGrid *listSwitch = [[TTTabGrid alloc] initWithFrame:CGRectMake(0, 0, 64, 32)];
    listSwitch.columnCount = 2;
    listSwitch.backgroundColor = [UIColor clearColor];
    TTTabItem *imgMode = [[TTTabItem alloc] initWithTitle:@" "];
    imgMode.icon = @"bundle://imgmode.png";
    TTTabItem *listMode = [[TTTabItem alloc] initWithTitle:@" "];
    listMode.icon = @"bundle://listmode.png";
    listSwitch.tabItems = [NSArray arrayWithObjects:
                           imgMode,
                           listMode,
                           nil];
    [listSwitch sizeToFit];
    [listSwitch setFrame:CGRectMake(buttonX, (toolbar.frame.size.height - listSwitch.frame.size.height) / 2 - 1, listSwitch.frame.size.width, listSwitch.frame.size.height)];
    [listSwitch setDelegate:self];
    [toolbar addSubview:listSwitch];
    
    buttonX = buttonX + listSwitch.frame.size.width + TOOLBAR_BTN_GAP;
    
    //myorders btn
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setImage:[UIImage imageNamed:@"orders.png"] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(displayOrderList) forControlEvents:UIControlEventTouchDown];
    [btn setFrame:CGRectMake(buttonX, (toolbar.frame.size.height - TOOLBAR_BTN_HEIGHT) / 2, TOOLBAR_BTN_WIDTH, TOOLBAR_BTN_HEIGHT)];
    [btn setImageEdgeInsets:TOOLBAR_BTN_IMG_EDGE_INSETS];
    [toolbar addSubview:btn];
    
    //order badge
    style =[TTShapeStyle styleWithShape:[TTRoundedRectangleShape shapeWithRadius:TT_ROUNDED] next:
       [TTSolidFillStyle styleWithColor:[UIColor redColor] next:nil]];
    self.badgeView = [[TTView alloc] initWithFrame:CGRectMake(btn.frame.origin.x + 20, btn.frame.origin.y - 3, 12, 12)];
    [self.badgeView setBackgroundColor:[UIColor clearColor]];
    self.badgeView.style = style;
    self.orderBadge = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 12, 12)];
    [self.orderBadge setTextColor:[UIColor whiteColor]];
    [self.orderBadge setBackgroundColor:[UIColor clearColor]];
    [self.orderBadge setFont:[UIFont systemFontOfSize:10]];
    [self.orderBadge setTextAlignment:UITextAlignmentCenter];
    [self.badgeView addSubview:self.orderBadge];
    [toolbar addSubview:self.badgeView];
    
    [[OrderManager sharedManager] addObserver:self
                                   forKeyPath:@"orders"
                                      options:NSKeyValueObservingOptionNew
                                      context:NULL];
    
    buttonX = buttonX + btn.frame.size.width + TOOLBAR_BTN_GAP;
    
    //search btn
    btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setImage:[UIImage imageNamed:@"searchdish.png"] forState:UIControlStateNormal];
//    [self.recent addTarget:self.delegate 
//                    action:@selector(toggleRecent) 
//          forControlEvents:UIControlEventTouchDown];
    [btn setFrame:CGRectMake(buttonX, (toolbar.frame.size.height - TOOLBAR_BTN_HEIGHT) / 2, TOOLBAR_BTN_WIDTH, TOOLBAR_BTN_HEIGHT)];
    [btn setImageEdgeInsets:UIEdgeInsetsMake(5, 5, 5, 5)];
    [toolbar addSubview:btn];
    
    buttonX = buttonX + btn.frame.size.width + TOOLBAR_BTN_GAP;
    
    //quit btn
    btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setImage:[UIImage imageNamed:@"quit.png"] forState:UIControlStateNormal];
    [btn addTarget:self 
            action:@selector(dismissViewController) 
  forControlEvents:UIControlEventTouchDown];
    [btn setFrame:CGRectMake(buttonX, (toolbar.frame.size.height - TOOLBAR_BTN_HEIGHT) / 2, TOOLBAR_BTN_WIDTH, TOOLBAR_BTN_HEIGHT)];
    [btn setImageEdgeInsets:UIEdgeInsetsMake(5, 5, 5, 5)];
    [toolbar addSubview:btn];
    
    [self addSubview:toolbar];
}

-(void)toggleCategory {
    self.categoryToggleAction(); 
    [self setToggleCategory];
}

- (void)setToggleCategory {
    [self.category setSelected:!self.category.isSelected];
}

- (void)dismissViewController {
    self.dismissedAction();
}

- (void)displayOrderList {
    if (![self.badgeView isHidden]) {
        self.displayOrderAction();
    }
}

#pragma mark TTTabDelegate
- (void)tabBar:(TTTabBar*)tabBar tabSelected:(NSInteger)selectedIndex {
    self.displayChangeAction(selectedIndex);
}

#pragma mark KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"orders"]) {
        NSArray *orders = [OrderManager sharedManager].orders;
        if ([orders count] > 0) {
            [self.badgeView setHidden:NO];
            [self.orderBadge setText:[NSString stringWithFormat:@"%d", [orders count]]];
        } else {
            [self.badgeView setHidden:YES];
        }
    }
}

@end
