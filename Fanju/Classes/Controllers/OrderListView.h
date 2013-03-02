//
//  OrderListViewController.h
//  EasyOrder
//
//  Created by igneus on 12/29/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^DismissOrderListBlock)(void);

@interface OrderListView : UIView {
    DismissOrderListBlock dismissOrderList;
}

- (void)performedDismissOrderList:(DismissOrderListBlock)dismiss;
- (void)showView;
@end
