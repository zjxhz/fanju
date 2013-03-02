//
//  OrderDetailViewController.h
//  EasyOrder
//
//  Created by igneus on 1/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CommonTableViewController.h"

@interface OrderDetailViewController : CommonTableViewController
-(id)initWithTitle:(NSString*)title orderid:(int)oid;
@end
