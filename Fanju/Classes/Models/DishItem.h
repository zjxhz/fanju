//
//  DishItem.h
//  EasyOrder
//
//  Created by 浣泽 徐 on 8/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OrderedObject.h"
@interface DishItem : NSObject <OrderedObject>
@property NSInteger num;
@property NSInteger orderNo;//seq no
@property(nonatomic, copy) NSString* name;
@property NSInteger price;

-(DishItem*)initWithData:(NSDictionary*)data;
+(DishItem*) itemWithData:(NSDictionary*)data;
@end
