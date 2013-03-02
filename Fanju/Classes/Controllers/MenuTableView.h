//
//  MenuTableView.h
//  EasyOrder
//
//  Created by igneus on 12/17/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^TablePannedBlock)(void);
typedef void (^DishSelectedBlock)(int);

typedef enum{
    CellDisplayImageMode,
    CellDisplayListMode,
} CellDisplayMode;

@class Category;

@interface MenuTableView : UIView

@property (strong, nonatomic) NSMutableArray *array;
@property (nonatomic) CellDisplayMode displayMode;
@property (nonatomic, strong) TablePannedBlock tablePanAction;
@property (nonatomic, strong) DishSelectedBlock dishSelectAction;

- (void)toggleMenuTable;
- (void)categorySelected:(Category*)category;
@end
